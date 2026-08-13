.text

#if defined(__linux__) || defined(__FreeBSD__) /* HOST_OS_LINUX */
.globl ClobberAndCall
.type ClobberAndCall, @function
ClobberAndCall:
#else /* HOST_OS_MACOS */
.globl _ClobberAndCall
_ClobberAndCall:
#endif

/* Clobber all volatile registers and call the nullary function which is
   passed in as the first argument. */

addi sp, sp, -64
sw ra, 60(sp)
sw fp, 56(sp)
addi fp, sp, 64

sw s1, 40(sp)
sw s2, 36(sp)
sw s3, 32(sp)
sw s4, 28(sp)
sw s5, 24(sp)
sw s6, 20(sp)
sw s7, 16(sp)
sw s8, 12(sp)
sw s9, 8(sp)
sw s10, 4(sp)
sw s11, 0(sp)

li ra, 1
li a1, 1
li a2, 1
li a3, 1
li a4, 1
li a5, 1
li a6, 1
li a7, 1
li t0, 1
li t1, 1
li t2, 1
li t3, 1
li t4, 1
li t5, 1
li t6, 1
li s1, 1
li s2, 1
li s3, 1
li s4, 1
li s5, 1
li s6, 1
li s7, 1
li s8, 1
li s9, 1
li s10, 1
li s11, 1

jalr a0

lw s11, 0(sp)
lw s10, 4(sp)
lw s9, 8(sp)
lw s8, 12(sp)
lw s7, 16(sp)
lw s6, 20(sp)
lw s5, 24(sp)
lw s4, 28(sp)
lw s3, 32(sp)
lw s2, 36(sp)
lw s1, 40(sp)

lw fp, 56(sp)
lw ra, 60(sp)
addi sp, sp, 64
ret
