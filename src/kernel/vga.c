#include "vga.h"
#include "memory.h"

u8 VGA_WIDTH = 80;
u8 VGA_HEIGHT = 25;
volatile u16 *vga = (volatile u16 *)0xB8000;
u8 vgaColorCode = VGA_COLOR_LIGHT_MAGENTA;

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
  memsetw((void *)(vga + charCount), (vgaColorCode << 8) | ' ', VGA_WIDTH);
}

void vgaFill(u8 charAscii) {
  memsetw((void *)vga, (vgaColorCode << 8) | charAscii, VGA_WIDTH * VGA_HEIGHT);
}
