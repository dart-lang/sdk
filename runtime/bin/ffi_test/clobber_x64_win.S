.code

ClobberAndCall proc

;; Clobber some significant registers and call the nullary function which is
;; passed in as the first argument.

;; Pool pointer register.
push r15
mov r15, 1

;; Thread register.
push r14
mov r14, 1

;; Code register.
push r12
mov r12, 1

;; Arguments descriptor register (volatile).
mov r10, 1

;; Clobber all other volatile registers (except the argument).
mov rax, 1
mov rdx, 1
mov r8, 1
mov r9, 1
mov r11, 1

;; Stack must be 16-byte aligned before the call. We save three registers above
;; to ensure this.
call rcx

pop r12
pop r14
pop r15

ret
ClobberAndCall endp

end
