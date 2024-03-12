#include <stdint.h>
#include <intrin.h>

struct interrupt_descriptor_64_t {
    uint16_t base_low;
    uint16_t selector;
    uint8_t  ist;
    uint8_t  flags;
    uint16_t base_mid;
    uint32_t base_high;
    uint32_t reserved;
};

struct interrupt_functions_t {
    void (*load_idt)(const interrupt_descriptor_64_t *idt_address, uint32_t idt_size_in_bytes);
    void (*enable_interrupts)();
    void (*disable_interrupts)();
    void (*intret)(int32_t localsize);
};

const interrupt_functions_t *stored_interrupt_functions;
interrupt_descriptor_64_t interrupt_descriptor_table[48];
int counter = 0;

void update_video_memory()
{
    if (counter % 100 == 0)
    {
        volatile char* video_buffer = (volatile char*)0xB8000;
        int seconds = counter / 100;
        for (int i = 3; i >= 0; i--)
        {
            video_buffer[i * 2] = seconds % 10 + '0';
            seconds /= 10;
        }
    }
}

void timer_interrupt_handler()
{
    ++counter;
    update_video_memory();
    stored_interrupt_functions->intret(-16); // -16 because of tail call optimization, 'jmp' is generated instead of 'call'
}

void raw_main(const interrupt_functions_t *interrupt_functions)
{
    stored_interrupt_functions = interrupt_functions;
    update_video_memory();

    uint64_t timer_address = (uint64_t)timer_interrupt_handler;

    interrupt_descriptor_64_t* timer_interrupt_descriptor = &interrupt_descriptor_table[32];
    timer_interrupt_descriptor->base_low = timer_address & 0xFFFF;
    timer_interrupt_descriptor->base_mid = (timer_address >> 16) & 0xFFFF;
    timer_interrupt_descriptor->base_high = (timer_address >> 32) & 0xFFFFFFFF;
    timer_interrupt_descriptor->selector = 32;
    timer_interrupt_descriptor->flags = 0x8E;
    timer_interrupt_descriptor->ist = 0;
    timer_interrupt_descriptor->reserved = 0;

    interrupt_functions->load_idt(interrupt_descriptor_table, sizeof interrupt_descriptor_table);
    interrupt_functions->enable_interrupts();

    while (true)
    {
        __halt();
    }
}
