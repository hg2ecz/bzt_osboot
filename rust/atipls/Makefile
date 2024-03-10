all: program.elf

program.elf:
	cargo +nightly build --release
	cp target/x86_64-unknown-none/release/langcontest program.elf

clean:
	rm -rf target 2>/dev/null || true
