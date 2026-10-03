#ifndef HKOS_IO_H
#define HKOS_IO_H

#include "ints.h"

// Variadic macros for custom printf implementation
#define vaList __builtin_va_list
#define vaStart __builtin_va_start
#define vaArg __builtin_va_arg
#define vaEnd __builtin_va_end
#define vaCopy __builtin_va_copy

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
static inline void push(u32 val) {
  __asm__ volatile("push %0" : : "r"(val) : "memory");
}
static inline u32 pop(void) {
  u32 val;
  __asm__ volatile("pop %0" : "=r"(val) : : "memory");
  return val;
}

extern u8 cursorx;
extern u8 cursory;

void printc(u8 charAscii);
void prints(char *str);
void printf(const char *str, ...);

#endif // HKOS_IO_H
