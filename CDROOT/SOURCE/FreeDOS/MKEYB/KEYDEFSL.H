/* keydefsl.h 
this keyboard is modeled after the layout given by
	http://www.microsoft.com/globaldev/keyboards/kbdslove.htm
*/


/*
 * history
 * 29 sep 03: tom ehlert - creation
 * 
 */

#define NAME(x) x##_SL


#include <dos.h>
#include "mkeyb.h"

#define LANGUAGE "slovenian"
#define STATUS   "by tom"

/********************************************************
 * SLOVENIAN keyboard mappings                          *
 ********************************************************/

uchar NAME(scancodetable)[] = {

 /* Z */ REPLACE	(0x2C, 0x15		)
 /* Y */ REPLACE	(0x15, 0x2C		)


 /* 1 */       ALTGR    (0x02,               '~')
 /* 2 */ PUNCT_ALTGR    (0x03, '2', '"',     '?')  // wrong altgrey
 /* 3 */       ALTGR    (0x04,               '^')
 /* 4 */       ALTGR    (0x05,               '?')
 /* 5 */       ALTGR    (0x06,               '?')
 /* 6 */ PUNCT_ALTGR    (0x07, '6', '&',     '?')
 /* 7 */ PUNCT_ALTGR    (0x08, '7', '/',     '?')
 /* 8 */ PUNCT_ALTGR    (0x09, '8', '(',     '?')
 /* 9 */ PUNCT_ALTGR    (0x0a, '9', ')',     '?')
 /* 0 */ PUNCT_ALTGR    (0x0b, '0', '=',     '~')
 /* - */ PUNCT_ALTGR    (0x0c, '\'','?',     '?')
 /* = */ PUNCT_ALTGR    (0x0d, '+', '*',     '?')


 /* q */       ALTGR    (0x10,               '\\')
 /* w */       ALTGR    (0x11,               '|')
 /* e */       ALTGR    (0x12,               EURO)

 /* [ */ ALPHA_ALTGR    (0x1a, '?','?',      '?') 
 /* ] */ ALPHA_ALTGR    (0x1b, '?','?',      '?') 
 
 /* f */       ALTGR    (0x21,               '[')
 /* g */       ALTGR    (0x21,               ']')

 /* k */       ALTGR    (0x25,              '?')
 /* l */       ALTGR    (0x26,              '?')
 /* ; */ ALPHA_ALTGR    (0x27, '?','?',     '?')
 /* ' */ ALPHA_ALTGR    (0x28, '?','?',     '?')
 /*   */ ALPHA_ALTGR    (0x29, '?','?',     '?')


 /* v */       ALTGR    (0x2f,               '@')
 /* b */       ALTGR    (0x30,               '{')
 /* n */       ALTGR    (0x31,               '}')
 /* m */       ALTGR    (0x32,               '?')

 /* , */ PUNCT_ALTGR    (0x33,',',';',       '<')
 /* . */ PUNCT_ALTGR    (0x34,'.',':',       '>')
 /* , */ PUNCT          (0x35,'-','_'           )

 /*   */ PUNCT      	(0x56, '<', '>'     	)
         0
};

struct KeyboardDefinition NAME(Keyboard) = {
        "SL",                                          //char LanguageShort[4];                 // "GR",
        "SLOVENIAN keyboard, no combi's (by tom)",     //char *Description;                              // created by, "with combis"
        DRIVER_FUNCTION_NORMAL,                        //char DriverFunctionRequired;
        NAME(scancodetable),                           //char *ScancodeTable;
#ifdef COMBI
        {       NAME(combi1table),NAME(combi2table),NAME(combi3table),
                NAME(combi4table),NAME(combi5table),NAME(combi6table) },
#else
        { 0 },
#endif                  
        ',',                                           //char DezimalDingsbums;
        0,                                             //char DefaultLayoutUS;                  // TRUE for russian
        } ;
