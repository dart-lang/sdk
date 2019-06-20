#if defined(_M_X64) || defined(__x86_64__) /* HOST_ARCH_X64 */

.intel_syntax noprefix
.text

#if defined(__linux__) || defined(__FreeBSD__) /* HOST_OS_LINUX */
.globl ClobberAndCall
.type ClobberAndCall, @function
ClobberAndCall:
#else /* HOST_OS_MACOS */
.globl _ClobberAndCall
_ClobberAndCall:
#endif

/* Clobber some significant registers and call the nullary function which is
   passed in as the first argument. */

/* Pool pointer register. */
push r15
mov r15, 1

/* Thread register. */
push r14
mov r14, 1

/* Code register. */
push r12
mov r12, 1

/* Arguments descriptor register. */
push r10
mov r10, 1

call rdi

pop r10
pop r12
pop r14
pop r15

ret

#elif defined(_M_IX86) || defined(__i386__)  /* HOST_ARCH_IA32 */

#elif defined(__aarch64__) /* HOST_ARCH_ARM64 */

.text
.global ClobberAndCall
.type ClobberAndCall, %function
ClobberAndCall:

/* Save link register register and thread register. */
stp lr, x26, [sp, #-16]!
mov lr, #1
mov x26, #1

/* Arguments descriptor register isn't callee-saved. */
mov x4, #1

/* Pool pointer register and code register. */
stp x24, x27, [sp, #-16]!

mov x24, #1
mov x27, #1

blr x0

ldp x24, x27, [sp], #16
ldp lr, x26, [sp], #16

blr lr

#elif defined(__ARMEL__)  /* HOST_ARCH_ARM */

.text
.global ClobberAndCall
.type ClobberAndCall, %function
ClobberAndCall:

stmdb sp!,{r4, r5, r6, r10, lr}

/* Arguments descriptor register. */
mov r4, #1

/* Pool pointer register. */
mov r5, #1

/* Code pointer register. */
mov r6, #1

/* Thread register. */
mov r10, #1

blx r0

ldm sp!,{r4, r5, r6, r10, pc}

#endif
