all: program.elf program.exe

program.elf: program.asm
	fasm program.asm program.elf

program.exe: program.asm
	fasm -d PE=1 program.asm program.exe

clean:
	rm program.elf program.exe 2>/dev/null || true
