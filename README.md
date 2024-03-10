Programnyelv verseny
====================

https://gitlab.com/bztsrc/langcontest

A feladat: egy olyan rendszerprogram írása, ami nem csinál mást, mint másodpercenként eggyel növel egy számlálót a képernyőn. Elég egyszerű, nem lehet probléma bármilyen nyelven megírni ezt, igaz?

A verseny szabályait igyekeztem úgy kialakítani, hogy azok a lehető legegyenlőbb feltételeket biztosítsák, bármilyen nyelvről és fordítóról is lett légyen szó, és igazságos összehasonlítási alapot szolgáltassanak:

- architektúrának a 64 bites x86-ot választom, mert arra minden nyelvhez biztos van fordító és könnyedén tesztelhető, ráadásul tele van hozzá doksival a net
- mivel nincs oprendszer, a betöltőt biztosítom, emiatt nem kell aggódni, nektek csak egyetlen lefordított rendszerprogramot kell csinálni
- bármilyen nyelv használható, az Assembly-t leszámítva (a betöltő teszteléséhez egy Assembly-ben írt referencia implementációt biztosítok)
- inline Assembly nem, csak az adott nyelv natív utasításkészlete használható, a forrásnak hordozhatónak kell lennie (azaz hiba nélkül le kell fordulnia többféle architektúrán, akkor is, ha úgysem működne ott)
- nem használható semmi olyan kulcsszó vagy opció, ami kikapcsolja a nyelv alap funkcióit, mert az úgy már nem a csodanyelv lenne (pl Rust-ban az unsafe/unmanaged, vagy C++ alatt az -fno-exceptions/-fno-rtti nem megendegett)
- bármilyen más kulcsszó, parancssori opció használható, akár fordítóspecifikus, architektúraspecifikus is (például hívási, optimalizálási, ellenőrzési, kódgenerálási, linkelési stb., bármi más mehet, csak a nyelv alapkészletét tilos leszűkíteni)
- bármilyen fordító megengedett, ami képes az adott nyelvet lefordítani (például Go esetén gcc-go/golang, C esetén gcc/Clang stb., semmilyen megkötés nincs a fordítóra)
- bármilyen szabványos függvénykönyvtár használható, ami a nyelvvel és a fordító telepítésével együtt érkezik vagy Ti írjátok, de harmadik féltől származó, netről letöltött nem (ha a nyelvnek van bare metal változata, természetesen azt is ér használni)
- bármilyen fordítási segédprogram megengedett, olyan is, amit külön kell telepíteni vagy saját fejlesztésű (például interface bindolók, fejléc generálók, linker szkriptek, binutils, make/mk/cmake/ant/scons/meson/ninja/azanyjakinyja stb.)
- a lefordított program nem lehet nagyobb, mint amit egyetlen BIOS hívással be lehet tölteni a lemezről (65024 bájt)
- a képernyőre VGA teletype módban kell írni (ASCII karakter (0x30 - 0x39) + attribútum (0x07 fehér) párosokból álló tömb a 0xB8000 fizikai címen a Video RAM-ban)
- a pollozás nem megengedett, mert az nem lenne sem hatékony, sem energiatakarékos, sem pontos
- a program megírására 1 hónap áll rendelkezésre
- egy program többször is módosítható és többször is beadható ez idő alatt, a legutolsó fog számítani (lehet reagálni a mások által beadott pályaművekre, és lehet újabb optimalizációkkal előrukkolni)
- a nyertes az a program, ami a legkevesebb segédprogramot, kulcsszót és specifikus opciót használja az adott nyelv készletéből (magyarán ami a legkevésbé gányolt), ezen kívül pedig ami legkissebb bájtméretű, működő binárist produkálja, holtverseny esetén meg ami a kevesebb memóriát fogyasztja futás időben (vermet is beleértve)

