// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// FFI trampolines for the 32-bit simulator (simarm, simriscv32) on IA32 host.

#if defined(__APPLE__)
#define LOCAL_SYMBOL(x) L##x
#else
#define LOCAL_SYMBOL(x) .L##x
#endif

#if defined(__i386__) && defined(SIMULATOR_FFI)

.text

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
  .rept 8 // FfiCallbackMetadata::kUbsanTargetValidationPaddingSize = 8
  int3
  .endr
LOCAL_SYMBOL(start):
#if defined(TARGET_ARCH_ARM)
  .rept 488 // FfiCallbackMetadata::NumCallbackTrampolinesPerPage()
#elif defined(TARGET_ARCH_RISCV32)
  .rept 484 // FfiCallbackMetadata::NumCallbackTrampolinesPerPage()
#endif
  call LOCAL_SYMBOL(body)
  .byte 0x0f, 0x1f, 0x00  // 3-byte NOP (total 8 bytes per trampoline)
  .endr
LOCAL_SYMBOL(body):
  // Pop the return address pushed by 'call LOCAL_SYMBOL(body)' into %edx
  // and subtract 5 to recover the exact trampoline entry address.
  popl %edx
  subl $5, %edx

  // %esp now points to the C caller's return address (%esp % 16 == 12).
  pushl %ebp
  movl %esp, %ebp

  // Allocate CallbackContext (72 bytes) + 8 bytes padding = 80 bytes on stack.
  // %ebp % 16 == 8, so after subl $80, %esp % 16 == 8.
  subl $80, %esp

  // Copy up to 8 C integer arguments from caller stack frame (8(%ebp)..36(%ebp))
  // into CallbackContext.integer_arguments[0..7] at 0(%esp)..28(%esp).
  movl 8(%ebp), %eax
  movl %eax, 0(%esp)
  movl 12(%ebp), %eax
  movl %eax, 4(%esp)
  movl 16(%ebp), %eax
  movl %eax, 8(%esp)
  movl 20(%ebp), %eax
  movl %eax, 12(%esp)
  movl 24(%ebp), %eax
  movl %eax, 16(%esp)
  movl 28(%ebp), %eax
  movl %eax, 20(%esp)
  movl 32(%ebp), %eax
  movl %eax, 24(%esp)
  movl 36(%ebp), %eax
  movl %eax, 28(%esp)

  movl $0, 64(%esp)     // CallbackContext.return_struct_pointer
  leal 8(%ebp), %eax
  movl %eax, 68(%esp)   // CallbackContext.sp

  // Call DoRedirectedFfiCallback(CallbackContext* ctxt, uword trampoline).
  // Pushing two 4-byte arguments decreases %esp by 8 bytes -> %esp % 16 == 0.
  movl %esp, %ecx
  pushl %edx            // arg 2: uword trampoline
  pushl %ecx            // arg 1: CallbackContext* ctxt

  // Load a pointer to the beginning of the stub (start_before_padding) into %eax
  // and round down to the page size (FfiCallbackMetadata::kPageMask).
  call 1f
1:
  popl %eax
  subl $(1b - LOCAL_SYMBOL(start_before_padding)), %eax
  andl $~(0x1000-1), %eax   // FfiCallbackMetadata::kPageSize = 4k
  movl (0x2000 + LOCAL_SYMBOL(start) - LOCAL_SYMBOL(start_before_padding) + 4)(%eax), %eax  // FfiCallbackMetadata::kDoRedirectedFfiCallback
  call *%eax

  addl $8, %esp

  // Load ABI result registers from CallbackContext.
  movl 0(%esp), %eax    // CallbackContext.integer_arguments[0]
  movl 4(%esp), %edx    // CallbackContext.integer_arguments[1]

  movl %ebp, %esp
  popl %ebp
  ret
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

#if defined(__linux__) && defined(__ELF__)
.section .note.GNU-stack,"",@progbits
#endif

#endif  // defined(__i386__) && defined(SIMULATOR_FFI)
