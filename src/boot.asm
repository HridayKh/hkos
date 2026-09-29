org 0x7C00 ; available memory: 0x00500 - 0x7FFFF
bits 16

%define __NL 0x0A ; ascii( \n )
%define __CR 0x0D ; ascii( \cr )
%define KEYBOARD_BUFFER 0x7E00 ; right after these 512 bytes
boot_start: ;--------------------------------- START -----------------------------------------
	xor   ax, ax ; ax = 0 ; cant write to (ds, es, ss) directly
	; note: shouldnt write to CS (code segment) ; cs:ip is current execution address
	mov   ds, ax ; data segment
	mov   es, ax ; extra segment
	mov   ss, ax ; stack segment
	mov   sp, 0x7C00 ; setup stack pointer ; goes down in memory towards 0x0500 ; ~30kb total

	mov   si, .msg_hello_world
	call  puts

	; take in and print ascii of, 1 character
	mov   si, .msg_enter_a_char_to_see_its_ascii
	call  puts ; print a message

	mov   cx, 1 ; only take in 1 character
	mov   si, KEYBOARD_BUFFER ; define the keyboard buffer for input
	call  text_input_until_counter ; take the input

	mov   si, .msg_new_line ; print a new line
	call  puts

	mov   ax, [KEYBOARD_BUFFER] ; print the ascii code
	call  putn


	; get and print queens's name
	mov   si, .msg_what_is_your_name_queen
	call  puts

	mov   si, KEYBOARD_BUFFER
	call  text_input_until_enter

	mov   si, .msg_hi_queen
	call  puts

	mov   si, KEYBOARD_BUFFER
	call  puts


	; disk reading lets goo!
	; chs: cylinder, head, sector
	; lets read the next sector from this one
	; which disk, which chs address, how many sectors, where to put it
	mov   ah, 2
	mov   al, 1
	mov   ch, 0
	mov   cl, 2
	mov   dh, 0
	mov   dl, 0 ; [diskNum]

	push  ax
	mov   ax, 0
	mov   es, ax
	pop   ax

	mov   bx, 0x7e00
	int   0x13
	mov   ah, 0x0e
	mov   al, [0x7e13]
	int   0x10

	; halt
	cli
	hlt
.msg_hello_world:
	db    'Hello, World!', __CR, __NL, 0 ; define byte, then null terminate
.msg_enter_a_char_to_see_its_ascii:
	db    'Enter a character to see its ASCII code: ', 0
.msg_what_is_your_name_queen:
	db    __CR, __NL, 'what is your name, queen? ', 0
.msg_hi_queen:
	db    __CR, __NL, 'hi queen ', 0
.msg_new_line:
	db    __CR, __NL, 0

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

___input: ;----------------------------------- INPUT -----------------------------------------
text_input_until_enter: ; takes keyboard input until enter pressed ; args: si - keyboard buffer start
			; stops on recieve enter ; ignores backsapce
	push  ax
	push  si
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
___end: ;----------------------------------- BOOT SIGN -----------------------------------------
;--- total size 307 bytes when last checked
	times 510-($-$$) db 0 ; 510 - (curr_line - start_of_program) ; db only writes 1 byte
	dw    0xAA55 ; writes word instead of 1 byte, equvlent to (db 0x55, 0xAA) ; little endian
	times 512 db 'A'