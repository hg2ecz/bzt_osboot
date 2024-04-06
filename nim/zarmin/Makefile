all: program.elf

program.elf: program.nim
	nim compile -d:release -f --opt:size --app:console \
		-o:program.elf --noMain:on --os:standalone --cpu:amd64 --debuginfo:off --embedsrc:off --mm:none \
		--passL:'-Wl,-Ttext=0x101000 -Wl,--build-id=none -static -nostdlib -m64 -march=x86-64' \
		program.nim

clean:
	rm -f program.elf || true

