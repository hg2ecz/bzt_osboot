RUST_BIN=$(HOME)/.cargo/bin/

PROG=timer_to_videomem
DISKIMG=disk.img

all:
	@make preinst
	@$(RUST_BIN)/cargo build --release
	@cat ../../boot_elf.bin target/x86_64-unknown-none/release/$(PROG) > $(DISKIMG)
	@ls -l | grep $(DISKIMG)

run:
	qemu-system-x86_64 $(DISKIMG)

# Install rust into $HOME/.cargo and $HOME/.rustup directories
preinst:
	@IS_RUST=$$(whereis rustc | grep '/'); \
	if [ -z "$$IS_RUST" ]; then \
	    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y; \
	fi
	@IS_BARE=$$(rustup target list | grep installed | grep x86_64-unknown-none); \
	if [ -z "$$IS_BARE)" ]; then \
	    $(RUST_BIN)/rustup target add x86_64-unknown-none; \
	fi

clean:
	@$(RUST_BIN)/cargo clean
	@rm -f $(DISKIMG)
