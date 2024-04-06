vga = 0xB8000;
load_idt = 0x7E20;
enable_interrupts = 0x7E39;
disable_interrupts = 0x7E3B;
iretq = 0x7E3D;

ENTRY(_start)

PHDRS
{
  text PT_LOAD FILEHDR PHDRS;
}
SECTIONS
{
    . = SEGMENT_START("text-segment", 0x101000) + SIZEOF_HEADERS;
    .text . : {
        *(.text .gnu.linkonce.t*)
        *(.rodata .rodata.* .gnu.linkonce.r*)
        *(.data .data.* .gnu.linkonce.d*)
    } :text
    .bss (NOLOAD) : {
        *(.bss)
        *(COMMON)
    } :text

    /DISCARD/ : { *(.note*) *(.gnu*) *(.comment*) *(.interp) *(.eh*) }
}
