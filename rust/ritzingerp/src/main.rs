#![no_std]
#![no_main]

use core::{mem::size_of_val, panic::PanicInfo, ptr::write_volatile, usize};
use x86::halt;

#[repr(C)]
#[derive(Copy, Clone)]
struct InterruptDescriptor64 {
    base_low: u16,
    selector: u16,
    ist: u8,
    flags: u8,
    base_mid: u16,
    base_high: u32,
    reserved: u32,
}

#[repr(C)]
struct InterruptFunctions {
    load_idt: fn(idt_address: *const InterruptDescriptor64, size_in_bytes: usize),
    enable_interrupts: fn(),
    disable_interrupts: fn(),
    intret: fn(localsize: i32) -> !,
}

static mut STORED_INTERRUPT_FUNCTIONS: *const InterruptFunctions = 0 as *const InterruptFunctions;

static mut COUNTER: u32 = 0;

fn update_display(counter: u32) {
    if counter % 100 == 0 {
        const VIDEO_BUFFER: *mut u8 = 0xB8000 as *mut u8;
        let mut seconds: u32 = counter / 100;
        for i in (0..4).rev() {
            let digit: u8 = (seconds % 10) as u8 + b'0';
            unsafe { write_volatile(VIDEO_BUFFER.add(i * 2), digit) };
            seconds /= 10;
        }
    }
}

extern "C" fn timer_interrupt_handler() -> ! {
    unsafe {
        COUNTER += 1;
        update_display(COUNTER);
        ((*STORED_INTERRUPT_FUNCTIONS).intret)(0);
    };
}

#[no_mangle]
extern "C" fn _start(interrupt_functions: &InterruptFunctions) -> ! {
    unsafe { STORED_INTERRUPT_FUNCTIONS = interrupt_functions };

    update_display(0);

    let timer_address = timer_interrupt_handler as usize;
    let mut idt: [InterruptDescriptor64; 48] = [InterruptDescriptor64 {
        base_low: 0,
        selector: 0,
        ist: 0,
        flags: 0,
        base_mid: 0,
        base_high: 0,
        reserved: 0,
    }; 48];
    let timer_interrupt: &mut InterruptDescriptor64 = &mut idt[32];
    timer_interrupt.base_low = (timer_address & 0xFFFF) as u16;
    timer_interrupt.base_mid = ((timer_address >> 16) & 0xFFFF) as u16;
    timer_interrupt.base_high = ((timer_address >> 32) & 0xFFFFFFFF) as u32;
    timer_interrupt.selector = 32;
    timer_interrupt.flags = 0x8E;
    timer_interrupt.ist = 0;
    timer_interrupt.reserved = 0;

    (interrupt_functions.load_idt)(idt.as_ptr(), size_of_val(&idt));
    (interrupt_functions.enable_interrupts)();

    loop {
        unsafe { halt() };
    }
}

#[panic_handler]
fn panic(_panic_info: &PanicInfo) -> ! {
    loop {}
}
