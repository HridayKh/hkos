org 0x7C00 ; available memory: 0x00500 - 0x7FFFF
bits 16

%define __LF 0x0A ; ascii( \n )
%define __CR 0x0D ; ascii( \cr )
%define KEYBOARD_BUFFER 0x0500 ; will go up in memory towards 0x7C00 ; ~30kb total ; shared with stack
%define SECTORS_TO_LOAD 5
boot_start: ;--------------------------------- START -----------------------------------------
	mov   [___drive_io], dl ; store the drive id
	; init the registers
	xor   ax, ax ; ax = 0 ; cant write to (ds, es, ss) directly
	mov   sp, 0x7C00 ; setup stack pointer ; goes down in memory towards 0x0500 ; ~30kb total ; shared with keyboard
	mov   ds, ax ; data segment
	mov   es, ax ; extra segment
	mov   ss, ax ; stack segment


	; init disk and a20 line
	call  set_disk_params ; init the disk params
	in    al, 0x92 ; enable a20 line
	or    al, 2 ; Set bit 1 (Fast A20 Gate)
	out   0x92, al


	; read the next sector, where 32-bit mode starts
	xor   ax, ax
	mov   es, ax ; buffer segment
	mov   bx, 0x7E00 ; buffer offset
	mov   ax, 1 ; lba
	mov   si, SECTORS_TO_LOAD ; num sectors
	call  read_lba


	mov   ah, 6 ; scroll up function
	mov   al, 0 ; entire window
	mov   bh, 0x0f ; white on black
	mov   cx, 0x0000 ; CH = 0, CL = 0 (upper left corner)
	mov   dx, 0xffff ; DH = 24, DL = 79 (lower right corner)
	int   0x10 ; Call BIOS video interrupt

	mov   ah, 0x02 ; AH = 02h (Set cursor position)
	mov   bh, 0x00 ; BH = 0 (Page number)
	mov   dh, 0x00 ; DH = 0 (Row)
	mov   dl, 0x00 ; DL = 0 (Column)
	int   0x10 ; Call BIOS video interrupt

	; move to 32  bit mode
	cli
	lgdt  [gdt_descriptor]
	mov   eax, cr0
	or    eax, 1
	mov   cr0, eax

	jmp   CODE_SEG:start_protected_mode

	cli
	hlt
puts: ; prints string to screen until it encounters null
      ; args: ds:si points to string
	push  si ; source index for string stuff
	push  ax ; (al, ah) are (low, high) bytes of ax
	push  bx
.loop:
	lodsb ; equiv to	mov al, [si] ; mov into al, mem contents of ds:si ; ds is default for si, ie, [si] = [ds:si]
	      ; 		inc si ; increment si so it points to next char
	or    al, al ; modify flag to see if it is null (0)
	jz    .done ; stop if it in null
	mov   ah, 0xE ; bios interupt AH(0xE): write chars in tty mode to screen
	xor   bh, bh ; interupt param BH = page num (text modes)
	int   0x10 ; 0x10 is where video driver for bios is
	jmp   .loop
.done:
	pop   bx
	pop   ax
	pop   si
	ret
___drive_io: ;------------------------------ DRIVE I/O -----------------------------------------
	db    0 ; stores the drive id
; drive_cylinders:  db 0, 0 ; 10-bit, stored as 16-bit
drive_sectors_per_track:
	db    0
drive_total_heads:
	db    0
; drive_count:  db 0
set_disk_params: ; sets the memory constants for the disks
	push  ax
	push  cx
	push  dx

	mov   ah, 0 ; reset the drive
	int   0x13
	
	stc
	mov   byte ah, 0x08 ; function 8, get drive parameters
	mov   byte dl, [___drive_io] ; set drive id/number
	int   0x13 ; call bios drive interupt
	jc    .error

	; mov   ax, cx ; ax for sectors per track
	; and   ax, 0x003F ; 0000 0000 0011 1111
	; mov   [drive_sectors_per_track], al ; sectors per track
	and   cx, 0x003F
	mov   [drive_sectors_per_track], cl ; sectors per track

	; mov   ax, cx ; ax has top 2 bits for cylinders ; cx has lower

	; shl   ax, 2
	; and   ax, 0x0300 ; 0000 0011 0000 0000
	; shr   cx, 8
	; and   cx, 0x00FF ; 0000 0000 1111 1111
	; or    ax, cx
	; add   ax, 1
	; mov   [drive_cylinders], ax ; cylinders

	add   dh, 1 ; bios returns 0-indexed
	mov   [drive_total_heads], dh ; num of heads
	; mov   [drive_count], dl ; num of drives attached
	jmp   .done
