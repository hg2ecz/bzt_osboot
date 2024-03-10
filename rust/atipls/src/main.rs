#![feature(abi_x86_interrupt)]
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
    const fn new(offset: u64, selector: u16, attributes: u8) -> InterruptEntry {
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
    timer: usize,
    counter: usize,
}

impl Application {
    const fn new() -> Application {
        Application {
            timer: 0,
            counter: 0,
        }
    }

    fn write_number(&self, number: usize) {
        let vga = 0xb8000 as *mut u8;

        for i in 0..4usize {
            let digit = (number / 10usize.pow(3 - i as u32)) % 10;
            unsafe {
                vga.add(i * 2).write(digit as u8 + 48);
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
static mut IDT: [InterruptEntry; 48] = [InterruptEntry::new(0, 0, 0); 48];
static mut APPLICATION: Application = Application::new();


#[no_mangle]
unsafe extern "C" fn main(interface: &'static BootLoaderInterface) -> ! {
    INTERFACE = Some(interface);

    APPLICATION.write_number(0);
    IDT[32] = InterruptEntry::new(pit_interrupt_handler as u64, 32, 0x8E);

    (interface.load_idt)(addr_of_mut!(IDT) as usize, 48 * size_of::<InterruptEntry>() as u16);
    (interface.enable_interrupts)();

    loop {}
}

unsafe extern "C" fn pit_interrupt_handler() {
    APPLICATION.pit_tick();
    (INTERFACE.unwrap().iretq)(-16);
}

#[panic_handler]
fn panic(__info: &PanicInfo) -> ! {
    loop {}
}
