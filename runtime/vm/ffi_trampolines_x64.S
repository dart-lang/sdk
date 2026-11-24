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

#if defined(SIMULATOR_FFI)
#if defined(__APPLE__)
.globl _SimulatorFfiCallbackTrampoline
.private_extern _SimulatorFfiCallbackTrampoline
_SimulatorFfiCallbackTrampoline:
#else
.globl SimulatorFfiCallbackTrampoline
.type SimulatorFfiCallbackTrampoline, @function
SimulatorFfiCallbackTrampoline:
#endif
LOCAL_SYMBOL(start_before_padding):
  .rept 16 // FfiCallbackMetadata::kUbsanTargetValidationPaddingSize = 16
  int3
  .endr
LOCAL_SYMBOL(start):
#if defined(TARGET_ARCH_ARM64)
#if defined(__Fuchsia__)
  .rept 482 // FfiCallbackMetadata::NumCallbackTrampolinesPerPage()
#elif defined(__APPLE__)
  .rept 2010 // FfiCallbackMetadata::NumCallbackTrampolinesPerPage()
#else
  .rept 8154 // FfiCallbackMetadata::NumCallbackTrampolinesPerPage()
#endif
#elif defined(TARGET_ARCH_RISCV64)
  .rept 484 // FfiCallbackMetadata::NumCallbackTrampolinesPerPage()
#endif
  callq LOCAL_SYMBOL(body)
  .byte 0x0f, 0x1f, 0x00  // 3-byte NOP (total 8 bytes per trampoline)
  .endr
LOCAL_SYMBOL(body):
  // Pop the return address pushed by 'callq LOCAL_SYMBOL(body)' into %r10
  // and subtract 5 to recover the exact trampoline entry address.
  popq %r10
  subq $5, %r10

  // %rsp now points to the C caller's return address (%rsp % 16 == 8).
  pushq %rbp
  movq %rsp, %rbp

  // Allocate CallbackContext (144 bytes) on the stack.
  // Since %rbp % 16 == 0 and 144 % 16 == 0, %rsp remains 16-byte aligned.
  subq $144, %rsp

  // Save ABI integer argument registers (args 1-6).
  movq %rdi, 0(%rsp)   // CallbackContext.integer_arguments[0]
  movq %rsi, 8(%rsp)   // CallbackContext.integer_arguments[1]
  movq %rdx, 16(%rsp)  // CallbackContext.integer_arguments[2]
  movq %rcx, 24(%rsp)  // CallbackContext.integer_arguments[3]
  movq %r8, 32(%rsp)   // CallbackContext.integer_arguments[4]
  movq %r9, 40(%rsp)   // CallbackContext.integer_arguments[5]

  // Save host stack arguments (args 7-8) located at 16(%rbp) and 24(%rbp).
  movq 16(%rbp), %rax
  movq %rax, 48(%rsp)  // CallbackContext.integer_arguments[6]
  movq 24(%rbp), %rax
  movq %rax, 56(%rsp)  // CallbackContext.integer_arguments[7]

  // Save ABI floating-point argument registers (args 1-8).
  movsd %xmm0, 64(%rsp)  // CallbackContext.double_arguments[0]
  movsd %xmm1, 72(%rsp)  // CallbackContext.double_arguments[1]
  movsd %xmm2, 80(%rsp)  // CallbackContext.double_arguments[2]
  movsd %xmm3, 88(%rsp)  // CallbackContext.double_arguments[3]
  movsd %xmm4, 96(%rsp)  // CallbackContext.double_arguments[4]
  movsd %xmm5, 104(%rsp) // CallbackContext.double_arguments[5]
  movsd %xmm6, 112(%rsp) // CallbackContext.double_arguments[6]
  movsd %xmm7, 120(%rsp) // CallbackContext.double_arguments[7]

  movq $0, 128(%rsp)     // CallbackContext.return_struct_pointer
  leaq 16(%rbp), %rax
  movq %rax, 136(%rsp)   // CallbackContext.sp

  // Call DoRedirectedFfiCallback(CallbackContext* ctxt, uword trampoline).
  movq %rsp, %rdi        // arg 1: CallbackContext* ctxt
  movq %r10, %rsi        // arg 2: uword trampoline

  // Load a pointer to the beginning of the stub (start_before_padding) into %rax
  // and round down to the page size (FfiCallbackMetadata::kPageMask).
  leaq LOCAL_SYMBOL(start_before_padding)(%rip), %rax
#if defined(TARGET_ARCH_ARM64)
#if defined(__Fuchsia__)
  andq $~(0x1000-1), %rax   // FfiCallbackMetadata::kPageSize = 4k
  addq $0x2000, %rax
#elif defined(__APPLE__)
  andq $~(0x4000-1), %rax   // FfiCallbackMetadata::kPageSize = 16k
  addq $0x8000, %rax
#else
  andq $~(0x10000-1), %rax  // FfiCallbackMetadata::kPageSize = 64k
  addq $0x20000, %rax
#endif
#elif defined(TARGET_ARCH_RISCV64)
  andq $~(0x1000-1), %rax   // FfiCallbackMetadata::kPageSize = 4k
  addq $0x2000, %rax
#endif
  movq (LOCAL_SYMBOL(start) - LOCAL_SYMBOL(start_before_padding) + 8)(%rax), %rax  // FfiCallbackMetadata::kDoRedirectedFfiCallback
  callq *%rax

  // Load ABI result registers from CallbackContext.
  movq 0(%rsp), %rax     // CallbackContext.integer_arguments[0]
  movq 8(%rsp), %rdx     // CallbackContext.integer_arguments[1]
  movsd 64(%rsp), %xmm0  // CallbackContext.double_arguments[0]
  movsd 72(%rsp), %xmm1  // CallbackContext.double_arguments[1]

  movq %rbp, %rsp
  popq %rbp
  retq
#if !defined(__APPLE__)
.size SimulatorFfiCallbackTrampoline,.-SimulatorFfiCallbackTrampoline
#endif

#if defined(__APPLE__)
.globl _SimulatorFfiCallbackTrampolineEnd
.private_extern _SimulatorFfiCallbackTrampolineEnd
_SimulatorFfiCallbackTrampolineEnd:
#else
.globl SimulatorFfiCallbackTrampolineEnd
.type SimulatorFfiCallbackTrampolineEnd, @function
SimulatorFfiCallbackTrampolineEnd:
#endif
  int3
#endif  // defined(SIMULATOR_FFI)

#if defined(__linux__) && defined(__ELF__)
.section .note.GNU-stack,"",@progbits
#endif

#endif  // defined(__x86_64__)
