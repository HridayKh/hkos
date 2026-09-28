org 0x7C00
bits 16

%define __NL 0x0A ; ascii( \n )
%define __CR 0x0D ; ascii( \cr )
%define KEYBOARD_BUFFER 0x7E00 ; right after these 512 bytes
;---------------------------------------   BOOT   --------------------------------------------
boot_start:
	xor   ax, ax ; ax = 0 ; cant write to (ds, es) directly
	mov   ds, ax ; ds is data segment register, to represent segment part of address of data
	mov   es, ax ; another data segment register


	mov   ss, ax ; setup stack
	mov   sp, 0x7C00 ; goes down in memory

	mov   si, .msg
	call  puts

	mov   ax, 0 ; print 0
	call  putn
	mov   ax, 34 ; print 34
	call  putn

	mov   ah, 0 ; take input
	int   0x16
	mov   si, KEYBOARD_BUFFER
	and   ax, 0x00ff
	call  putn


	mov   si, .keyboard
	call  puts

	mov   bx, KEYBOARD_BUFFER
.l:
	mov   ah, 0 ; take input
	int   0x16

	mov   [bx], al ; store current char into current kb buffer address (bx)
	mov   si, bx ; store the current char's pos into si (input for puts)

	cmp   al, 13 ; if curr char is new line, stop
	je    .done

	inc   bx ; increment the bx (location for the next char)
	mov   byte [bx], 0 ; put 0 in the next char's positon so puts knows to stop ; to be overwritten when next char is input
	call  puts
	jmp   .l
.done:
	mov   si, .hi
	call  puts
	mov   si, KEYBOARD_BUFFER
	call  puts

	cli
	hlt
.msg:
	db    'Hello, World!', __CR, __NL, 0 ; define byte, then null terminate
.keyboard:
	db    __CR, __NL, 'enter 1st 6 chars of your name: ', 0
.hi:
	db    __CR, __NL, 'hi queen ', 0

;---------------------------------------   PRINTING   ------------------------------------------
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
	mov   cl, 0xFFDA ; move \cr\n to stack so they get printed after the number
	push  cx ; moving '\cr'-48 so it becomes `\cr` when 48 is later added
	mov   cl, 0xFFDD ; same for \n
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
;---------------------------------------   BOOT SIGNATURE   ---------------------------------------
;--- total size 302 bytes when last checked
	times 510-($-$$) db 0 ; 510 - (curr_line - start_of_program) ; db only writes 1 byte
	dw    0xAA55 ; writes word isntead of 1 byte, equvlent to (db 0x55, 0xAA) ; little endian
