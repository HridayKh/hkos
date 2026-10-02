
#ifndef ____HKOS_INTS_HEADER_DEFINED____ // check if this header defined
#define ____HKOS_INTS_HEADER_DEFINED____ // mark as defined

// unsigned ints
typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32; // "unsigned long" is untested in 64b
typedef unsigned long long u64;

// signed ints
typedef char s8;
typedef short s16;
typedef int s32; // "unsigned long" is untested in 64b
typedef long long s64;

// size of pointers
#ifdef __IN_LONG_MODE__
typedef u64 iptr; // 64b addresses in long mode
typedef u64 isize;
#else
typedef u32 iptr; // 32b addresses in protected mode
typedef u32 isize;
#endif

#endif
