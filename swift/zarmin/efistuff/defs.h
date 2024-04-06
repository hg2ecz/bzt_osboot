#include <stdint.h>

typedef struct {
  void (*load_idt)(void *buffer, uint16_t size);
  void (*enable_interrupts)(void);
  void (*disable_interrupts)(void);
  void (*iretq)(int localsize);
} almost_efi_system_table_but_not_quite_t;

typedef struct idt_entry
{
  uint16_t base_lo;
  uint16_t sel;        /* Our kernel segment goes here! */
  uint8_t  ist;         /* 3 bits IST, above only 0s     */
  uint8_t  flags;       /* Set using the above table!    */
  uint16_t base_mid;
  uint32_t base_high;
  uint32_t dummy;
} __attribute__((packed)) idt_entry;

