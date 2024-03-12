all: program.exe

CFLAGS=-fno-strict-aliasing -ffreestanding -fno-stack-protector -fno-stack-check -fomit-frame-pointer -fno-asynchronous-unwind-tables \
	-mno-red-zone -nostdlib -Wall -Wextra -Werror

program.exe: program.c
	clang --target=x86_64-pc-win32-coff $(CFLAGS) -c program.c -o program.o
	lld -flavor link -subsystem:console -Brepro -nodefaultlib -dynamicbase -base:0x100000 -entry:_start program.o -out:program.exe
	@rm program.o program.lib 2>/dev/null || true

clean:
	rm program.exe 2>/dev/null || true
