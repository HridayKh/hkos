#include "ints.h"

#include "vga.c"

u8 cursorx = 0;
u8 cursory = 0;

static inline void outb(u16 port, u8 val) {
  __asm__ volatile("{outb %b0, %w1 | out %w1, %b0}"
                   :
                   : "a"(val), "Nd"(port)
                   : "memory");
}
static inline u8 inb(u16 port) {
  u8 ret;
  __asm__ volatile("{inb %w1, %b0 | in %b0, %w1}"
                   : "=a"(ret)
                   : "Nd"(port)
                   : "memory");
  return ret;
}

void updateCursor(void) {
  u16 pos = cursory * VGA_WIDTH + cursorx;

  outb(0x3D4, 0x0F);
  outb(0x3D5, (u8)(pos & 0xFF));
  outb(0x3D4, 0x0E);
  outb(0x3D5, (u8)((pos >> 8) & 0xFF));
}
void disableCursor(void) {
  outb(0x3D4, 0x0A);
  outb(0x3D5, 0x20);
}
void incCursorPos(void) {
  if (++cursorx >= VGA_WIDTH) {
    cursorx = 0;
    if (++cursory >= VGA_HEIGHT) {
      vgaScroll();
      cursory--;
    }
  }
}

void manageCursorForSpecialChar(u8 c) {
  if (c == 0x08) { // backspace
    if (cursorx != 0)
      cursorx--;
  } else if (c == 0x09) {
    cursorx = (cursorx + 8) & ~(8 - 1);
  } else if (c == '\r') {
    cursorx = 0;
  } else if (c == '\n') {
    cursory++;
  }
  if (cursorx >= VGA_WIDTH) {
    cursorx = 0;
    if (cursory >= VGA_HEIGHT) {
      vgaScroll();
      cursory--;
    }
  }
}

// print a single ascii character and then update the cursor
void printc(u8 charAscii) {
  manageCursorForSpecialChar(charAscii);
  if (charAscii >= ' ') // printable chars
    vgaPrintChar(cursorx, cursory, charAscii);
  updateCursor();
}

// print a string until null terminator and then update the cursor
void prints(u8 *str) {
  u8 chars = 0;
  u8 currentChar = str[chars];

  while (currentChar != '\0') {
    // printc is not used to avoid updating cursor on every char
    manageCursorForSpecialChar(currentChar);
    if (currentChar >= ' ') { // printable chars
      vgaPrintChar(cursorx, cursory, currentChar);
      incCursorPos();
    }

    currentChar = str[++chars];
  }
  updateCursor();
}