.error:
	push  si
	mov   si, .error_msg
	call  puts
	pop   si
.done:
	pop   dx
	pop   cx
	pop   ax
	ret
.error_msg:
	db    'err16 info', __CR, __LF, 0
;--------------------------------------------------------------------------------------------------

lba_to_chs: ; converts 0-indexed lba into chs, ready for int13h args: ax = lba address
	    ; returns: cx = cylinder / sector, dh = head, dl = drive number
	push  ax
	push  bx
	    
	mov   bx, ax ; store the lba into bx, continue using ax as the temp var


	mov   dx, 0 ; dx:ax = lba
	xor   cx, cx
	mov   cl, [drive_sectors_per_track] ; cx = sectors/track
	or    cx, cx ; check for 0
	jz    .error
	div   cx ; dx remainder, ax quotient

	add   dl, 1 ; sectors are 1-indexed
	mov   bl, dl ; store sector count in bx for now with mask
	and   bx, 0x003F ; 0000 0000 0011 1111


	mov   dx, 0 ; dx:ax = lba
	xor   cx, cx
	mov   cl, [drive_total_heads] ; cx: total heads
	or    cx, cx ; check for 0
	jz    .error
	div   cx ; dx remainder, ax quotient

	shl   dx, 8 ; dh now has the head
	mov   dl, [___drive_io] ; now dx is in its final format


	mov   cx, 0 ; init cx as 0
	mov   ch, al ; mov lower 8 bits of cylinder to ch (final location)

	shr   ax, 2
	and   ax, 0x00C0 ; 0000 0000 1100 0000
	or    cx, ax ; cx now has cylinder in proper format

	or    cx, bx ; cx is in return format after combining with sector count

	pop   bx
	pop   ax
	ret
.error:
	push  si
	mov   si, .msg_error
	call  puts
	pop   si
	ret
.msg_error:
	db    'err16 lba', __CR, __LF, 0

;--------------------------------------------------------------------------------------------------
read_lba: ; read sectors from disk ; args: es:bx = buffer where to store, ax = lba address, si = num of sectors
	push  ax
	push  bx
	push  cx
	push  dx
	push  di
	push  es
	
	mov   di, 3
	call  lba_to_chs ; sets cx too
.attempt:
	or    di, di
	jz    .err_done
	dec   di

	mov   ax, si ; num of sectors to read
	mov   ah, 0x02 ; read disk sector function
	stc
	int   0x13 ; call disk interupt
	jnc   .done ; success
	
	mov   ah, 0
	mov   dl, [___drive_io]
	int   0x13 ; reset the drive

	jmp   .attempt
.err_done:
	push  si
	mov   si, .msg_err
	call  puts
	pop   si
	stc
.done:
	pop   es
	pop   di
	pop   dx
	pop   cx
	pop   bx
	pop   ax
	ret
.msg_err:
	db    'err16 read', __CR, __LF, 0



gdt_start:
null_descriptor: ; GDTR Offset + 0
	dd    0, 0
