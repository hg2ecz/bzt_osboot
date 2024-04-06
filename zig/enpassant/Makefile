all: program.elf

program.elf: program.zig
	zig build-exe -O ReleaseSmall -mcmodel small -fstrip -target x86_64-freestanding-none --image-base 0x100000 --name program.elf -fno-stack-protector -fno-stack-check  -fomit-frame-pointer -fno-unwind-tables -mno-red-zone -fno-function-sections -z max-page-size=0x10 program.zig
	rm program.elf.o

program.exe: program.zig
	zig build-exe -O ReleaseSmall -mcmodel small -fstrip -target x86_64-windows --image-base 0x100000 -fno-stack-protector -fno-stack-check  -fomit-frame-pointer -fno-unwind-tables -mno-red-zone -fno-function-sections --entry _start -z max-page-size=0x10 program.zig
	rm program.exe.obj

clean:
	rm program.elf 2>/dev/null || true
	rm program.exe 2>/dev/null || true
	rm disk.img 2>/dev/null || true
	rm disk-pe.img 2>/dev/null || true

run: program.elf
	cat ../../boot_elf.bin program.elf > disk.img; qemu-system-x86_64 disk.img

runwin: program.exe
	cat ../../boot_pe.bin program.exe > disk-pe.img; qemu-system-x86_64 disk-pe.img
