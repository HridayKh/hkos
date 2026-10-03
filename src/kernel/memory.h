#ifndef HKOS_MEMORY_H
#define HKOS_MEMORY_H

#include "ints.h"

void *memcpy(void *dest, const void *src, isize n);
void *memmove(void *dest, const void *src, isize n);
void *memset(void *s, u8 c, isize n);
void *memsetw(void *s, u16 c, isize n);
int memcmp(const void *s1, const void *s2, isize n);

isize strlen(const char *str);

#endif // HKOS_MEMORY_H
