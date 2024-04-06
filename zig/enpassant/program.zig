const interrupt_descriptor_64_t = packed struct {
    base_low: u16,
    selector: u16,
    ist: u8,
    flags: u8,
    base_mid: u16,
    base_high: u32,
    reserved: u32,
};

const idtType = [48]interrupt_descriptor_64_t;
const interrupt_functions_t = packed struct {
    load_idt: *const fn (idt_address: *const idtType, idt_size_in_bytes: u16) callconv(.C) void,
    enable_interrupts: *const fn () callconv(.C) void,
    disable_interrupts: *const fn () callconv(.C) void,
    iretq: *const fn (localsize: i32) callconv(.C) void,
};

var systab: *const interrupt_functions_t = undefined;
var counter: u8 = 0;

pub export fn isrHandler() callconv(.C) void {
    var vga: [*]volatile u8 = @ptrFromInt(0xB8000);
    counter += 1;
    if (counter == 100) {
        counter = 0;
        if (vga[6] != '9') vga[6] += 1 else {
            vga[6] = '0';
            if (vga[4] != '9') vga[4] += 1 else {
                vga[4] = '0';
                if (vga[2] != '9') vga[2] += 1 else {
                    vga[2] = '0';
                    if (vga[0] != '9') vga[0] += 1;
                }
            }
        }
    }
    systab.iretq(-16);
}

pub export fn _start(st: *const interrupt_functions_t) void {
    systab = st;

    const sizeOfIdt = @sizeOf(idtType);
    var idt: idtType = undefined;
    var vga: [*]volatile u64 = @ptrFromInt(0xB8000);
    vga[0] = 0x0730073007300730;

    const isrh = packed union {
        addr: packed struct {
            low: u16,
            mid: u16,
            high: u32,
        },
        ptr: usize,
    }{ .ptr = @intFromPtr(&isrHandler) };

    idt[32] = interrupt_descriptor_64_t{
        .base_low = isrh.addr.low,
        .selector = 32,
        .ist = 0,
        .flags = 0x8e,
        .base_mid = isrh.addr.mid,
        .base_high = isrh.addr.high,
        .reserved = 0,
    };

    systab.load_idt(&idt, sizeOfIdt);

    systab.enable_interrupts();

    while (true) {}
}

pub fn main() void {}
