ENTRY(main)

SECTIONS {
    . = 0x100000;

    .text : {
        KEEP(*(.text))
        KEEP(*(.text.*))
    }

    .data : {
        *(.data)
    }

    .bss : {
        *(.bss)
    }
}