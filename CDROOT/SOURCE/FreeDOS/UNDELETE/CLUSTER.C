/*
  FreeDOS special UNDELETE tool (and mirror, kind of)
  Copyright (C) 2001, 2002, 2008  Eric Auer <eric@CoLi.Uni-SB.DE>

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301
  USA. Or check http://www.gnu.org/licenses/gpl.txt on the internet.
*/


#include "drives.h"		/* DPB structure */
#include "fatio.h"		/* readfat */
#include <stdio.h>		/* printf */

#define CTS clustertosector
Dword
clustertosector (Dword cluster, struct DPB *dpb)
{
  Dword sector, maxcluster;
  maxcluster = (dpb->secperfat==0) ? dpb->FAT32_clusters : dpb->maxclustnum;
  if ((cluster < 2) || (cluster > maxcluster))
    {
      printf ("Cluster number %lu out of range [2..%lu]\n",
	      cluster, maxcluster);
      return 0;
    }
  sector = cluster - 2;		/* make it 0 based */
  sector <<= dpb->shlclusttosec;
  /* FAT1x: sector += dpb->numressec + (dpb->secperfat * dpb->fats); */
  /* FAT1x: sector += (dpb->rootdirents >> 4); */
  /* rootdirents>>4 because of 512/32 being 1<<4... */
  sector += ((dpb->secperfat==0) ?  dpb->FAT32_firstdatasec: dpb->firstdatasec);
  return sector;
}

/* ***************************************************** */
/* Screen output of nextcluster has been modified for new interface,
   Less info but less scary for innocents - RP */
Dword
nextcluster (Dword cluster, struct DPB * dpb)
{				/* follow FAT chain or guess! */
  Dword maxcluster, oldcluster;
  int state;

  maxcluster = (dpb->secperfat==0) ? dpb->FAT32_clusters : dpb->maxclustnum;
  oldcluster = cluster;

/*  printf ("%d->", oldcluster); */
  state = readfat (dpb->drive, oldcluster, &cluster, dpb);
  if (state < 0)
    {
      printf ("FAT read error\n");
      return 0;
    }

  if (cluster > maxcluster)
    {
      printf ("EOF\n");
      return 0;
    }
  if (cluster == 0)
    {
      printf (".");
/*      printf ("NIL/");  *//* if we come from empty... (undelete) */
      do
	{
	  oldcluster++;
	  state = readfat (dpb->drive, oldcluster, &cluster, dpb);
	  if (state < 0)
	    {
	      printf ("FAT read error\n");
	      return 0;
	    }
	  if (cluster != 0)
	    {
	      printf ("-");
	    }
	}
      while (cluster != 0);	/* skip over used clusters */
      cluster = oldcluster;	/* return next empty cluster! */
    }				/* else stay inside FAT chain */

  /* printf("%d "); */
  return cluster;
}
