# See preinst section
FPC=fpc/compiler/ppc
RTL_EMBEDDED=fpc/rtl/units/x86_64-embedded

PROG=langcontest
DISKIMG=disk.img

all:
	@make preinst
	set -o errexit
	$(FPC) -Tembedded -O2 -XX -CX -al \
	    -k"-z max-page-size=0x10" \
	    -XP"x86_64-linux-gnu-" \
	    -Fu$(RTL_EMBEDDED) \
	    $(PROG).pas

	# hack - strip and get rid of the .data section,
	# which only contains the compiler signature
	strip --remove-section=.data $(PROG).elf
	cat ../../boot_elf.bin $(PROG).elf > $(DISKIMG)

preinst:
	if [ ! -e $(FPC) ]; then \
	    git clone --depth 1 https://gitlab.com/freepascal.org/fpc/source.git fpc; \
	    cd fpc && make all OS_TARGET=embedded CPU_TARGET=x86_64 SUBARCH=native; \
	fi

run:
	qemu-system-x86_64 $(DISKIMG)

clean:
	@rm -f $(PROG).elf $(PROG).s $(PROG).o $(DISKIMG)
	@rm -rf fpc
