.text

.global ClobberAndCall
ClobberAndCall:

/* Save link register register and thread register. Keep stack aligned to 16 bytes. */
stp lr, x26, [sp, #-16]!
mov lr, #1
mov x26, #1

/* Arguments descriptor register isn't callee-saved. */
mov x4, #1

/* Dart stack pointer, also volatile. */
mov x15, #1

/* Pool pointer register and code register. Keep stack aligned to 16 bytes. */
stp x24, x27, [sp, #-16]!

mov x24, #1
mov x27, #1

/* Clobber all other volatile registers. */
mov x1, #1
mov x2, #1
mov x3, #1
mov x4, #1
mov x5, #1
mov x6, #1
mov x7, #1
mov x8, #1
mov x9, #1
mov x10, #1
mov x11, #1
mov x12, #1
mov x13, #1
mov x14, #1

blr x0

ldp x24, x27, [sp], #16
ldp lr, x26, [sp], #16

blr lr
