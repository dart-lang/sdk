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

addi sp, sp, -112
sd ra, 104(sp)
sd fp, 96(sp)
addi fp, sp, 112

sd s1, 80(sp)
sd s2, 72(sp)
sd s3, 64(sp)
sd s4, 56(sp)
sd s5, 48(sp)
sd s6, 40(sp)
sd s7, 32(sp)
sd s8, 24(sp)
sd s9, 16(sp)
sd s10, 8(sp)
sd s11, 0(sp)

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

ld s11, 0(sp)
ld s10, 8(sp)
ld s9, 16(sp)
ld s8, 24(sp)
ld s7, 32(sp)
ld s6, 40(sp)
ld s5, 48(sp)
ld s4, 56(sp)
ld s3, 64(sp)
ld s2, 72(sp)
ld s1, 80(sp)

ld fp, 96(sp)
ld ra, 104(sp)
addi sp, sp, 112
ret
