import efistuff

// Very ugly hack was implemented to define C compatible empty memset function
// For some reason (I haven't dug into the swift core's source code) the withUnsafeMutablePointer requires (linking error with -nostdlib) and calls a memset (to zero out memory), but fortunately works if the memset is a noop
// I was unable to implement a C compatible swift prototype and functionality for memset
@_cdecl("memset")
public func memset() {}


// Very ugly hack again
// Swift global variables are thread-safe, because of this reading/writing global variables requires (link time error) synchronization functions from the Swift Core library (including this lib leads to an immediate overflow on the ~64k limit), so I'm adding the required function as a no-op.
@_cdecl("swift_beginAccess")
public func swift_beginAccess(pointer: UnsafeMutableRawPointer, buffer: UnsafeMutableRawPointer, flags: UInt, pc: UnsafeMutableRawPointer) {}


var timer: UInt32 = 0
var counter: UInt32 = 0
var efiifPtr: UnsafeMutablePointer<almost_efi_system_table_but_not_quite_t>?


func writeNumber(_ num: UInt32) {
    let videoMemory = UnsafeMutablePointer<UInt8>(bitPattern: UInt(0xB8000))!

    var _num = num
    var i = 3
    while i >= 0 {
        (videoMemory + i*2).pointee = UInt8(_num % 10) + 48
        _num /= 10
        i -= 1
    }
}


@_cdecl("interrupt_handler")
public func interrupt_handler() {
    timer += 1
    if timer >= 100 {
        timer = 0
        counter += 1
        writeNumber(counter)
    }

    efiifPtr!.pointee.iretq(0)
}


@_cdecl("_start")
public func _start(efiifPtrAddr: UInt64) {
    efiifPtr = UnsafeMutablePointer<almost_efi_system_table_but_not_quite_t>(bitPattern: UInt(efiifPtrAddr))!
    let efiif = efiifPtr!.pointee

    writeNumber(0)

    // this "hack" is required because I need a c-convention pointer to the exported interrupt_handler function
    var cc: (@convention(c) () -> Void)?
    cc = { interrupt_handler() }
    let offset: UInt64 = UInt64(bitPattern:Int64(Int(bitPattern: unsafeBitCast(cc, to: UnsafeMutableRawPointer.self))))


    var idte32 = efistuff.idt_entry()
    idte32.base_lo = UInt16(truncatingIfNeeded: offset)
    idte32.base_mid = UInt16(truncatingIfNeeded: offset >> 16)
    idte32.base_high = UInt32(truncatingIfNeeded: offset >> 32)
    idte32.sel = 32
    idte32.flags = 0x8e

    // This was the only way to allocate an array (actually, a tuple) of items on the stack without relying on many Swift Core Library functions, which instantly exceed the ~64K limit.
    var idt_table = (
        efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(),
        efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(),
        efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(),
        efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(),
        idte32, efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(),
        efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry(), efistuff.idt_entry()
    )

    withUnsafeMutablePointer(to: &idt_table) { idt_ptr in
        efiif.load_idt(idt_ptr, 48 * 16)
    }

    efiif.enable_interrupts()

    while (true) {}
}

