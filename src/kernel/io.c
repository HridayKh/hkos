#include "ints.h"

#include "vga.c"
#define vaList __builtin_va_list
#define vaStart __builtin_va_start
#define vaArg __builtin_va_arg
#define vaEnd __builtin_va_end
#define vaCopy __builtin_va_copy

u8 cursorx = 0;
u8 cursory = 0;

static void push(u32 val) {
  __asm__ volatile("push %0" : : "r"(val) : "memory");
}
static u32 pop(void) {
  u32 val;
  __asm__ volatile("pop %0" : "=r"(val) : : "memory");
  return val;
}

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

static void updateCursor(void) {
  u16 pos = cursory * VGA_WIDTH + cursorx;

  outb(0x3D4, 0x0F);
  outb(0x3D5, (u8)(pos & 0xFF));
  outb(0x3D4, 0x0E);
  outb(0x3D5, (u8)((pos >> 8) & 0xFF));
}
static void normalizeCursor(void) {
  if (cursorx >= VGA_WIDTH) {
    cursorx = 0;
    cursory++;
  }

  while (cursory >= VGA_HEIGHT) {
    vgaScroll();
    cursory--;
  }
}

static void manageCursorForChar(u8 c) {
  if (c == '\b') {
    if (cursorx > 0)
      cursorx--;
  } else if (c == '\t') {
    cursorx = (cursorx + 8) & ~7;
  } else if (c == '\r') {
    cursorx = 0;
  } else if (c == '\n') {
    cursory++;
  }

  normalizeCursor();
}

// print a single ascii character but the cursor is NOT updated
// returns if char was printed (char >= ' ')
static void printcNoCursorUpdate(u8 charAscii) {
  manageCursorForChar(charAscii);
  if (charAscii >= ' ') { // printable chars
    vgaPrintChar(cursorx, cursory, charAscii);
    cursorx++;
    normalizeCursor();
  }
}
// print a string until null terminator  but the cursor is NOT updated
static void printsNoCursorUpdate(char *str) {
  register u8 chars = 0;
  register u8 currentChar = str[chars];
  while (currentChar != '\0') {
    printcNoCursorUpdate(currentChar);
    currentChar = str[++chars];
  }
}

// print a single ascii character and then update the cursor
void printc(u8 charAscii) {
  printcNoCursorUpdate(charAscii);
  updateCursor();
}
// print a string until null terminator and then update the cursor
void prints(char *str) {
  printsNoCursorUpdate(str);
  updateCursor();
}

static void printNumAsHexStr(u32 num) {
  if (num == 0) {
    printcNoCursorUpdate('0');
    return;
  }
  push(0);
  u8 r = 0;
  while (num != 0) {
    r = num % 16;
    num = num / 16;
    if (r <= 9)
      push(r + '0');
    else
      push(r + 'A' - 10);
  }
  u32 v = pop();
  while (v != 0) {
    printcNoCursorUpdate(v);
    v = pop();
  }
}
static void printNumAsStr(u32 num) {
  if (num == 0) {
    printcNoCursorUpdate('0');
    return;
  }
  push(0);
  u8 r = 0;
  while (num != 0) {
    r = num % 10;
    num = num / 10;
    push(r + '0');
  }
  u32 v = pop();
  while (v != 0) {
    printcNoCursorUpdate(v);
    v = pop();
  }
}

// formatted strings of style: "hello %ui %si %uh %sh %s %c %% world!"
// %ui: unsigned int
// %si: signed int
// %uh: unsigned hex
// %sh : signed hex
// %s: string
// %c: char
// %%: the char '%'
void printf(const char *str, ...) {
  vaList args;
  vaStart(args, str);

  isize i = 0;

  while (str[i] != '\0') {
    if (str[i] != '%') {
      printcNoCursorUpdate(str[i]);
      i++;
      continue;
    }

    i++;
    u8 spec = str[i];

    if (spec == '\0') {
      printcNoCursorUpdate('%');
      break;
    }

    switch (spec) {
    case 'u': { // %ui or %uh
      u8 sub = str[i + 1];
      if (sub == 'i' || sub == 'h') {
        i++; // Consume sub-specifier ('i' or 'h')
        u32 unum = vaArg(args, u32);
        (sub == 'h') ? printNumAsHexStr(unum) : printNumAsStr(unum);
      } else {
        printcNoCursorUpdate('%');
        printcNoCursorUpdate('u');
      }
      break;
    }

    case 's': { // %si, %sh, or %s
      u8 sub = str[i + 1];
      if (sub == 'i' || sub == 'h') {
        i++; // Consume sub-specifier ('i' or 'h')
        s32 snum = vaArg(args, s32);
        if (snum < 0) {
          printcNoCursorUpdate('-');
        }
        u32 unum = (snum < 0) ? (0U - (u32)snum) : (u32)snum;
        (sub == 'h') ? printNumAsHexStr(unum) : printNumAsStr(unum);
      } else {
        printsNoCursorUpdate(vaArg(args, char *));
      }
      break;
    }

    case 'c': // %c
      printcNoCursorUpdate(vaArg(args, u32));
      break;

    case '%': // %%
      printcNoCursorUpdate('%');
      break;

    default: // Unknown specifier (e.g. %z) -> print verbatim
      printcNoCursorUpdate('%');
      printcNoCursorUpdate(spec);
      break;
    }

    i++; // Advance past the processed specifier
  }

  vaEnd(args);
  updateCursor();
}
