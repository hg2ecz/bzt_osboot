#include <stdint.h>

/* interfész */
typedef struct {
  void (*load_idt)(void *buffer, uint16_t size);    /* betölti a megszakításkezelőket */
  void (*enable_interrupts)(void);                  /* engedélyezi a megszakításokat */
  void (*disable_interrupts)(void);                 /* letiltja a megszakításokat */
  void (*iretq)(int localsize);                     /* visszatér a megszakításkezelőből */
} almost_efi_system_table_but_not_quite_t;

/* adat terület */
almost_efi_system_table_but_not_quite_t *INTERFACE;
uint64_t counter = 0, idt[48 * 2] = { 0 };
uint8_t *vga = (uint8_t*)0xB8000;

/* megszakításkiszolgáló */
void isr_handler(void)
{
    /* léptetjük a számlálót */
    if(++counter == 100) {
        /* ha elérte a százat, akkor eltelt egy másodperc, léptetjük a képernyőn is */
        counter = 0;
        if(vga[6] != '9') vga[6]++; else { vga[6] = '0';            /* első digit */
            if(vga[4] != '9') vga[4]++; else { vga[4] = '0';        /* második digit */
                if(vga[2] != '9') vga[2]++; else { vga[2] = '0';    /* harmadik digit */
                    if(vga[0] != '9') vga[0]++;                     /* negyedik digit */
                    else *((uint64_t*)0xB8000) = 0x0730073007300730UL;
                }
            }
        }
    }
    /* visszatérés a kivételkezelőből */
    INTERFACE->iretq(0);
}

/* belépési pont */
void _start(almost_efi_system_table_but_not_quite_t *table)
{
    INTERFACE = table;

    /* számláló kirajzolása */
    *((uint64_t*)0xB8000) = 0x0730073007300730UL;

    /* IDT beállítása */
    idt[32 * 2] = (((uintptr_t)isr_handler & ~0xffff) << 32) | 0x8E0000200000UL | ((uintptr_t)isr_handler & 0xffff);
    INTERFACE->load_idt(idt, 48 * 16);

    /* engedélyezzük a megszakításokat */
    INTERFACE->enable_interrupts();

    /* nincs több dolgunk, végtelen ciklusban várakozunk */
    while(1);
}
