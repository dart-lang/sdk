#if defined(_M_X64) || defined(__x86_64__) /* HOST_ARCH_X64 */

.intel_syntax noprefix
.text

#if defined(__linux__) || defined(__FreeBSD__) /* HOST_OS_LINUX */
.globl FfiTrampolineCall
.type FfiTrampolineCall, @function
FfiTrampolineCall:
#else /* HOST_OS_MACOS */
.globl _FfiTrampolineCall
_FfiTrampolineCall:
#endif

/* Save argument in scratch register. */
push  rbx              /* Backup caller saved register. */
mov   rbx,  rdi        /* Save argument in scratch register. */

/* Enter frame. */
push  rbp
mov   rbp,  rsp

/* Reserve framespace for arguments. */
mov   rax,  [rbx+0x80] /* Load number of stack arguments. */
shl   rax,  3          /* Multiply by size (8 bytes). */
sub   rsp,  rax        /* Reserve num_stack_args stack slots. */

/* Stack alignment. */
and   rsp,  [rbx+0x78] /* Align stack with stack alignment mask. */

/* Copy stack arguments. */
cmp   rax,  0x0        /* Check if number of stack arguments is 0. */
jz    .done            /* Skip loop if no stack arguments. */
add   rsp,  rax        /* Unreserve stack slots so we can push arguments. */
add   rbx,  0x80       /* Offset RBX to point to stack arguments */
.loop:                 /* Copy stack arguments loop. */
push  [rbx+rax]        /* Push stack argument. */
sub   rax,  0x8        /* Decrement stack argument iterator. */
cmp   rax,  0x0        /* Compare iterator with 0 */
jnz   .loop            /* Loop while iterator is not 0 */
sub   rbx,  0x80       /* Restore RBX to original value. */
.done:                 /* End stack arguments loop. */

/* Copy registers and fpu registers. */
mov   rdi,  [rbx+0x8]  /* kArg1Reg */
mov   rsi,  [rbx+0x10] /* kArg2Reg */
mov   rdx,  [rbx+0x18] /* kArg3Reg */
mov   rcx,  [rbx+0x20] /* kArg4Reg */
mov   r8,   [rbx+0x28] /* kArg5Reg */
mov   r9,   [rbx+0x30] /* kArg6Reg */
movsd xmm0, [rbx+0x38]
movsd xmm1, [rbx+0x40]
movsd xmm2, [rbx+0x48]
movsd xmm3, [rbx+0x50]
movsd xmm4, [rbx+0x58]
movsd xmm5, [rbx+0x60]
movsd xmm6, [rbx+0x68]
movsd xmm7, [rbx+0x70]

/* Do call. */
mov   rax,  [rbx] /* function address */
call  rax         /* Call the function. */

/* Copy results back. */
mov   [rbx],   rax  /* Move integer result in kOffsetIntResult */
movsd [rbx+8], xmm0 /* Move double result in kOffsetDoubleResult */

/* leave frame */
mov   rsp,  rbp
pop   rbp

/* Restore caller saved register. */
pop   rbx

ret

#endif /* HOST_ARCH_X64 */
