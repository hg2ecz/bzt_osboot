all: program.elf

CFLAGS=-s -static -fno-strict-aliasing -ffreestanding -fno-stack-protector -fno-stack-check -fomit-frame-pointer -fno-asynchronous-unwind-tables \
	-mno-red-zone -nostdlib -Wall -Wextra -Werror
LDFLAGS=-T link.ld

program.elf: program.c
	#clang --target=x86_64-elf $(CFLAGS) $(LDFLAGS) program.c -o program.elf
	gcc $(CFLAGS) $(LDFLAGS) program.c -o program.elf

clean:
	rm program.elf 2>/dev/null || true
