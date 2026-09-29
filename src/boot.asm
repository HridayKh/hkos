org 0x7C00 ; available memory: 0x00500 - 0x7FFFF
bits 16

	xor   ax, ax
	mov   ds, ax
	mov   es, ax
	mov   ss, ax
	mov   sp, 0x7C00


	; move to 32  bit mode
	cli
	lgdt  [gdt_descriptor]
	mov   eax, cr0
	or    eax, 1
	mov   cr0, eax

	jmp   CODE_SEG:start_protected_mode

gdt_start:
null_descriptor:
	dd    0, 0
code_descriptor:
	dw    0xFFFF ; limit: 0xf ffff
	dw    0 ;
	db    0
	db    0b10011010
	db    0b11001111
	db    0
data_descriptor:
	dw    0xFFFF ; limit: 0xf ffff
	dw    0 ;
	db    0
	db    0b10010010
	db    0b11001111
	db    0
gdt_end:
gdt_descriptor:
	dw    gdt_end - gdt_start - 1
	dd    gdt_start
CODE_SEG equ code_descriptor - gdt_start
DATA_SEG equ data_descriptor - gdt_start

bits 32
%define VID 0xB8000
start_protected_mode:
	mov   ax, DATA_SEG
	mov   ds, ax
	mov   es, ax
	mov   fs, ax
	mov   gs, ax
	mov   ss, ax
	mov   esp, 0x90000 ; Set up a safe 32-bit stack in low RAM

    ; 4. Write 'A' (White on Black) directly to VGA Video Memory
	mov   byte [0xB8000], 'A'
	mov   byte [0xB8001], 0x0F
	cli
	hlt



	times 510-($-$$) db 0 ; 510 - (curr_line - start_of_program) ; db only writes 1 byte
	dw    0xAA55 ; writes word instead of 1 byte, equvlent to (db 0x55, 0xAA) ; little endian