; ==============================================================================
; CODE SEGMENT DESCRIPTOR (Selector: 0x08)
; Sets up a 32-bit flat Code Segment starting at 0x00000000 spanning all 4 GB.
; ==============================================================================
code_descriptor: ; GDT Offset + 8 (0x08)
	dw    0xFFFF ; Limit (bits 0-15)  : 0xFFFF
	dw    0x0000 ; Base  (bits 0-15)  : 0x0000
	db    0x00 ; Base  (bits 16-23) : 0x00
    
    ; Access Byte: 0b10011010 (0x9A)
    ; | Bit 7 | Bits 6-5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0 |
    ; |   P   |   DPL    |   S   |  E/C  |  C/E  |  R/W  |   A   |
    ; |   1   |    00    |   1   |   1   |   0   |   1   |   0   |
    ;   P   (1)  = Present in memory
    ;   DPL (00) = Privilege level (Ring 0 / Kernel Mode)
    ;   S   (1)  = Descriptor type (1 = (Code/Data) segment, 0 = System segment)
    ;   E/C (1)  = Executable (1 = Code Segment)
    ;   C/E (0)  = Conforming (0 = Only code with equal privilege can jump here)
    ;   R/W (1)  = Readable (1 = Code can be read for constants/literals)
    ;   A   (0)  = Accessed bit (Set to 1 automatically by CPU when used)
	db    10011010b

    ; Flags (bits 7-4) & Limit (bits 19-16) (0b11001111 = 0xCF)
    ; Flags: 0b1100 (4 bits)
    ;   G (1) = Granularity (1 = Limit is scaled by 4 KB pages: 0xFFFFF * 4 KB = 4 GB)
    ;   D (1) = Default operation size (1 = 32-bit Protected Mode code)
    ;   L (0) = 64-bit code segment (0 = 32-bit segment)
    ;   A (0) = Reserved / Available for systems software
    ; Limit: 0b1111 (4 bits) -> Limit bits 16-19 (0xF)
	db    11001111b

	db    0x00 ; Base  (bits 24-31) : 0x00

; ==============================================================================
; DATA SEGMENT DESCRIPTOR (Selector: 0x10)
; Sets up a 32-bit flat Data/Stack Segment starting at 0x00000000 spanning all 4 GB.
; ==============================================================================
data_descriptor: ; GDT Offset + 16 (0x10)
	dw    0xFFFF ; Limit (bits 0-15)  : 0xFFFF
	dw    0x0000 ; Base  (bits 0-15)  : 0x0000
	db    0x00 ; Base  (bits 16-23) : 0x00
    
    ; Access Byte: 0b10010010 (0x92)
    ; | Bit 7 | Bits 6-5 | Bit 4 | Bit 3 | Bit 2 | Bit 1 | Bit 0 |
    ; |   P   |   DPL    |   S   |  E/C  |  C/E  |  R/W  |   A   |
    ; |   1   |    0     |   1   |   0   |   0   |   1   |   0   |
    ;   P   (1)  = Present in memory
    ;   DPL (00) = Privilege level (Ring 0 / Kernel Mode)
    ;   S   (1)  = Descriptor type (1 = (Code/Data) segment, 0 = System segment)
    ;   E/C (0)  = Executable (0 = Data Segment)
    ;   C/E (0)  = Direction bit (0 = Segment grows UPWARD)
    ;   R/W (1)  = Writable (1 = Data segment can be written to)
    ;   A   (0)  = Accessed bit (Set to 1 automatically by CPU when used)
	db    10010010b

    ; Flags (bits 7-4) & Limit (bits 19-16) (0b11001111 = 0xCF)
    ; Flags: 0b1100 (4 bits)
    ;   G (1) = Granularity (1 = Limit is scaled by 4 KB pages: 0xFFFFF * 4 KB = 4 GB)
    ;   B (1) = Big / Stack Size (1 = 32-bit stack pointer ESP used)
    ;   0 (0) = Reserved
    ;   A (0) = Reserved / Available for systems software
    ; Limit: 0b1111 (4 bits) -> Limit bits 16-19 (0xF)
	db    11001111b

	db    0x00 ; Base  (bits 24-31) : 0x00
gdt_end:
gdt_descriptor:
	dw    gdt_end - gdt_start - 1 ; gdt size
	dd    gdt_start ; start of the gdt (offset)
CODE_SEG equ code_descriptor - gdt_start
DATA_SEG equ data_descriptor - gdt_start

___boot_sign: ;----------------------------- BOOT SIGN -----------------------------------------
;--- total size 344 bytes when last checked
	times 510-($-$$) db 0
	dw    0xAA55
%include "boot32.asm"
