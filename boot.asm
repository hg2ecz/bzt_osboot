            ORG         07C00h
            USE16

            jmp         short @f                ; kötelező ugrás (mágikus bájtok)
            nop
            ;---- környezet beállítása ----
@@:         cli
            cld
            mov         al, 0FFh                ; PIC kikapcsolása
            out         021h, al
            out         0A1h, al
            in          al, 70h                 ; NMI kikapcsolása
            or          al, 80h
            out         70h, al
            xor         ax, ax
            mov         ss, ax
            mov         ds, ax
            mov         es, ax
            mov         sp, 07C00h
            mov         ax, 2401h               ; A20 engedélyezése
            int         15h
            mov         ax, 3                   ; képernyő törlése
            int         10h
            ;---- második blokk beolvasása ----
            mov         si, 500h
            mov         di, si
            mov         byte [di - 1], dl
            xor         ah, ah
            mov         al, 16                  ; size
            stosw
            mov         al, 1                   ; count
            stosw
            mov         ax, 7E00h               ; addr0, 7E00h-ra töltünk be
            stosw
            xor         ax, ax                  ; addr1
            stosw
            inc         ax                      ; sect0
            stosw
            xor         ax, ax                  ; sect1
            stosw
            stosw                               ; sect2
            stosw                               ; sect3
            mov         ah, 42h
            push        si
            int         13h
            pop         si
            ;---- a lefordított program beolvasása ----
            mov         byte [8000h], 0
            mov         byte [si+2], 127        ; maximális szektorszám
            mov         byte [si+5], 80h        ; 8000h-ra töltünk be
            inc         byte [si+8]             ; LBA 2-től
            mov         ah, 42h
            int         13h
            ;---- protmode bekapcsolása ----
            mov         si, GDT_value
            mov         di, 510h
            mov         cx, word[si]
            repnz       movsb
            lgdt        [510h]
            mov         eax, cr0
            or          al, 1
            mov         cr0, eax
            jmp         16:@f
            USE32
@@:         mov         ax, 24
            mov         ds, ax
            mov         es, ax
            ;---- longmode bekapcsolása ----
            xor         eax, eax
            mov         ah, 010h
            mov         cr3, eax
            ; 2M leképezése
            mov         edi, eax                ; PML4
            mov         dword [edi], 02003h     ; mutató a 2M PDPE-re
            add         edi, eax                ; 2M PDPE
            mov         dword [edi], 03003h
            add         edi, eax                ; 2M PDE
            mov         ax, 0083h
            stosd
            xor         eax, eax
            stosd
            mov         al, 0E0h                ; PAE, MCE, PGE beállítása; minden mást törlünk
            mov         cr4, eax
            mov         ecx, 0C0000080h         ; EFER MSR
            rdmsr
            bts         eax, 8                  ; longmode lapozás engedélyezése
            wrmsr
            mov         eax, cr0
            xor         cl, cl
            or          eax, ecx
            btc         eax, 16                 ; WP törlés
            mov         cr0, eax                ; lapozás engedélyezése gyorsítótár nélkül (PE, CD beállítása)
            lgdt        [510h]                  ; 80 bites cím (16+64)
            jmp         32:@f
            USE64
@@:         xor         rax, rax                ; longmode szegmensek betöltése
            mov         ax, 40
            mov         ds, ax
            mov         es, ax
            mov         ss, ax
if defined PE
            ;---- PE / COFF formátum értelmezése ----
            mov         ebx, 8000h              ; betöltés címe
            cmp         word [ebx], 5A4Dh       ; MZ ellenőrzés
            jne         .die
            mov         r8d, ebx
            add         ebx, dword [ebx + 0x3c] ; COFF fejléc
            cmp         word [ebx], 4550h       ; PE ellenőrzés
            jne         .die
            mov         dl, byte [ebx + 6]      ; szekciók száma
            mov         r9d, dword [ebx + 0x28] ; belépési pont
            mov         ebp, dword [ebx + 0x30] ; betöltési cím
            add         r9d, ebp
            add         bx, word [ebx + 0x14]   ; fejlécméret hozzáadása
            add         bx, 24                  ; ebx most a szekciótáblára mutat
@@:         mov         edi, dword [ebx + 12]   ; szekció másolása a PE-ből VA-ba
            add         edi, ebp                ; cél: betöltési cím + reloc offszet
            mov         ecx, dword [ebx + 16]   ; nyers adatmennyiség
            mov         esi, dword [ebx + 20]
            add         esi, r8d                ; forrás: nyers adat címe + betöltési cím
            repnz       movsb
            add         ebx, 40                 ; következő szekció
            dec         dl
            jnz         @b
            call        pit_init                ; PIT felkonfigurálása
            mov         rcx, table              ; interfésztábla
