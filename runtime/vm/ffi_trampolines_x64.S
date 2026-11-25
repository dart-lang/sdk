// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// FFI trampolines for the simulator on x86_64 host.
// Calls from simulated ARM64 to host x86_64 C functions.

#if defined(__APPLE__)
#define LOCAL_SYMBOL(x) L##x
#else
#define LOCAL_SYMBOL(x) .L##x
#endif

#if defined(__x86_64__) &&                                                     \
    (defined(TARGET_ARCH_ARM64) || defined(TARGET_ARCH_RISCV64))

.text

#if defined(__APPLE__)
.globl _SimulatorFfiCalloutTrampoline
.private_extern _SimulatorFfiCalloutTrampoline
_SimulatorFfiCalloutTrampoline:
#else
.globl SimulatorFfiCalloutTrampoline
.type SimulatorFfiCalloutTrampoline, @function
SimulatorFfiCalloutTrampoline:
#endif
  pushq %rbp
  movq %rsp, %rbp

  // Preserve callee-saved registers.
  // Pushing %r12 and %r13 keeps %rsp 16-byte aligned:
  // After push %rbp, %rsp % 16 == 0.
  // After push %r12, %rsp % 16 == 8.
  // After push %r13, %rsp % 16 == 0.
  pushq %r12
  pushq %r13

  // Save the CalloutContext* argument (passed in %rdi).
  movq %rdi, %r12

  // CalloutContext.simulator_stack_pointer is at offset 16 (0x10).
  movq 16(%r12), %r13

  // Allocate 48 bytes (6 quadwords) on host stack for stack arguments.
  // 48 is a multiple of 16, so %rsp remains 16-byte aligned before callq.
  subq $48, %rsp

  // Copy stack arguments for System V AMD64 ABI:
  // Target ARM64 passes args 1-8 in registers, args 9-12 on simulated stack (sim_sp[0..3]).
  // Host x86_64 passes args 1-6 in registers, args 7-12 on host stack.
  // Host stack arg 7 (rsp + 0): CalloutContext.integer_arguments[6] (offset 80)
  movq 80(%r12), %rax
  movq %rax, 0(%rsp)

  // Host stack arg 8 (rsp + 8): CalloutContext.integer_arguments[7] (offset 88)
  movq 88(%r12), %rax
  movq %rax, 8(%rsp)

  // Host stack arg 9 (rsp + 16): target stack slot 0 (sim_sp[0])
  movq 0(%r13), %rax
  movq %rax, 16(%rsp)

  // Host stack arg 10 (rsp + 24): target stack slot 1 (sim_sp[1])
  movq 8(%r13), %rax
  movq %rax, 24(%rsp)

  // Host stack arg 11 (rsp + 32): target stack slot 2 (sim_sp[2])
  movq 16(%r13), %rax
  movq %rax, 32(%rsp)

  // Host stack arg 12 (rsp + 40): target stack slot 3 (sim_sp[3])
  movq 24(%r13), %rax
  movq %rax, 40(%rsp)

  // Load integer/pointer argument registers (args 1-6):
  movq 32(%r12), %rdi   // integer_arguments[0]
  movq 40(%r12), %rsi   // integer_arguments[1]
  movq 48(%r12), %rdx   // integer_arguments[2]
  movq 56(%r12), %rcx   // integer_arguments[3]
  movq 64(%r12), %r8    // integer_arguments[4]
  movq 72(%r12), %r9    // integer_arguments[5]

  // Load floating point argument registers (args 1-8):
  movsd 96(%r12), %xmm0   // double_arguments[0]
  movsd 104(%r12), %xmm1  // double_arguments[1]
  movsd 112(%r12), %xmm2  // double_arguments[2]
  movsd 120(%r12), %xmm3  // double_arguments[3]
  movsd 128(%r12), %xmm4  // double_arguments[4]
  movsd 136(%r12), %xmm5  // double_arguments[5]
  movsd 144(%r12), %xmm6  // double_arguments[6]
  movsd 152(%r12), %xmm7  // double_arguments[7]

  // System V AMD64 ABI: %al specifies the number of vector registers used for variadic functions.
  xorl %eax, %eax

  // Call target function at CalloutContext.target (offset 168 / 0xa8).
  callq *168(%r12)

  // Save return values into CalloutContext.
  movq %rax, 32(%r12)    // integer_arguments[0]
  movq %rdx, 40(%r12)    // integer_arguments[1]
  movsd %xmm0, 96(%r12)  // double_arguments[0]
  movsd %xmm1, 104(%r12) // double_arguments[1]

  // Deallocate host stack arguments and restore registers.
  addq $48, %rsp
  popq %r13
  popq %r12
  popq %rbp
  retq

#if !defined(__APPLE__)
.size SimulatorFfiCalloutTrampoline,.-SimulatorFfiCalloutTrampoline
#endif

#if defined(__linux__) && defined(__ELF__)
.section .note.GNU-stack,"",@progbits
#endif

#endif  // defined(__x86_64__)