A felsorolt limitációk a hardveres futási környezet sajátosságai (long mód, BIOS betöltés, VGA képernyő), ezek nem megkerülhetőek, muszáj alkalmazkodni hozzájuk.
Elvileg a 64 bites long mód nem tartozna ide, de ennélkül már a verseny indulása előtt nyerne a C és elvérezne az összes többi csodanyelv... :P De jófej leszek és esélyt adok nektek, így legyen hát 64 bit only.

A függvénykönyvtárakra vonatkozó megkötés azért került bele, hogy csak a nyelv maga számítson. Standard lib használható, de el is hagyható, 3rd party lib viszont tilos, mert az már nem a nyelv része.

Hogy a fordítási környezetből adódó eltéréseket is kiiktassuk, két betöltőt is biztosítok: az első ELF binárist tölt be, és SysV ABI-t használ:
```
cat boot_elf.bin programod.elf > disk.img
```
A másik pedig PE/COFF binárist és MS fastcall ABI-t (pont, mint az UEFI):
```
cat boot_pe.bin programod.exe > disk.img
```
Mindkét esetben az elkészült virtuális lemezt qemu alatt, a következő paranccsal kell tudni futtatni:
```
qemu-system-x86_64 disk.img
```

Hogy a programokba tényleg ne kelljen Assembly betét, a betöltő a bináris fejlécében megadott linkcímekre másolja a szegmenseket, kinullázza a bss-t, beállítja a vermet lefele növekvően 640K-ra, az alacsonyszintű CPU utasításokhoz pedig interfészt és wrapper függvényeket biztosít, mielőtt a belépési pontot meghívná.
Relokációt nem végez, a programot linkeljétek valaholva a 96K és 640K vagy az 1M és 2M közé, ahová jólesik, és több szegmensből is állhat akár.

Az interfészt pontosan ugyanúgy kell használni, mint UEFI esetén, csak itt más függvényeket tartalmaz. Ennek a C nyelvű definíciója:
```c
typedef struct {
  void (*load_idt)(void *buffer, uint16_t size);    /* betölti a megszakításkezelőket */
  void (*enable_interrupts)(void);                  /* engedélyezi a megszakításokat */
  void (*disable_interrupts)(void);                 /* letiltja a megszakításokat */
  void (*iretq)(int localsize);                     /* visszatér a megszakításkezelőből */
} almost_efi_system_table_but_not_quite_t;
```
A program belépési pontja egy mutatót kap paraméterül erre a struktúrára, pontosan úgy, mint UEFI-nél.
EDIT: mivel sokan sírtatok, ezért módosítás: az összes paraméternél kiírtam, hogy const, ha ez nem lett volna egyértelmű, és ezeknél a függvényeknél, és szigorúan csakis ezeknél az interfész által biztosított függvényeknél használható Rust alatt az unsafe. VAGY Az interfészt egyáltalán **nem kötelező** használni, le is implementálhatjátok ezt a négy függvényt Rust-ban, ekkor azonban nem lesz külsős függvényhívás, így ilyenkor tilos az unsafe.

Továbbá, hogy még a hardverprogramozási készségek se számítsanak, és tényleg csak a nyelveket mérjük össze, a betöltő megteszi azt a szívességet is, hogy előre felprogramozza a megszakításvezérlőt valamint a PIT-et másodpercenkénti 100 IRQ megszakításra, azonban nem kezd megszakításokat generálni, míg az enable_interrupts() függvényt meg nem hívjátok.
Hasonlóan az iretq() hívás gondoskodik a megszakításvezérlőben az IRQ nyugtázásáról is, így azzal sem kell törődnötök. A load_idt() híváshoz segítségként, 32 kivételfajta van és 16 IRQ, a kódszelektor a 32-es, a megszakításkapu attribútuma meg a 0x8E.

Itt az alkalom, hogy bizonyítsátok, a Go, Rust vagy bármelyik másik agyonhypeolt csodanyelv valóban képes lehet a C leváltására! Én állítom, hogy nem, bizonyítsátok be, hogy tévedek! Versenyre fel!
