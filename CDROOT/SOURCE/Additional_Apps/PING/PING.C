/*
 * PING - internet diagnostic tool
 * Copyright (C) 1991, University of Waterloo
 * portions Copyright (C) 1990, National Center for Supercomputer Applications
 *
 * This program is free software; you can redistribute it and/or modify
 * it, but you may not sell it.
 *
 * This program is distributed in the hope that it will be useful,
 * but without any warranty; without even the implied warranty of
 * merchantability or fitness for a particular purpose.
 *
 *     Erick Engelke                   or via E-Mail
 *     Faculty of Engineering
 *     University of Waterloo          Erick@development.watstar.uwaterloo.ca
 *     200 University Ave.,
 *     Waterloo, Ont., Canada
 *     N2L 3G1
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <conio.h>
#include <assert.h>
#include <math.h>
#include <time.h>
#include <tcp.h>

#ifdef USE_EXCEPT
#include "d:/prog/mw/except/exc.h"
#endif

#ifdef USE_MPATROL
#include <mpatrol.h>
#endif

#if defined(DJGPP) && defined(DYNAMIC)
  #include <sys/dxe.h>
  DXE_DEMAND (Watt32);
#endif

#if defined(__SMALL__) || defined(__LARGE__)
  #define DBL_FMT "lf"
#else
  #define DBL_FMT "f"
#endif


#ifdef __BORLANDC__
#pragma warn -rch
#endif

W32_FUNC DWORD pkt_dropped (void);

#if defined(__DJGPP__)
  #define COM_ARG  "[-C COM-port] "
#else
  #define COM_ARG  ""
#endif

struct stddev {
       double sum;        /* standard sum        */
       double sqSum;      /* standard square sum */
       DWORD  samples;    /* # of samples taken  */
     };

struct statistics {
       DWORD  startTime;
       DWORD  numReplies;
       DWORD  numPings;
       struct stddev stddev;
     } stat;

char *name;
int   dbg_mode;

void MS_CDECL TraceOff (void)
{
  ctrace_on = 0;
}

/*-------------------------------------------------------------------*/

double GetTimeAverage (void)
{
  return (stat.stddev.sum / (1000.0 * stat.numReplies));
}

/*-------------------------------------------------------------------*/

void PutDeltaTime (long delta)
{
  stat.stddev.sum   += (double) delta;
  stat.stddev.sqSum += pow ((double)delta, 2.0);
  stat.stddev.samples++;
}

/*-------------------------------------------------------------------*/

double StdDeviation (void)
{
  double rc;
  double n = (double) stat.stddev.samples;

  if (n <= 1.0)
     return (0.0);
  rc = sqrt ((n*stat.stddev.sqSum - pow(stat.stddev.sum,2.0)) / (n*(n-1.0)));
  return (rc / 1000.0);
}

/*-----------------------------------------------------------------------*/

int Stats (void)
{
  DWORD drops = pkt_dropped();

  printf ("\nPing Statistics\n"
          "  Sent        : %lu\n"
          "  Received    : %lu\n", stat.numPings, stat.numReplies);

  if (drops)
     printf ("  Dropped     : %lu\n", drops);

  if (stat.numPings)
     printf ("  Success     : %.1"DBL_FMT" %%\n", 100.0*stat.numReplies/stat.numPings);

  if (!stat.numReplies)
     printf ("  There was no response from %s\n", name);
  else
  {
    printf ("  Average RTT : %5.3"DBL_FMT" sec\n", GetTimeAverage());
    printf ("  Std Dev     : %5.3"DBL_FMT" sec\n", StdDeviation());
  }
  return (stat.numReplies > 0);
}

/*-----------------------------------------------------------------------*/

void Usage (char *str)
{
  if (str)
     puts (str);
  puts ("ping [-?dfhstv] [-c count] " COM_ARG
        "[-w wait] host [size]");
  exit (1);
}

/*-----------------------------------------------------------------------*/

