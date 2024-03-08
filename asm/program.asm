; formátum kiválasztása
if defined PE
format PE64 console 4.0 at 100000h
section '.text' code readable executable
else
format ELF64 executable at 100000h
segment readable executable
end if
entry _start
use64

        ;---- interfészhez makrók ----
macro struct name
{
  virtual at 0
    name name
  end virtual
}
struc INTERFACE {
        .load_idt           dq ?
        .enable_interrupts  dq ?
        .disable_interrupts dq ?
        .intret             dq ?
}
struct INTERFACE

        ;---- kód terület ----
isr_handler: ; megszakításkiszolgáló
        ; léptetjük a számlálót
        inc     word [counter]
        cmp     word [counter], 100
        jne     .return
        ; ha elérte a százat, akkor eltelt egy másodperc, léptetjük a képernyőn is
        mov     word [counter], 0
        ; első digit
        cmp     byte [0B8006h], 039h
        je      @f
        inc     byte [0B8006h]
        jmp     .return
@@:     mov     byte [0B8006h], 030h
        ; második
        cmp     byte [0B8004h], 039h
        je      @f
        inc     byte [0B8004h]
        jmp     .return
@@:     mov     byte [0B8004h], 030h
        ; harmadik
        cmp     byte [0B8002h], 039h
        je      @f
        inc     byte [0B8002h]
        jmp     .return
@@:     mov     byte [0B8002h], 030h
        ; negyedik
        cmp     byte [0B8000h], 039h
        je      @f
        inc     byte [0B8000h]
        jmp     .return
@@:     mov     rax, 0730073007300730h
        mov     qword [0B8000h], rax
        ; visszatérés a kivételkezelőből
.return:sub     rsp, 8
        xor     rcx, rcx
        xor     rdi, rdi
        mov     rbx, qword [table]
        mov     rbx, qword [rbx + INTERFACE.intret]
        call    rbx

_start: ; belépési pont
if defined PE
        mov     qword [table], rcx
        mov     rbx, rcx
else
        mov     qword [table], rdi
        mov     rbx, rdi
end if
        ; számláló kirajzolása
        mov     rax, 0730073007300730h
        mov     qword [0B8000h], rax

        ; IDT beállítása
        mov     edi, idt + 32 * 16
        mov     rax, isr_handler
        stosw
        mov     ax, 32
        stosw
        mov     ax, 8E00h
        stosw
        shr     rax, 16
        stosq

if defined PE
        mov     rcx, idt
        mov     rdx, 48 * 16
else
        mov     rdi, idt
        mov     rsi, 48 * 16
end if
        mov     rbx, qword [rbx + INTERFACE.load_idt]
        call    rbx

        ; engedélyezzük a megszakításokat
        mov     rbx, qword [table]
        mov     rbx, qword [rbx + INTERFACE.enable_interrupts]
        call    rbx

        ; nincs több dolgunk, végtelen ciklusban várakozunk
@@:     hlt
        jmp     @b

        ;---- adat terület ----
if defined PE
section '.data' data readable writable shareable
else
segment readable writable
end if
counter:rq      1
table:  rq      1
idt:    rq      48 * 2
