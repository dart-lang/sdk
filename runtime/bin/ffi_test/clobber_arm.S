.text

.global ClobberAndCall
ClobberAndCall:

/* Save r3 to keep the stack aligned to 8 bytes. */
stmdb sp!,{r3, r4, r5, r6, r10, lr}

/* Arguments descriptor register. */
mov r4, #1

/* Pool pointer register. */
mov r5, #1

/* Code pointer register. */
mov r6, #1

/* Thread register. */
mov r10, #1

/* Clobber callee-saved registers. */
mov r1, #1
mov r2, #1
mov r3, #1
mov r12, #1

blx r0

ldm sp!,{r3, r4, r5, r6, r10, pc}
