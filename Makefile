all: boot_elf.bin boot_pe.bin

boot_elf.bin: boot.asm
	fasm boot.asm boot_elf.bin

boot_pe.bin: boot.asm
	fasm -d PE=1 boot.asm boot_pe.bin

run: boot_elf.bin boot_pe.bin
ifneq ($(wildcard program.elf),)
	cat boot_elf.bin program.elf > disk.img
else
ifneq ($(wildcard program.exe),)
	cat boot_pe.bin program.exe > disk.img
else
	@echo "Másold ide a program.elf vagy program.exe fájlodat a teszteléshez!"
	@false
endif
endif
	qemu-system-x86_64 disk.img

clean:
	rm boot_*.bin *.img program.elf program.exe 2>/dev/null || true
