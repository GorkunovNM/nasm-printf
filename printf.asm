;================================CONSTS================================
FIRST_SPEC_TABLE equ 'b'                ; first spec in jump table
;======================================================================

section .data
        form_str DB "I %s %x %d%%%c%b I %s %x %d%%%c%b", 0h   ; format string
        str_t DB "love", 0h                                   ; string to print

        alpha DB "0123456789abcdef"     ; alphabet

        jmp_table:
        ;DQ jprnt_prcnt                 ; % spec
        ;TIMES 'b'-'%'-1 DQ next        ; undef spec
        DQ jprnt_b, jprnt_c, jprnt_d    ; b, c, d specs
        TIMES 'o'-'d'-1 DQ next         ; undef spec
        DQ jprnt_o                      ; o spec
        TIMES 's'-'o'-1 DQ next         ; undef spec
        DQ jprnt_s                      ; s spec
        TIMES 'x'-'s'-1 DQ next         ; undef spec
        DQ jprnt_x                      ; x spec

section .bss
        num_buf RESB 20h                ; 4 bytes (32 bits)
 
section .text
        global _start
 
_start:
        push 127d
        push '!'
        push 100d
        push 3802d
        push str_t
        push 127d
        push '!'
        push 100d
        push 3802d
        push str_t
        push form_str

        call printf                     ; printf("I %s %x %d%%%c%b", "love", 3802, 100, '!', 127)

        mov rax, 60d
        xor rdi, rdi
        syscall                         ; exit(0);

;======================================================================
;printf - procedure which is analog of printf from stdio.h
;
;in:    rbx     - format string
;       stack   - format string arguments
;
;out:   rax = 1
;       rbx = \0 which is the end of format string
;       rcx = rubbish
;       rdx = 1
;       rsi = rubbish
;       rdi = 1
;       r8  = rubbish
;       r9  = rubbish
;       r10 = rubbish
;       r11 = rubbish
;       r12 = rubbish
;
;======================================================================

printf:
        push rbp
        mov rbp, rsp
        mov r12, 10h
        mov rbx, [rbp + r12]

        mov rax, 1h
        mov rdi, 1h
        mov rdx, 1h                     ; putchar(*(???))

printf_start:
        cmp BYTE [rbx], 0h
        je return                       ; if (*char_now == '\0') return;
        cmp BYTE [rbx], '%'
        jne jprnt_char                  ; if (*char_now != '%') putchar(char_now); else {
        
        inc rbx                         ; char_now++

        cmp BYTE [rbx], 'x'             ; if (*char_now > 'x') goto next
        ja next
        xor rcx, rcx
        mov cl, [rbx]

        cmp BYTE cl, '%'
        je jprnt_prcnt

        jmp [jmp_table + rcx * 8 - FIRST_SPEC_TABLE * 8]  ; printf cases

next:
        inc rbx                         ; char_now++

        jmp printf_start                ; goto printf_start
return:
        pop rbp
        ret

jprnt_char:
        mov rsi, rbx
        syscall                         ; putchar(*char_now)
        inc rbx                         ; char_now++
        jmp printf_start                ; goto printf_start

jprnt_d:
        add r12, 8h
        mov rax, [rbp + r12]
        
        mov r8, rax
        xor r10, r10

div_loop10:
        mov r11, rax
        mov r9, 10d
        xor rdx, rdx
        div r9
        xor rdx, rdx
        mul r9
        mov r8, rax
        mov rax, r11
        mov r9, alpha
        add r9, rax
        sub r9, r8
        mov r9, [r9]
        mov [num_buf + r10], r9
        
        mov r11, rax
        mov r9, 10d
        xor rdx, rdx
        div r9
        mov r8, rax
        mov rax, r11
        xor rdx, rdx
        div r9
        inc r10
        cmp r8, 0h
        jne div_loop10

        mov rax, 1h
        mov rdx, 1h
        dec r10

print_loop10:
        lea rsi, [num_buf + r10]
        syscall
        dec r10
        cmp r10, 0h
        jge print_loop10

        jmp next

jprnt_x:
        add r12, 8h
        mov rax, [rbp + r12]
        
        mov cl, 4h
        call prnt_bi

        jmp next

jprnt_o:
        add r12, 8h
        mov rax, [rbp + r12]
        
        mov cl, 3h
        call prnt_bi

        jmp next

jprnt_b:
        add r12, 8h
        mov rax, [rbp + r12]

        mov cl, 1h
        call prnt_bi

        jmp next

jprnt_s:
        add r12, 8h
        mov rcx, [rbp + r12]

        mov rax, 1h
        cmp BYTE [rcx], 0h
        je next

loop_s:
        mov rsi, rcx
        syscall
        mov rcx, rsi
        inc rcx
        cmp BYTE [rcx], 0h
        jne loop_s

        jmp next

jprnt_c:
        add r12, 8h
        mov rsi, rbp 
        add rsi, r12

        syscall
        mov rax, 1h
        jmp next

jprnt_prcnt:
        mov rsi, rbx
        syscall                         ; putchar(*char_now)
        jmp next                        ; goto next

;======================================================================
;prnt_bi - procedure which prints integer in number system modulo 2 ^ n
;
;in:    rax - integer to print
;       cl  - n
;       rdx = 1
;       rdi = 1
;
;out:   rax = 1
;       rdx = 1
;       rsi = rubbish
;       rdi = 1
;       r8  = 0
;       r9  = rubbish
;       r10 = 0
;
;======================================================================

prnt_bi:
        mov r8, rax
        xor r10, r10

div_loop:
        shr r8, cl
        shl r8, cl

        lea r9, [alpha + rax]
        sub r9, r8
        mov r9, [r9];
        mov [num_buf + r10], r9

        shr r8, cl
        shr rax, cl
        inc r10
        cmp r8, 0h
        jne div_loop

        mov rax, 1h
        dec r10

print_loop:
        lea rsi, [num_buf + r10]
        syscall
        dec r10
        cmp r10, 0h
        jge print_loop

        ret
