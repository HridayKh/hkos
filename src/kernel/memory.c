#include "memory.h"

void *memcpy(void *dest, const void *src, isize n) {
  u8 *s = (u8 *)src;
  u8 *d = (u8 *)dest;
  for (isize i = 0; i < n; i++)
    d[i] = s[i];
  return dest;
}
void *memmove(void *dest, const void *src, isize n) {
  u8 *s = (u8 *)src;
  u8 *d = (u8 *)dest;
  if (d < s) {
    for (isize i = 0; i < n; i++)
      d[i] = s[i];
  } else if (d > s) {
    for (isize i = n; i > 0; i--)
      d[i - 1] = s[i - 1];
  }
  return dest;
}
void *memset(void *s, u8 c, isize n) {
  u8 *p = (u8 *)s;
  u8 val = (u8)c;
  for (isize i = 0; i < n; i++)
    p[i] = val;
  return s;
}
void *memsetw(void *s, u16 c, isize n) {
  u16 *p = (u16 *)s;
  u16 val = (u16)c;
  for (isize i = 0; i < n; i++)
    p[i] = val;
  return s;
}
int memcmp(const void *s1, const void *s2, isize n) {
  u8 *p1 = (u8 *)s1;
  u8 *p2 = (u8 *)s2;

  for (isize i = 0; i < n; i++)
    if (p1[i] != p2[i])
      return (int)p1[i] - (int)p2[i];
  return 0;
}

isize strlen(const char *str) {
  isize len = 0;
  while (str[len] != '\0')
    len++;
  return len;
}
