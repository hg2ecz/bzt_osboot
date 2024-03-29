package main

/*
typedef unsigned short uint16_t;
void load_idt(void *buffer, uint16_t size);
void enable_interrupts(void);
void disable_interrupts(void);
void iretq(int localsize);
void pitInterruptHandler();
*/
import "C"

import (
	"unsafe"
	"encoding/binary"
)

const idtEntrySize int = 16
const idtTotalSize int = 48 * idtEntrySize
var IDT [idtTotalSize]byte

const timer_limit uint32 = 10
var timer uint32 = 0
var counter uint32 = 1

func writeNumber(num uint32) {
	const vidmemAddress uintptr = 0xb8000

	for i := 3; i >= 0; i-- {
		ptr := (*byte)(unsafe.Pointer(vidmemAddress + uintptr(i * 2)))
		*ptr = (byte)((num % 10) + 48)
		num /= 10;
	}
}

//go:export pitInterruptHandler
func pitInterruptHandler() {
	timer += 1

	if timer > timer_limit {
		writeNumber(counter)
		counter += 1
		timer = 0
	}

	C.iretq(-16)
}

//go:export _start
func _start() {
	writeNumber(0)

	idt32Start := idtEntrySize * 32
	idt32Slice := IDT[idt32Start:idt32Start + idtEntrySize]

	// no packed struct support in go :(
	pit_intr_ptr := uintptr((unsafe.Pointer)(C.pitInterruptHandler))
	// base_lo, base_mid, base_high
	binary.LittleEndian.PutUint16(idt32Slice[0:2], uint16(pit_intr_ptr))
	binary.LittleEndian.PutUint16(idt32Slice[6:8], uint16(pit_intr_ptr >> 16))
	binary.LittleEndian.PutUint32(idt32Slice[8:12], uint32(pit_intr_ptr >> 32))
	// select
	binary.LittleEndian.PutUint16(idt32Slice[2:4], uint16(32))
	// flags
	idt32Slice[5] = uint8(0x8e)


	C.load_idt(unsafe.Pointer(&IDT[0]), uint16(idtTotalSize))
	C.enable_interrupts()


 	for { }
}

func main() {
}

