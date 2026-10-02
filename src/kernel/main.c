#define __IN_PROTECTED_MODE__

#include "ints.h"
#include "io.c"

__attribute__((section(".text.entry"))) void kernel_main(void) {
  setColorCode(COLORS.LIGHT_MAGENTA, COLORS.BLACK);

  //   printc(0, 0, 'X', defaultColorCode);

  u8 str[] = "hi\n\r\tgfdgfgfdgdfgdfgfdgdfgdfgqrgefgfffffffffffffffffffffffffffffffdfgdfgfdgfgfdgdfgdfgfdgdfgdfgqrgefgffffffffffffffffffffffffffffff!";
  prints(str);

  while (1)
    __asm__ volatile("hlt");
}
