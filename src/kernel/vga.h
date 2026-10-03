
#ifndef HKOS_VGA_H // check if this header defined
#define HKOS_VGA_H // mark as defined

#include "ints.h"

enum VGA_COLORS {
    VGA_COLOR_BLACK         = 0,
    VGA_COLOR_BLUE          = 1,
    VGA_COLOR_GREEN         = 2,
    VGA_COLOR_CYAN          = 3,
    VGA_COLOR_RED           = 4,
    VGA_COLOR_MAGENTA       = 5,
    VGA_COLOR_BROWN         = 6,
    VGA_COLOR_LIGHT_GREY    = 7,
    VGA_COLOR_DARK_GREY     = 8,
    VGA_COLOR_LIGHT_BLUE    = 9,
    VGA_COLOR_LIGHT_GREEN   = 10,
    VGA_COLOR_LIGHT_CYAN    = 11,
    VGA_COLOR_LIGHT_RED     = 12,
    VGA_COLOR_LIGHT_MAGENTA = 13,
    VGA_COLOR_YELLOW        = 14,
    VGA_COLOR_WHITE         = 15,
};

extern u8 VGA_WIDTH;
extern u8 VGA_HEIGHT;
extern volatile u16 *vga;
extern u8 vgaColorCode;

inline void setColorCode(u8 fg, u8 bg) { vgaColorCode = fg | (bg << 4); }
void vgaPrintChar(u8 x, u8 y, u8 charAscii);
void vgaScroll(void);
void vgaFill(u8 charAscii);

#endif // HKOS_VGA_H
