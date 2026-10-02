bits 32

start_protected_mode:
	; init code segments
	mov    ax, DATA_SEG
	mov    ds, ax
	mov    es, ax
	mov    ss, ax
	mov    fs, ax
	mov    gs, ax

	; init stack pointer
	mov    esp, 0x90000

	; init registers
	xor    ebp, ebp
	xor    eax, eax
	xor    ebx, ebx
	xor    ecx, ecx
	xor    edx, edx
	xor    esi, esi
	xor    edi, edi

	; mov    dx, 0x3D4
	; mov    al, 0x0A ; Maximum Scan Line Register
	; out    dx, al

	; mov    dx, 0x3D5
	; mov    al, 0x20 ; Set Bit 5 (0x20) to disable cursor
	; out    dx, al

	call   load_kernel

	cli
	hlt


load_kernel:
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
