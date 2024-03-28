all: program.elf

program.elf: program.go
	tinygo build -no-debug -opt=z -target=bootelf.json -x -o program.elf

clean:
	rm -f program.elf || true


