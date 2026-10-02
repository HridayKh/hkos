#include "ints.h"
#include "memory.h"

const struct {
  u8 BLACK;
  u8 BLUE;
  u8 GREEN;
  u8 CYAN;
  u8 RED;
  u8 MAGENTA;
  u8 BROWN;
  u8 LIGHT_GREY;
  u8 DARK_GREY;
  u8 LIGHT_BLUE;
  u8 LIGHT_GREEN;
  u8 LIGHT_CYAN;
  u8 LIGHT_RED;
  u8 LIGHT_MAGENTA;
  u8 YELLOW;
  u8 WHITE;
} COLORS = {.BLACK = 0,
            .BLUE = 1,
            .GREEN = 2,
            .CYAN = 3,
            .RED = 4,
            .MAGENTA = 5,
            .BROWN = 6,
            .LIGHT_GREY = 7,
            .DARK_GREY = 8,
            .LIGHT_BLUE = 9,
            .LIGHT_GREEN = 10,
            .LIGHT_CYAN = 11,
            .LIGHT_RED = 12,
            .LIGHT_MAGENTA = 13,
            .YELLOW = 14,
            .WHITE = 15};

u8 VGA_WIDTH = 80;
u8 VGA_HEIGHT = 25;
volatile u16 *vga = (volatile u16 *)0xB8000;
u8 vgaColorCode = 0x0D; // default light magenta on black

inline void setColorCode(u8 fg, u8 bg) { vgaColorCode = fg | (bg << 4); }

void vgaPrintChar(u8 x, u8 y, u8 charAscii) { // 80x25 chars
  if (x >= VGA_WIDTH)
    x = VGA_WIDTH - 1;
  if (y >= VGA_HEIGHT)
    y = VGA_HEIGHT - 1;

  u32 index = y * VGA_WIDTH + x;
  vga[index] = (vgaColorCode << 8) | charAscii;
}

void vgaScroll(void) {
  isize charCount = VGA_WIDTH * (VGA_HEIGHT - 1);
  memmove((void *)vga, (void *)(vga + VGA_WIDTH), charCount * 2);
  memset((void *)vga + charCount, 0, VGA_WIDTH);
}

void vgaFill(u8 charAscii) {
  memsetw((void *)vga, (charAscii << 8) + vgaColorCode, VGA_WIDTH * VGA_HEIGHT);
}
