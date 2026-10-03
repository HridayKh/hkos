#define __IN_PROTECTED_MODE__

#include "io.h"
#include "vga.h"

void test_printf(void) {
  // -------------------------------------------------------------
  // 1. User Sample String (Mixed Specifiers)
  // -------------------------------------------------------------
  // Expected: "hello 42 -1234 ABC123 -FF embedded Z % world!"
  printf("hello %ui %si %uh %sh %s %c %% world!\r\n", 42u, -1234, 0xABC123u,
         -255, "embedded", 'Z');

  // -------------------------------------------------------------
  // 2. Individual Specifiers - Basic Functionality
  // -------------------------------------------------------------
  printf("Unsigned int : %ui\r\n", 123456789u);     // Expected: 123456789
  printf("Signed int   : %si\r\n", -987654321);     // Expected: -987654321
  printf("Unsigned hex : %uh\r\n", 0xDEADBEEFu);    // Expected: DEADBEEF
  printf("Signed hex   : %sh\r\n", -0x1000);        // Expected: -1000
  printf("String       : %s\r\n", "Hello, World!"); // Expected: Hello, World!
  printf("Char         : %c\r\n", 'A');             // Expected: A
  printf("Literal %    : %%\r\n");                  // Expected: %

  // -------------------------------------------------------------
  // 3. Boundary & Limit Values
  // -------------------------------------------------------------
  // Zeroes
  printf("Zeroes       : %ui | %si | %uh | %sh\r\n", 0u, 0, 0u, 0);
  // Expected: 0 | 0 | 0 | 0

  // Maximum Unsigned (4294967295 / 0xFFFFFFFF)
  printf("Max Unsigned : %ui | %uh\r\n", 4294967295, 4294967295);
  // Expected: 4294967295 | FFFFFFFF

  // Signed Integer Limits (2147483647 & -2147483648)
  printf("Max Signed   : %si | %sh\r\n", 2147483647, 2147483647);
  // Expected: 2147483647 | 7FFFFFFF

  printf("Min Signed   : %si | %sh\r\n", (s32)-2147483648, (s32)-2147483648);
  // Expected: -2147483648 | -80000000

  // -------------------------------------------------------------
  // 4. Edge Cases
  // -------------------------------------------------------------
  // Empty String
  printf("Empty string : [%s]\r\n", ""); // Expected: []

  // Consecutive % Symbols
  printf("Percent test : %%%%%%\r\n"); // Expected: %%%

  // Back-to-back Specifiers (No space separators)
  printf("Consecutive  : %ui%si%uh%sh%s%c%%\r\n", 1u, -2, 3u, -4, "5", '6');
  // Expected: 1-23-456%

  // Single character strings & whitespace chars
  printf("Special chars: [%c] [%c] [%c%c]\r\n", ' ', '\t', '\r', '\n');
  // Expected: [ ] [	] [
  //           ]
}
__attribute__((section(".text.entry"))) void kernel_main(void) {
  setColorCode(VGA_COLOR_LIGHT_MAGENTA, VGA_COLOR_BLACK);

  test_printf();
  prints("\r\n");
  test_printf();
  prints("\nh\biii!\r\n");

  while (1)
    __asm__ volatile("hlt");
}
