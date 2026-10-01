org 0x7C00 ; available memory: 0x00500 - 0x7FFFF
bits 16

%define __LF 0x0A ; ascii( \n )
%define __CR 0x0D ; ascii( \cr )
%define KEYBOARD_BUFFER 0x0500 ; will go up in memory towards 0x7C00 ; ~30kb total ; shared with stack
boot_start: ;--------------------------------- START -----------------------------------------
	mov   [___drive_io], dl ; store the drive id
	; init the registers
	xor   ax, ax ; ax = 0 ; cant write to (ds, es, ss) directly
	mov   sp, 0x7C00 ; setup stack pointer ; goes down in memory towards 0x0500 ; ~30kb total ; shared with keyboard
	mov   ds, ax ; data segment
	mov   es, ax ; extra segment
	mov   ss, ax ; stack segment

	call  set_disk_params ; init the disk params

	; print hi queen
	mov   si, .msg_hi_queen
	call  puts

	xor   ax, ax
	mov   es, ax ; buffer
	mov   bx, 0x7E00 ; buffer
	mov   ax, 1 ; lba
	mov   si, 2 ; num sectors
	call  read_lba

	; move to 32  bit mode
	cli
	lgdt  [gdt_descriptor]
	mov   eax, cr0
	or    eax, 1
	mov   cr0, eax

	jmp   CODE_SEG:start_protected_mode

	cli
	hlt
.msg_hi_queen:
	db    'hi queen', __CR, __LF, 0
; .msg_new_line:
; 	db    __CR, __LF, 0
___printing: ;-------------------------------- PRINT -----------------------------------------
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
;--------------------------------------------------------------------------------------------------
putn: ; prints number to screen ; args: ax - num to print
	push  ax ; division quotient
	push  bx ; counter of digits
	push  cx ; base 10 divisor
	push  dx ; division remainder
	mov   bx, 2 ; start digit counter at 2 due to \cr \n
	mov   cx, 0xFFDA ; move \cr\n to stack so they get printed after the number
	push  cx ; moving '\cr'-48 so it becomes `\cr` when 48 is later added
	mov   cx, 0xFFDD ; same for \n
	push  cx
	mov   cx, 10 ; setup base 10 divisor
.loop:
	xor   dx, dx ; dividend high
	div   cx ; dx:ax / cx = (ax quotient, dx remainder)
	push  dx ; push digit to stack
	inc   bx ; update digit counter
	or    ax, ax ; check if more digits
	jnz   .loop ; continue loop if more digits left
.print_loop:
	pop   ax ; get the digit to print
	add   al, 48 ; add 48 so digit becomes ascii code
	mov   ah, 0xE ; bios interupt AH(0xE): write chars in tty mode to screen
	xor   bh, bh ; interupt param BH = page num (text modes)
	int   0x10 ; 0x10 is where video driver for bios is
	dec   bx ; update counter
	or    bx, bx ; check if more digits left
	jnz   .print_loop ; do next digit
.done:
	pop   dx
	pop   cx
	pop   bx
	pop   ax
	ret

; ___input: ;----------------------------------- INPUT -----------------------------------------
text_input_until_enter: ; takes keyboard input until enter pressed ; args: si - keyboard buffer start
			; stops on recieve enter ; ignores backsapce
	push  ax
	push  si
	mov   byte [si], 0 ; initialise the kb buffer with a null terminator
.input_loop:
	mov   ah, 0 ; specify next char function
	int   0x16 ; interupt code for keyboard input

	cmp   al, 8 ; if curr char is backspace, do nothing
	je    .input_loop
	cmp   al, 13 ; if curr char is new line, stop
	je    .done

	mov   [si], al ; store current char into kb buffer (si)
	mov   byte [si+1], 0 ; set next char as string null terminator ; to be overwritten when next char is input
	call  puts ; print current char
	inc   si ; increment the si (location for the next char)

	jmp   .input_loop
.done:
	pop   si
	pop   ax
	ret
text_input_until_counter: ; takes keyboard input until enter pressed ; args: cx - char counter, si - keyboard buffer start
			  ; doesn't ignore any character
	push  ax
	push  cx
	push  si
.input_loop:
	mov   ah, 0 ; specify next char function
	int   0x16 ; interupt code for keyboard input

	mov   [si], al ; store current char into kb buffer (si)
	mov   byte [si+1], 0 ; set next char as string null terminator ; to be overwritten when next char is input
	call  puts ; print current char
	inc   si ; increment the si (location for the next char)
	
	dec   cx ; update the char counter
	jnz   .input_loop ; continues next chars only if counter is not 0
