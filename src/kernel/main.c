__attribute__((section(".text.entry"))) void kernel_main(void) {

  *(char *)0xB8000 = 'X';
  *(char *)0xB8001 = 0x0F;

  while (1) {
    __asm__ volatile("hlt");
  }
}