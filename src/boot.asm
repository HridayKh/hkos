org 0x7C00 ; available memory: 0x00500 - 0x7FFFF
bits 16

	; init the registers
	xor   ax, ax ; ax = 0 ; cant write to (ds, es, ss) directly
	xor   bx, bx
	xor   cx, cx
	xor   dx, dx
	mov   sp, 0x7C00 ; setup stack pointer ; goes down in memory towards 0x0500 ; ~30kb total ; shared with keyboard
	xor   bp, bp
	xor   si, si
	xor   di, di
	; note: shouldnt write to CS (code segment) ; cs:ip is current execution address
	mov   ds, ax ; data segment
	mov   es, ax ; extra segment
	mov   ss, ax ; stack segment

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

	; move to 32  bit mode
	cli
	lgdt  [gdt_descriptor]
	mov   eax, cr0
	or    eax, 1
	mov   cr0, eax

	jmp   CODE_SEG:start_protected_mode

	times 510-($-$$) db 0 ; 510 - (curr_line - start_of_program) ; db only writes 1 byte
	dw    0xAA55 ; writes word instead of 1 byte, equvlent to (db 0x55, 0xAA) ; little endian

bits 32
%define VID 0xB8000
start_protected_mode:
	mov   al, 65 ; 65 = 'A'
	mov   ah, 0x0F ; white on black
	mov   [VID], ax
	cli
	hlt


