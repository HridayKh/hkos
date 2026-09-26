org 0x7C00
bits 16

%define __NL 0x0A ; ascii( \n )
%define __CR 0x0D ; ascii( \r )
	jmp   near boot_start ; jump to start of the loader
bdb_oem:
	db    'MSWIN4.1' ; 8 bytes
bdb_bytes_per_sector:
	dw    512
bdb_sectors_per_cluster:
	db    1
bdb_reserved_sectors:
	dw    1
bdb_fat_count:
	db    2
bdb_dir_entries_count:
	dw    0xE0
bdb_total_sectors:
	dw    2880 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:
	db    0xF0 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:
	dw    9 ; 9 sectors/fat
bdb_sectors_per_track:
	dw    18
bdb_heads:
	dw    2
bdb_hidden_sectors:
	dd    0
bdb_large_sector_count:
	dd    0
; extended boot record
ebr_drive_number:
	db    0 ; 0x00 floppy, 0x80 hdd, useless
	db    0 ; reserved
ebr_signature:
	db    0x29
ebr_volume_id:
	db    0x69, 0x69, 0x69, 0x69 ; serial number, value doesn't matter
ebr_volume_label:
	db    ' HKOS HKOS ' ; 11 bytes, padded with spaces
ebr_system_id:
	db    'FAT12   ' ; 8 bytes

;---------------------------------------   BOOT   --------------------------------------------
boot_start:
	xor   ax, ax ; ax = 0 ; cant write to (ds, es) directly
	mov   ds, ax ; ds is data segment register, to represent segment part of address of data
	mov   es, ax ; another data segment register

	
	mov   ss, ax ; setup stack
	mov   sp, 0x7C00 ; goes down in memory

	mov   si, .msg
	call  puts


	; read something from floppy disk
	; BIOS should set DL to drive number
	mov   [ebr_drive_number], dl

	mov   ax, 1 ; LBA=1, second sector from disk
	mov   cl, 1 ; 1 sector to read
	mov   bx, 0x7E00 ; data should be after the bootloader
	call  disk_read

	mov   ax, [es:bx]
	call  putn


	mov   ax, 0 ; print 0
	call  putn
	mov   ax, 34 ; print 34
	call  putn

	cli
	hlt
.msg:
	db    'Hello, World!', __CR, __NL, 0 ; define byte, then null terminate

;---------------------------------------   PRINTING   ------------------------------------------
puts: ; prints string to screen until it encounters null
      ; args: ds:si points to string
	push  si ; source index for string stuff
	push  ax ; (al, ah) are (low, high) bytes of ax
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
	pop   ax
	pop   si
	ret
;--------------------------------------------------------------------------------------------------
putn: ; prints number to screen      ; args: ax - num to print
	push  ax ; division quotient
	push  bx ; counter of digits
	push  cx ; base 10 divisor
	push  dx ; division remainder
	xor   bx, bx ; start digit counter at 0
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
	call  .print_ax ; print char in ax
	dec   bx ; update counter
	or    bx, bx ; check if more digits left
	jnz   .print_loop ; do next digit
.done:
	mov   al, __CR ; print \c\n
	call  .print_ax
	mov   al, __NL
	call  .print_ax
	pop   dx
	pop   cx
	pop   bx
	pop   ax
	ret
.print_ax:
	mov   ah, 0xE ; bios interupt AH(0xE): write chars in tty mode to screen
	xor   bh, bh ; interupt param BH = page num (text modes)
	int   0x10 ; 0x10 is where video driver for bios is
	ret

;---------------------------------------   ERROR HANDLERS   ---------------------------------------
floppy_error:
	mov   si, msg_read_failed
	call  puts
wait_key_and_reboot:
	mov   ah, 0
	int   0x16 ; wait for keypress
	jmp   0xFFFF:0 ; jump to beginning of BIOS, should reboot
.halt:
	cli ; disable interrupts, this way CPU can't get out of "halt" state
	hlt
msg_read_failed:
	db    'Read from disk failed! Press any key to reboot.....', 0


;---------------------------------------   DISKS ROUTINES   ---------------------------------------

; Convert LBA to CHS address
; Parameters:
;	- ax: LBA address
; Returns:
;	- cx [bits 0-5]: sector number
;	- cx [bits 6-15]: cylinder
;	- db: head
lba_to_chs:

	push  ax
	push  cx
	push  dx

	xor   dx, dx ; dx = 0
	div   word [bdb_sectors_per_track] ; ax = LBA / SectorsPerTrack
                                           ; dx = LBA % SectorsPerTrack

	inc   dx ; dx = (LBA % SectorsPerTrack + 1) = sector
	mov   cx, dx ; cx = sector

	xor   dx, dx ; dx = 0
	div   word [bdb_heads] ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                               ; dx = (LBA / SectorsPerTrack) % Heads = head
	mov   dh, dl ; dh = head
	mov   ch, al ; ch = cylinder (lower 8 bits)
	shl   ah, 6
	or    cl, ah ; put upper 2 bits of cylinder in CL

	pop   dx
	pop   cx
	pop   ax
	ret

;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;
disk_read:

	push  ax ; save registers we will modify
	push  bx
	push  cx
	push  dx
	push  di

	call  lba_to_chs ; compute CHS
	mov   ax, cx ; AL = number of sectors to read
    
	mov   ah, 0x2
	mov   di, 3 ; retry count
.retry:
	pusha ; save all registers, we don't know what bios modifies
	stc ; set carry flag, some BIOS'es don't set it
	int   0x13 ; carry flag cleared = success
	jnc   .done ; jump if carry not set
    ; read failed
	popa
	call  disk_reset

	dec   di
	test  di, di
	jnz   .retry

.fail:
    ; all attempts are exhausted
	jmp   floppy_error

.done:
	popa

	pop   di
	pop   dx
	pop   cx
	pop   bx
	pop   ax ; restore registers modified
	ret


;
; Resets disk controller
; Parameters:
;   dl: drive number
;
disk_reset:
	pusha
	mov   ah, 0
	stc
	int   13h
	jc    floppy_error
	popa
	ret
;---------------------------------------   BOOT SIGNATURE   ---------------------------------------
;--- total size 302 bytes when last checked
	times 510-($-$$) db 0 ; 510 - (curr_line - start_of_program) ; db only writes 1 byte
	dw    0xAA55 ; writes word isntead of 1 byte, equvlent to (db 0x55, 0xAA) ; little endian
