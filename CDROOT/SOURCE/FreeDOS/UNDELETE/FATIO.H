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


#ifndef FATIO_H
#define FATIO_H

#include "dostypes.h"		/* Byte Word Dword */
#include "drives.h"		/* struct DPB */
#include "diskio.h"		/* readsector, writesector */

int writefat (int drive, Dword slot, Dword value, struct DPB *dpb);
int readfat (int drive, Dword slot, Dword * value, struct DPB *dpb);

#endif
