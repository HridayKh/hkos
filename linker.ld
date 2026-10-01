ENTRY(kernel_main)

SECTIONS
{
    . = 0x100000;

    _kernel_start = .;

    .header : {
        /* Store total size in dwords (32-bit int) */
        LONG((_kernel_end - _kernel_start + 511) / 512); /* Sector count */
    }

    .text : {
        *(.text.entry)
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data*)
    }

    .bss : {
        *(.bss*)
        *(COMMON)
    }

    _kernel_end = .;
}