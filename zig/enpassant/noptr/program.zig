extern fn load_idt(idt_address: *[48 * 2]u64, idt_size_in_bytes: u16) callconv(.C) void;
extern fn enable_interrupts() callconv(.C) void;
extern fn disable_interrupts() callconv(.C) void;
extern fn iretq(localsize: i32) callconv(.C) void;
extern var vga: [4096]u8;

var counter: u8 = 0;

pub export fn isrHandler() callconv(.C) void {
    counter += 1;
    if (counter == 100) {
        counter = 0;
        for (0..4) |i| {
            if (vga[(3 - i) * 2] != '9') {
                vga[(3 - i) * 2] += 1;
                break;
            }
            vga[(3 - i) * 2] = '0';
        }
    }
    iretq(-16);
}

pub export fn _start(_: *u8) void {
    for (0..4) |i| {
        vga[i * 2] = '0';
        vga[i * 2 + 1] = 7;
    }

    var idt: [48 * 2]u64 = undefined;
    idt[32 * 2] = @shlExact(@intFromPtr(&isrHandler) & 0xffffffffffff0000, 32) | 0x8E0000200000 | (@intFromPtr(&isrHandler) & 0xffff);

    load_idt(&idt, 48 * 16);

    enable_interrupts();

    while (true) {}
}