else
            ;---- ELF formátum értelmezése ----
            mov         ebx, 8000h              ; betöltés címe
            cmp         dword [ebx], 464C457Fh  ; ELF ellenőrzés
            jne         .die
            cmp         dword [ebx+16], 3E0002h ; x86_64 executable
            jne         .die
            mov         r9d, dword [ebx + 0x18] ; belépési pont
            xor         r10, r10
            mov         r10w, word [ebx + 0x36] ; e_phentsize
            mov         dx, word [ebx + 0x38]   ; e_phentnum
            mov         ebp, ebx
            add         ebx, dword [ebx + 0x20] ; e_phoffs
.nextph:    cmp         byte [ebx], 1           ; p_type == PT_LOAD
            jne         @f
            mov         esi, dword [ebx + 8]    ; p_offset
            add         esi, ebp
            mov         edi, dword [ebx + 16]   ; p_vaddr
            mov         ecx, dword [ebx + 32]   ; p_filesz
            cmp         edi, 018000h
            jb          @f
            cmp         edi, 0200000h
            jae         @f
            or          ecx, ecx
            jz          .nomemcpy
            repnz       movsb                   ; memcpy(p_vaddr, load + p_offset, p_filesz)
.nomemcpy:  mov         ecx, dword [ebx + 40]   ; p_memsz - p_filesz
            sub         ecx, dword [ebx + 32]
            or          ecx, ecx
            jz          @f
            xor         al, al                  ; memset(p_vaddr + p_filesz, 0, p_memsz - p_filesz)
            repnz       stosb
@@:         add         ebx, r10d
            dec         dx
            jnz         .nextph
            call        pit_init                ; PIT felkonfigurálása
            mov         rdi, table              ; interfésztábla
end if
            xor         rsp, rsp
            mov         esp, 9A000h             ; verem beállítása
            mov         rbp, rsp
            jmp         r9                      ; relokált belépési pontra ugrás
            ;---- hibajelentés funkció ----
.die:       mov         esi, .err
            mov         edi, 0B8000h
            mov         ah, 04fh
@@:         lodsb
            or          al, al
            jz          @f
            stosw
            jmp         @b
@@:         hlt
            ;---- adat terület ----
.err:
if defined PE
            db          "PE/COFF"
else
            db          "ELF"
end if
            db          " HIBA", 0
GDT_value:  dw          GDT_value.end-GDT_value ; value / null deszkriptor
            dd          510h
            dw          0
            dd          0000FFFFh,00009800h     ;  8 - real mode cs (valós mód)
            dd          0000FFFFh,00CF9A00h     ; 16 - prot mode cs (védett mód)
            dd          0000FFFFh,008F9200h     ; 24 - prot mode ds
            dd          0000FFFFh,00AF9A00h     ; 32 - long mode cs (hosszú mód)
            dd          0000FFFFh,00CF9200h     ; 40 - long mode ds
.end:       db          01BEh-($-$$) dup 0
            ;---- régimódú partíciós táblának fenntartott hely ----
            db          01FEh-($-$$) dup 0
            db          55h, 0AAh               ; kötelező mágikus bájtok
            ;---- interfész ----
table:      dq          .load_idt
            dq          .enable_interrupts
            dq          .disable_interrupts
            dq          .intret
.load_idt:                                      ; IDT betöltése
if defined PE
            dec         dx
            mov         word[580h], dx
            mov         qword[582h], rcx
else
            dec         si
            mov         word[580h], si
            mov         qword[582h], rdi
end if
            lidt        [580h]
            ret
.enable_interrupts:                             ; megszakítások engedélyezése
            sti
            ret
.disable_interrupts:                            ; megszakítások letiltása
            cli
            ret
.intret:    add         esp, 16                 ; IRQ nyugta és visszatérés megszakításból
if defined PE
            add         esp, ecx
else
            add         esp, edi
end if
            mov         al, 020h
            out         020h, al
            iretq
pit_init:   mov         al, 11h                 ; PIC átprogramozása
            out         020h, al                ; kivételek ISR 0 - ISR 31
            out         0A0h, al
            mov         al, 20h                 ; IRQ-k ISR 32 - ISR 47
            out         021h, al
            mov         al, 28h
            out         0A1h, al
            mov         al, 4h
            out         021h, al
            mov         al, 2h
            out         0A1h, al
            mov         al, 1h
            out         021h, al
            out         0A1h, al
            mov         al, 036h                ; PIT átállítása 100Hz-re
            out         043h, al
            mov         ax, 11931
            out         040h, al
            mov         al, ah
            out         040h, al
            mov         al, 0FEh                ; IRQ 0 (ISR 32) engedélyezése
            out         021h, al
            ret
            db          0400h-($-$$) dup 0
