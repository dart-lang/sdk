#if defined(__aarch64__) /* HOST_ARCH_ARM64 */

.text

#if defined(__ANDROID__) || defined(__linux__) || defined(__FreeBSD__)
/* HOST_OS_ANDROID || HOST_OS_LINUX */
.global FfiTrampolineCall
.align 2
FfiTrampolineCall:
#else /* HOST_OS_MACOS */
.global _FfiTrampolineCall
.align 2
_FfiTrampolineCall:
#endif

/* Save argument in scratch register. */
stp   x19,  x20, [sp, #-16]! /* Push x19 and x20, we use x19 as scratch. */
mov   x19,  x0              /* Save argument in scratch register. */

/* Enter frame. */
stp   fp,   lr, [sp, #-16]!
mov   fp,   sp

/* Reserve framespace for arguments. */
ldr   x9,   [x19, #(8*18)]  /* Load number of stack arguments. */
lsl   x9,   x9,  #3         /* Multiply by size (8 bytes). */
sub   sp,   sp,  x9         /* Reserve num_stack_args stack slots. */

/* Stack alignment. */
ldr   x10,  [x19, #(8*17)]  /* Load stack alignment mask. */
mov   x11,  sp
and   x11,  x11,  x10       /* Align stack. */
mov   sp,   x11

/* Copy stack arguments. */
cmp   x9,   #0              /* Check if number of stack arguments is 0. */
beq   .done                 /* Skip loop if no stack arguments. */
add   x19,  x19, #(8*19)    /* Offset r19 to point to stack arguments. */
.align 2
.loop:                      /* Copy stack arguments loop. */
sub   x9,   x9,   #8        /* Decrement stack argument iterator. */
ldr   x10,  [x19, x9]       /* Load value from ffi_marshalled_args. */
str   x10,  [sp,  x9]       /* Store value on stack. */
cmp   x9,   #0              /* Compare iterator with 0 */
bne   .loop                 /* Loop while iterator is not 0 */
sub   x19,  x19, #(8*19)    /* Restore r19 to original value. */
.align 2
.done:                      /* End stack arguments loop. */

/* Copy registers and fpu registers. */
ldp   x0, x1, [x19, #(8*1)] /* and #(8*2) */
ldp   x2, x3, [x19, #(8*3)] /* and #(8*4) */
ldp   x4, x5, [x19, #(8*5)] /* ... */
ldp   x6, x7, [x19, #(8*7)]
ldp   d0, d1, [x19, #(8*9)]
ldp   d2, d3, [x19, #(8*11)]
ldp   d4, d5, [x19, #(8*13)]
ldp   d6, d7, [x19, #(8*15)]

/* Do call. */
ldr   x9,   [x19]           /* Load function address. */
blr   x9                    /* Call the function. */

/* Copy results back. */
str   x0,   [x19, #(8*0)]   /* Move integer result in kOffsetIntResult. */
str   d0,   [x19, #(8*1)]   /* Move double result in kOffsetDoubleResult. */

/* Leave frame. */
mov   sp,   fp
ldp   fp,   lr,  [sp], #16

/* Restore caller saved register. */
ldp   x19,  x20, [sp], #16   /* Pop x19 and x20. */
ret

#endif /* HOST_ARCH_ARM64 */
