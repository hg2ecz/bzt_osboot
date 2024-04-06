#![no_std]
#![no_main]

use core::{mem::size_of, panic::PanicInfo, ptr::addr_of_mut};

#[repr(C)]
struct BootLoaderInterface {
    load_idt: fn(usize, u16),
    enable_interrupts: fn(),
    disable_interrupts: fn(),
    iretq: fn(i32),
}

#[repr(C)]
#[derive(Clone, Copy)]
struct InterruptEntry {
    offset_low: u16,
    selector: u16,
    isr: u8,
    attributes: u8,
    offset_mid: u16,
    offset_high: u32,
    zero: u32,
}

impl InterruptEntry {
    const fn new(offset: usize, selector: u16, attributes: u8) -> InterruptEntry {
        InterruptEntry {
            offset_low: offset as u16,
            selector,
            isr: 0,
            attributes,
            offset_mid: (offset >> 16) as u16,
            offset_high: (offset >> 32) as u32,
            zero: 0,
        }
    }
}

struct Application {
    timer: u32,
    counter: u32,
}

impl Application {
    const fn new() -> Application {
        Application {
            timer: 0,
            counter: 0,
        }
    }

    fn write_number(&self, number: u32) {
        let vga = 0xb8000 as *mut u8;

        for i in 0..4 {
            let digit = ((number / 10_u32.pow(3 - i as u32)) % 10) as u8 + b'0';
            unsafe {
                vga.add(2 * i).write(digit);
            }
        }
    }

    fn pit_tick(&mut self) {
        self.timer += 1;
        if self.timer == 100 {
            self.timer = 0;
            self.counter += 1;
            self.write_number(self.counter);
        }
    }
}

static mut INTERFACE: Option<&'static BootLoaderInterface> = None;
static mut APPLICATION: Application = Application::new();

#[no_mangle]
extern "C" fn main(interface: &'static BootLoaderInterface) -> ! {
    unsafe {
        INTERFACE = Some(interface);
        APPLICATION.write_number(0);
    }
    let mut idt = [InterruptEntry::new(0, 0, 0); 48];
    idt[32] = InterruptEntry::new(pit_interrupt_handler as usize, 32, 0x8E);

    #[rustfmt::skip]
    (interface.load_idt)(addr_of_mut!(idt) as usize, 48 * size_of::<InterruptEntry>() as u16);
    (interface.enable_interrupts)();
    #[allow(clippy::empty_loop)]
    loop {}
}

extern "C" fn pit_interrupt_handler() {
    unsafe { APPLICATION.pit_tick() };

    if let Some(interface) = unsafe { INTERFACE } {
        (interface.iretq)(-16);
    }
}

#[panic_handler]
fn panic(__info: &PanicInfo) -> ! {
    #[allow(clippy::empty_loop)]
    loop {}
}