int main (int argc, char **argv)
{
  DWORD  host, new_rcvd;
  DWORD  send_timeout = 0L;
  DWORD  last_rcvd    = 0L;
  double wait         = 1.0;
  DWORD  count        = 0UL;
  int    flood_ping   = 0;
  int    hi_res       = 0;
  int    ch;
  char  *pattern_data = NULL;
  size_t pattern_len  = 0;

#ifdef USE_EXCEPT
  InstallExcHandler (NULL);
#endif

  while ((ch = getopt(argc, argv, "vdfsthc:w:C:?")) != EOF)
     switch (ch)
     {
       case 'v': puts (wattcpVersion());
                 break;
       case 'd': dbg_mode++;
                 break;
       case 's': count = 10UL;
                 break;
       case 't': /* start tracing now (High-C only!) */
                 atexit (TraceOff);
                 ctrace_on = 1;
                 break;
       case 'h': hi_res = 1;
                 break;
       case 'w': if (flood_ping)
                    Usage ("`-w' option is incompatible with `-f' option\n");
                 wait = atof (optarg);
                 if (wait < 0.001)
                    Usage ("wait must be >= 0.001\n");
                 if (!count)
                    count = 2UL;
                 break;
       case 'f': flood_ping = 1;
                 if (!count)
                    count = ULONG_MAX;
                 if (wait != 1.0)
                    Usage ("`-f' option is incompatible with `-w' option\n");
                 break;
       case 'c': count = atol (optarg);
                 if (count < 1)
                    Usage ("illegal count argument\n");
                 break;
       case 'C':
#ifdef __DJGPP__
                 if (!trace2com_init (optarg[0]-'0',115200UL))
                 {
                   printf ("Failed to initialise COM%d\n", optarg[0]-'0');
                   return (-1);
                 }
                 break;
#endif           /* else fall-through */

       case '?':
       default : Usage (NULL);
     }

  argc -= optind;
  argv += optind;

  if (argc-- < 1 || (name = *argv++) == NULL)
     Usage (NULL);

  if (dbg_mode)
     dbug_init();

  if (hi_res)
     putenv ("USE_RDTSC=1");

  sock_init();

  if (hi_res && !has_rdtsc)
  {
    printf ("`-h' option requires a CPU with RDTSC instruction\n");
    return (-1);
  }

  if (argc)
  {
    size_t i;

    pattern_len = atol (*argv);

    if (pattern_len > USHRT_MAX-20-12 || pattern_len < 64)
    {                /* max-frag - ip - echo-header */
      printf ("Illegal size (64 - %u)\n", (unsigned)(USHRT_MAX-20-12));
      Usage (NULL);
    }
    pattern_data = malloc (pattern_len);
    if (pattern_data)
       for (i = 0; i < pattern_len; i++)
           pattern_data[i] = "0123456789"[i % 10];
  }

  if (isaddr(name))
     host = aton (name);
  else if ((host = lookup_host(name,NULL)) == 0)
  {
    puts (dom_strerror(dom_errno));
    return (3);
  }

  if (flood_ping)
     printf ("pinging with %lu flood packets\n", count);

  else if (count > 1)
     printf ("pinging %lu times once every %.3"DBL_FMT"s\n", count, wait);

  if (!flood_ping)      /* wait 1 msec */
     wait *= 1000.0;    /* get # of msec */

  if (!count)
     count = 1UL;

  while (1)
  {
    if (!send_timeout || chk_timeout(send_timeout))
    {
      send_timeout = set_timeout ((DWORD)wait);
      if (stat.numPings < count)
      {
        stat.numPings++;
        stat.startTime = set_timeout (0);
        if (_ping(host, stat.numPings, (const BYTE*)pattern_data, pattern_len))
        {
          if (flood_ping)
               putchar ('.');
          else printf ("\nsent PING # %lu ", stat.numPings);
        }
      }
    }

    if (watt_kbhit())
       return Stats();

    tcp_tick (NULL);

    if (_chk_ping(host,&new_rcvd) != 0xFFFFFFFFUL)
    {
      long diff = set_timeout(0) - stat.startTime;

      if (diff < 0)
          diff = 0;
      PutDeltaTime (diff);
      stat.numReplies++;
      if (flood_ping)
      {
        if (new_rcvd != last_rcvd + 1)
             printf ("\b!");
        else printf ("\b");
      }
      else
        printf ("PING receipt # %lu%c: response time %.3"DBL_FMT" seconds",
                stat.numReplies, new_rcvd == last_rcvd + 1 ? ' ' : '!',
                (double)diff / 1000.0);

      last_rcvd = new_rcvd;
      if (stat.numReplies == count)
         return Stats();
    }

    if (flood_ping)
    {
      send_timeout = 0L;  /* resend immediately */
      if (stat.numPings >= count)
         return Stats();
    }
    fflush (stdout);
  }
  return (0);
}


