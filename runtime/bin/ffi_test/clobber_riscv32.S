.text

#if defined(__linux__) || defined(__FreeBSD__) /* HOST_OS_LINUX */
.globl ClobberAndCall
.type ClobberAndCall, @function
ClobberAndCall:
#else /* HOST_OS_MACOS */
.globl _ClobberAndCall
_ClobberAndCall:
#endif

li a0, 1
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
ret
