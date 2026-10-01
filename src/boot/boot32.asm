bits 32
%define VIDEO_BUFFER 0xB8000

start_protected_mode:
	mov    ax, DATA_SEG
	mov    ds, ax
	mov    es, ax
	mov    ss, ax
	mov    fs, ax
	mov    gs, ax
	mov    esp, 0x90000

	mov    esi, .msg ; address of current char
	mov    eax, 0 ; value of current char
	mov    ebx, VIDEO_BUFFER ; value of video buffer
.print_loop:
	mov    byte al, [esi]
	or     eax, eax ; check if string end
	jz     .done1

	mov    [ebx], al ; print current char
	mov    byte [ebx + 1], 0x0D ; light magenta on black
	add    ebx, 2 ; set address for next char
	inc    esi
	jmp    .print_loop
.done1:

	mov    dx, 0x3D4
	mov    al, 0x0A ; Maximum Scan Line Register
	out    dx, al

	mov    dx, 0x3D5
	mov    al, 0x20 ; Set Bit 5 (0x20) to disable cursor
	out    dx, al

	xor    eax, eax
	xor    ecx, ecx
	xor    edi, edi

.load_kernel:
    ; 1. Read Sector 1 of Kernel (LBA 2048) directly to 0x100000
	mov    eax, 2048 ; Initial LBA
	mov    cl, 1 ; Load 1 sector first (pass in CL)
	mov    edi, 0x100000 ; Destination: 1 MB
	call   ata_lba_read

    ; 2. Read Sector Count from the header stored at 0x100000
	mov    ecx, [0x100000] ; Total sector count stored in header
	dec    ecx ; Subtract the 1 sector we already loaded
	cmp    ecx, 0
	jle    .done ; Skip loop if kernel fits in 1 sector

    ; 3. Setup loop variables for remaining sectors
	mov    eax, 2049 ; Start from next sector (LBA 2049)
	mov    edi, 0x100000 + 512 ; Destination buffer advances by 512 bytes

.read_loop:
	push   ecx ; Save loop counter (ECX)
	push   eax ; Save current LBA (EAX)

	mov    cl, 1 ; Read 1 sector at a time (pass in CL)
	call   ata_lba_read

	pop    eax ; Restore current LBA
	pop    ecx ; Restore loop counter

	inc    eax ; Advance to next LBA sector
	add    edi, 512 ; Advance RAM destination buffer by 512 bytes
	dec    ecx ; Decrement remaining sector count
	jnz    .read_loop

.done:
    ; 4. Jump past header directly to kernel execution entry point
	jmp    0x100004 ; Jump to kernel entry point

	cli
	hlt
.msg:
	db     'hi, hello!', 0


;=============================================================================
; ATA read sectors (28-bit LBA mode)
;
; EAX = LBA
; CL  = sector count
; EDI = destination buffer
;=============================================================================
ata_lba_read:
	pushfd
	and    eax, 0x0FFFFFFF
	push   eax
	push   ebx
	push   ecx
	push   edx
	push   edi

	mov    ebx, eax

	mov    edx, 0x1F6
	shr    eax, 24
	or     al, 0xE0
	out    dx, al

	mov    edx, 0x1F2
	mov    al, cl
	out    dx, al

	mov    eax, ebx
	mov    edx, 0x1F3
	out    dx, al

	mov    eax, ebx
	shr    eax, 8
	mov    edx, 0x1F4
	out    dx, al

	mov    eax, ebx
	shr    eax, 16
	mov    edx, 0x1F5
	out    dx, al

	mov    edx, 0x1F7
	mov    al, 0x20
	out    dx, al

.wait:
	in     al, dx
	test   al, 0x80 ; BSY
	jnz    .wait
	test   al, 0x08 ; DRQ
	jz     .wait

	movzx  ecx, cl
	shl    ecx, 8 ; sectors * 256 words
	mov    edx, 0x1F0
	rep    insw

	pop    edi
	pop    edx
	pop    ecx
	pop    ebx
	pop    eax
	popfd
	ret


;=============================================================================
; ATA write sectors (28-bit LBA mode)
;
; EAX = LBA
; CL  = sector count
; EDI = source buffer
;=============================================================================
ata_lba_write:
	pushfd
	and    eax, 0x0FFFFFFF
	push   eax
	push   ebx
	push   ecx
	push   edx
	push   edi
	push   esi

	mov    ebx, eax

	mov    edx, 0x1F6
	shr    eax, 24
	or     al, 0xE0
	out    dx, al

	mov    edx, 0x1F2
	mov    al, cl
	out    dx, al

	mov    eax, ebx
	mov    edx, 0x1F3
	out    dx, al

	mov    eax, ebx
	shr    eax, 8
	mov    edx, 0x1F4
	out    dx, al

	mov    eax, ebx
	shr    eax, 16
	mov    edx, 0x1F5
	out    dx, al

	mov    edx, 0x1F7
	mov    al, 0x30
	out    dx, al

.wait:
	in     al, dx
	test   al, 0x80 ; BSY
	jnz    .wait
	test   al, 0x08 ; DRQ
	jz     .wait

	mov    esi, edi
	movzx  ecx, cl
	shl    ecx, 8 ; sectors * 256 words
	mov    edx, 0x1F0
	rep    outsw

.wait_complete:
	in     al, dx
	test   al, 0x80 ; wait for BSY to clear
	jnz    .wait_complete

	pop    esi
	pop    edi
	pop    edx
	pop    ecx
	pop    ebx
	pop    eax
	popfd
	ret