.done:
	pop   si
	pop   cx
	pop   ax
	ret

___drive_io: ;------------------------------ DRIVE I/O -----------------------------------------
	db    0 ; stores the drive id
drive_cylinders: ; 10-bit, stored as 16-bit
	db    0, 0
drive_sectors_per_track:
	db    0
drive_total_heads:
	db    0
drive_count:
	db    0
set_disk_params: ; sets the memory constants for the disks
	pusha

	mov   ah, 0 ; reset the drive
	int   0x13
	
	stc
	mov   byte ah, 0x08 ; function 8, get drive parameters
	mov   byte dl, [___drive_io] ; set drive id/number
	int   0x13 ; call bios drive interupt
	jc    .error

	mov   ax, cx ; ax for sectors per track
	and   ax, 0x003F ; 0000 0000 0011 1111
	mov   [drive_sectors_per_track], al ; sectors per track

	mov   ax, cx ; ax has top 2 bits for cylinders ; cx has lower

	shl   ax, 2
	and   ax, 0x0300 ; 0000 0011 0000 0000
	shr   cx, 8
	and   cx, 0x00FF ; 0000 0000 1111 1111
	or    ax, cx
	add   ax, 1
	mov   [drive_cylinders], ax ; cylinders

	add   dh, 1 ; bios returns 0-indexed
	mov   [drive_total_heads], dh ; num of heads
	mov   [drive_count], dl ; num of drives attached
	jmp   .done
.error:
	mov   si, .error_msg
	call  puts
.done:
	popa
	ret
.error_msg:
	db    'Unable to get drive params', __CR, __LF, 0
;--------------------------------------------------------------------------------------------------

lba_to_chs: ; converts 0-indexed lba into chs, ready for int13h args: ax = lba address
	    ; returns: cx = cylinder / sector, dh = head, dl = drive number
	push  ax
	push  bx
	    
	mov   bx, ax ; store the lba into bx, continue using ax as the temp var


	mov   dx, 0 ; dx:ax = lba
	mov   cx, [drive_sectors_per_track] ; cx = sectors/track
	or    cx, cx ; check for 0
	jz    .error
	div   cx ; dx remainder, ax quotient

	add   dl, 1 ; sectors are 1-indexed
	mov   bl, dl ; store sector count in bx for now with mask
	and   bx, 0x003F ; 0000 0000 0011 1111


	mov   dx, 0 ; dx:ax = lba
	mov   cx, [drive_total_heads] ; cx: total heads
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
	db    'err lba->chs', __CR, __LF, 0

;--------------------------------------------------------------------------------------------------
read_lba: ; read sectors from disk ; args: es:bx = buffer where to store, ax = lba address, si = num of sectors
	pusha
	
	mov   di, 3
	call  lba_to_chs
.attempt:
	or    di, di
	jz    .err_done
	dec   di

	; push  ax
	; mov   ax, di
	; call  putn
	; pop   ax

	mov   ax, si ; num of sectors to read
	mov   ah, 0x02 ; read disk sector function
	stc
	int   0x13 ; call disk interupt
	jnc   .done ; success
	
	call  putn ; 3073 = 0000 1100 00000001

	mov   ah, 0
	mov   dl, [___drive_io]
	int   0x13 ; reset the drive

	jmp   .attempt

.err_done:
	mov   ah, 0
	cmp   si, ax ; check if num of sectors read equals sectors to be read
	je    .err_done

	mov   si, .msg_err
	call  puts
	stc
.done:
	popa
	ret
.msg_err:
	db    'disk read error', __CR, __LF, 0





___end: ;----------------------------------- BOOT SIGN -----------------------------------------
;--- total size 476 bytes when last checked
	times 510-($-$$) db 0 ; 510 - (curr_line - start_of_program) ; db only writes 1 byte
	dw    0xAA55 ; writes word instead of 1 byte, equvlent to (db 0x55, 0xAA) ; little endian
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
; EQU is used to set constants

bits 32
%define VID 0xB8000
start_protected_mode:
	jmp   mode


mode:
	mov   ax, DATA_SEG
	mov   ds, ax
	mov   es, ax
	mov   fs, ax
	mov   gs, ax
	mov   ss, ax
	mov   esp, 0x90000 ; Set up a safe 32-bit stack in low RAM

    ; 4. Write 'A' (White on Black) directly to VGA Video Memory
	mov   byte [0xB8000], 65
	mov   byte [0xB8001], 0x0F
	cli
	hlt


