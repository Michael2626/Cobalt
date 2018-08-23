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


#include "fatio.h"
#include <stdio.h>		/* printf */

Byte fatbuf1[1024];
Byte fatbuf2[1024];
Dword lastfatbuf = 0xffffffffL;	/* number of sector in buffer */


int
writefat (int drive, Dword slot, Dword value, struct DPB *dpb)
{
  Dword oldvalue;
  Dword offs;			/* intermediate values have 17 or 18 bits */
  Dword fatsector, secperfat;

  secperfat = (dpb->secperfat==0) ? dpb->FAT32_secperfat : dpb->secperfat;
  fatsector = dpb->numressec;	/* skip reserved */

  readfat (drive, slot, &oldvalue, dpb);

  if (dpb->secperfat==0)
    {				/* fat32 */
      offs = slot;
      offs <<= 2;
    }
  else if (dpb->maxclustnum > 0xff6)
    {				/* fat16 */
      offs = slot;
      offs <<= 1;
    }
  else
    {				/* fat12 */
      offs = slot;
      offs = ((offs << 1) + offs) >> 1;	/* 1.5by/slot! */
    }
  fatsector += offs >> 9;	/* assume 512 by per sector */
  offs &= 511;			/* may be 511 for FAT12, sigh */

  if (dpb->secperfat==0)
    {				/* fat32 */
      fatbuf1[(Word) offs + 3] &= 0xf0;	/* keep upper 4 bits unchanged */
      fatbuf1[(Word) offs + 3] |= (value >> 24) & 0x0f;	/* use 28 bits */
      fatbuf1[(Word) offs + 2] = (value >> 16) & 0xff;
      fatbuf1[(Word) offs + 1] = (value >> 8) & 0xff;
      fatbuf1[(Word) offs] |= value & 0xff;
    }
  else if (dpb->maxclustnum > 0xff6)
    {				/* fat16 */
      fatbuf1[(Word) offs + 1] = (value >> 8) & 0xFF;
      fatbuf1[(Word) offs] = value & 0xFF;
    }
  else
    {				/* fat12 */
      if ((slot & 1) == 0)
	{			/* even */
	  fatbuf1[(Word) offs + 1] &= 0xF0;
	  fatbuf1[(Word) offs + 1] |= (value >> 8) & 0x0F;
	  fatbuf1[(Word) offs] = value & 0xFF;
	}
      else
	{			/* odd */
	  fatbuf1[(Word) offs + 1] = (value >> 4) & 0xFF;
	  fatbuf1[(Word) offs] &= 0x0F;
	  fatbuf1[(Word) offs] |= (value << 4) & 0xF0;
	}
    }

  fatbuf2[(Word) offs + 3] = fatbuf1[(Word) offs + 3];
  fatbuf2[(Word) offs + 2] = fatbuf1[(Word) offs + 2];
  fatbuf2[(Word) offs + 1] = fatbuf1[(Word) offs + 1];
  fatbuf2[(Word) offs] = fatbuf1[(Word) offs];


  if (writesector (drive, fatsector, fatbuf1) < 0)
    {
      printf ("Error writing FAT");
      return -1;
    }
  if (writesector (drive, fatsector + 1, fatbuf1 + 512) < 0)
    {
      printf ("Error writing FAT");
      return -1;
    }
  if (dpb->fats > 1)
    {
      if (writesector (drive, fatsector + secperfat, fatbuf2) < 0)
	{
	  printf ("Error writing FAT");
	  return -1;
	}
      if (writesector (drive, fatsector + secperfat + 1,
		       fatbuf2 + 512) < 0)
	{
	  printf ("Error writing FAT");
	  return -1;
	}
    }

  return 0;
}

