all: program.elf

program.elf: program.zig
	zig build-exe -O ReleaseSmall -mcmodel small -fstrip -target x86_64-freestanding-none --image-base 0x100000 --name program.elf -fno-stack-protector -fno-stack-check  -fomit-frame-pointer -fno-unwind-tables -mno-red-zone -fno-function-sections -z max-page-size=0x10 -T link.ld program.zig
	rm program.elf.o
clean:
	rm program.elf 2>/dev/null || true
	rm disk.img 2>/dev/null || true

run: program.elf
	cat ../../../boot_elf.bin program.elf > disk.img; qemu-system-x86_64 disk.img
