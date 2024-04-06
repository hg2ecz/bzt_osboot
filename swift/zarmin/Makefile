all: program.elf

program.elf: program.swift
	swiftc -clang-target x86_64-linux-elf -gnone -Osize -c -o program.o -I . program.swift
	clang --target=x86_64-elf -o program.elf -Wl,-Ttext=0x101000 -Wl,--build-id=none --static -nostdlib program.o

clean:
	rm -f program.elf program.o || true