int
readfat (int drive, Dword slot, Dword * value, struct DPB *dpb)
{
  Dword val1;
  Dword val2;
  Dword offs;			/* intermediate values have 17 or 18 bits */
  Dword fatsector, secperfat;

  secperfat = (dpb->secperfat==0) ? dpb->FAT32_secperfat : dpb->secperfat;
  fatsector = dpb->numressec;	/* skip reserved */
  value[0] = 0;

  if (dpb->secperfat==0)
    {				/* fat32 */
      offs = slot;
      offs <<= 2;
    }
  else if (dpb->maxclustnum > 0xff6)
    {				/* fat16 */
      offs = slot;
      offs <<= 1;
    }
  else
    {				/* fat12 */
      offs = slot;
      offs = ((offs << 1) + offs) >> 1;	/* 1.5by/slot! */
    }
  fatsector += offs >> 9;	/* assume 512 by per sector */
  offs &= 511;			/* may be 511 for FAT12, sigh */

  if (fatsector != lastfatbuf)
    {
      if (readsector (drive, fatsector, fatbuf1) < 0)
	{
	  return -1;
	}
      if (readsector (drive, fatsector + 1, fatbuf1 + 512) < 0)
	{
	  return -1;
	}
      if (dpb->fats > 1)
	{
	  if (readsector (drive, fatsector + secperfat, fatbuf2) < 0)
	    {
	      return -1;
	    }
	  if (readsector (drive, fatsector + secperfat + 1,
			  fatbuf2 + 512) < 0)
	    {
	      return -1;
	    }
	}
      lastfatbuf = fatsector;	/* buffer this */
    }				/* else already in buffer */

  if (dpb->secperfat==0)
    {				/* fat32 */
      val1 = fatbuf1[(Word) offs + 3] & 0x0f;	/* use 28 bits */
      val1 <<= 8;
      val1 |= fatbuf1[(Word) offs + 2];
      val1 <<= 8;
      val1 |= fatbuf1[(Word) offs + 1];
      val1 <<= 8;
      val1 |= fatbuf1[(Word) offs];
      val2 = fatbuf2[(Word) offs + 3] & 0x0f;	/* use 28 bits */
      val2 <<= 8;
      val2 |= fatbuf2[(Word) offs + 2];
      val2 <<= 8;
      val2 |= fatbuf2[(Word) offs + 1];
      val2 <<= 8;
      val2 |= fatbuf2[(Word) offs];
    }
  else if (dpb->maxclustnum > 0xff6)
    {				/* fat16 */
      val1 = fatbuf1[(Word) offs + 1];
      val1 <<= 8;
      val1 |= fatbuf1[(Word) offs];
      val2 = fatbuf2[(Word) offs + 1];
      val2 <<= 8;
      val2 |= fatbuf2[(Word) offs];
    }
  else
    {				/* fat12 */
      if ((slot & 1) == 0)
	{
	  val1 = fatbuf1[(Word) offs + 1] & 0x0f;
	  val1 <<= 8;
	  val1 |= fatbuf1[(Word) offs];
	  val2 = fatbuf2[(Word) offs + 1] & 0x0f;
	  val2 <<= 8;
	  val2 |= fatbuf2[(Word) offs];
	}
      else
	{
	  val1 = fatbuf1[(Word) offs + 1];
	  val1 <<= 4;
	  val1 |= fatbuf1[(Word) offs] >> 4;
	  val2 = fatbuf2[(Word) offs + 1];
	  val2 <<= 4;
	  val2 |= fatbuf2[(Word) offs] >> 4;
	}
    }

  value[0] = val1;

  if (dpb->fats < 2)
    {
      val2 = val1;
    }
  if (val1 != val2)
    {
      printf ("FAT inconsistency: #1 %lu or #2 %lu ???\n", val1, val2);
      printf ("always using FAT1 in this case!\n");
      printf ("Slot: %lu  offset: %lu  sectors: %lu/%lu\n",
	      slot, offs, fatsector, fatsector + secperfat);
    }

  return 0;
}

/* fat12 packs 3, 4, 5, 6 as bytes 3,40,0, 5,60,0, ... */
