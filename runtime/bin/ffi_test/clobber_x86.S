.intel_syntax noprefix
.text

.globl _ClobberAndCall
_ClobberAndCall:
.globl ClobberAndCall
ClobberAndCall:

/* Load the target function. */
mov eax, [esp+0x4]

/* Code register. */
push edi
mov edi, 1

/* Thread register. */
push esi
mov esi, 1

/* Arguments descriptor register (volatile). */
mov edx, 1

/* Clobber all other volatile registers. */
mov ecx, 1
mov edx, 1

/* Align the frame to 16 bytes. */
sub esp, 4

call eax

add esp, 4

pop esi
pop edi

ret
