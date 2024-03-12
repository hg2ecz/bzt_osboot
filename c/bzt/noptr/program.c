#include <stdint.h>

/* interfész */
void load_idt(void *buffer, uint16_t size);    /* betölti a megszakításkezelőket */
void enable_interrupts(void);                  /* engedélyezi a megszakításokat */
void disable_interrupts(void);                 /* letiltja a megszakításokat */
void iretq(int localsize);                     /* visszatér a megszakításkezelőből */

/* adat terület */
uint64_t counter = 0, idt[48 * 2] = { 0 };
uint8_t vga[4096];

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
                    else vga[0] = vga[2] = vga[4] = vga[6] = '0';
                }
            }
        }
    }
    /* visszatérés a kivételkezelőből */
    iretq(0);
}

/* belépési pont */
void _start()
{
    /* számláló kirajzolása */
    vga[0] = vga[2] = vga[4] = vga[6] = '0';
    vga[1] = vga[3] = vga[5] = vga[7] = 7;

    /* IDT beállítása */
    idt[32 * 2] = (((uintptr_t)isr_handler & ~0xffff) << 32) | 0x8E0000200000UL | ((uintptr_t)isr_handler & 0xffff);
    load_idt(idt, 48 * 16);

    /* engedélyezzük a megszakításokat */
    enable_interrupts();

    /* nincs több dolgunk, végtelen ciklusban várakozunk */
    while(1);
}
