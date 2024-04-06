type
  VGA = ptr array[0..4000, char]

  AlmostEfiSystemTableButNotQuite* = object
    load_idt*: proc(buffer: pointer, size: uint16): void {.cdecl.}
    enable_interrupts*: proc(): void {.cdecl.}
    disable_interrupts*: proc(): void {.cdecl.}
    iretq*: proc(localSize: int): void {.cdecl.}

  IdtEntry* {.packed.} = object
    base_lo*: uint16
    sel*: uint16
    ist*: uint8
    flags*: uint8
    base_mid*: uint16
    base_high*: uint32
    dummy*: uint32

var
  vga: VGA = cast[VGA](0xb8000'u64)
  efiif: ptr AlmostEfiSystemTableButNotQuite
  counter: uint32 = 0
  timer: uint32 = 0

const
  timerTarget = 100

proc writeNumber(num: uint32) =
  var lnum = num
  for i in countdown(3, 0):
    vga[][i*2] = char((lnum mod 10) + 48)
    lnum = lnum div 10

proc interrupt_handler() {.exportc, cdecl.} =
  if timer > timerTarget:
    timer = 0
    counter += 1
    writeNumber(counter)

  timer += 1
  efiif.iretq(-16)

proc Start(efiifIn: ptr AlmostEfiSystemTableButNotQuite) {.exportc: "_start", cdecl.} =
  efiif = efiifIn

  writeNumber(0)

  var idtTable: array[48, IdtEntry]

  var interrupt_handler_ptr = cast[uint64](cast[pointer](interrupt_handler))
  var idte32 = addr idtTable[32]
  idte32.base_lo = uint16(interrupt_handler_ptr)
  idte32.base_mid = uint16(interrupt_handler_ptr shr 16)
  idte32.base_high = uint32(interrupt_handler_ptr shr 32)
  idte32.sel = 32
  idte32.flags = 0x8e

  efiif.load_idt(cast[pointer](addr idtTable), cast[uint16](sizeof(idtTable)))
  efiif.enable_interrupts()

  while true:
    discard

