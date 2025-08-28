// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// FFI trampolines for the simulator and the interpreter.
// This is not written as VM stub because we need it be executable in contexts where we cannot JIT.
// (Alternatively, we could start requiring the VM snapshot to be provided in every mode.)

#if defined(__aarch64__) && (defined(SIMULATOR_FFI) || defined(DART_DYNAMIC_MODULES))

.text

#if defined(DART_DYNAMIC_MODULES)

#if defined(__APPLE__)
.globl _FfiCallTrampoline
_FfiCallTrampoline:
#else
.globl FfiCallTrampoline
.type FfiCallTrampoline, %function
FfiCallTrampoline:
#endif
  stp fp, lr, [sp, #-16]!
  mov fp, sp

  // Spill a preserved register to save args.
  stp x19, x20, [sp, #-16]!
  mov x19, x0         // FfiCallArguments* args

  // Copy top frame from Dart stack to C stack
  ldr x0, [x19, #0]  // FfiCallArguments.stack_area
  ldr x1, [x19, #8]  // FfiCallArguments.stack_area_end
.Lcopy1:
  ldp x2, x3, [x1, #-16]!  // From stack_area
  stp x2, x3, [sp, #-16]!  // To C SP
  cmp x1, x0
  b.gt .Lcopy1

  // Load the ABI argument registers. Note that Dart FFI does not support
  // full 128-bit SIMD arguments, so we don't need to set the full V
  // registers.
  ldp x0, x1, [x19, #16]    // FfiCallArguments.cpu_registers
  ldp x2, x3, [x19, #32]
  ldp x4, x5, [x19, #48]
  ldp x6, x7, [x19, #64]
  ldr x8, [x19, #80]
  ldp d0, d1, [x19, #272]  // FfiCallArguments.fpu_registers
  ldp d2, d3, [x19, #288]
  ldp d4, d5, [x19, #304]
  ldp d6, d7, [x19, #320]

  // Call target.
  ldr lr, [x19, #528]  // FfiCallArguments.target
  blr lr

  // Save the ABI result registers.
  stp x0, x1, [x19, #16]  // FfiCallArguments.cpu_registers
  stp d0, d1, [x19, #272]  // FfiCallArguments.fpu_registers
  stp d2, d3, [x19, #288]

  add sp, fp, -16
  ldp x19, x20, [sp], #16
  ldp fp, lr, [sp], #16
  ret
#if !defined(__APPLE__)
.size FfiCallTrampoline,.-FfiCallTrampoline
#endif

#endif  // defined(DART_DYNAMIC_MODULES)

#if defined(SIMULATOR_FFI)

#if defined(__APPLE__)
.globl _SimulatorFfiCalloutTrampoline
_SimulatorFfiCalloutTrampoline:
#else
.globl SimulatorFfiCalloutTrampoline
.type SimulatorFfiCalloutTrampoline, %function
SimulatorFfiCalloutTrampoline:
#endif
  stp fp, lr, [sp, #-16]!
  mov fp, sp

  // Spill a preserved register to save the context pointer.
  stp x19, x20, [sp, #-16]!
  mov x19, x0

  // Copy top frame from Dart stack to C stack
  ldr x0, [x19, #16]  // CalloutContext.simulator_stack_pointer (CSP)
  ldr x1, [x19, #24]  // CalloutContext.simulator_frame_pointer
  add x1, x1, 15   // Round up the frame pointer, since the Dart frame pointer
  and x1, x1, ~15  // is not double-word aligned.
.Lcopy2:
  ldp x2, x3, [x1, #-16]!  // From Dart FP
  stp x2, x3, [sp, #-16]!  // To C SP
  cmp x1, x0
  b.gt .Lcopy2

  // Load the ABI argument registers. Note that Dart FFI does not support
  // full 128-bit SIMD arguments, so we don't need to set the full V
  // registers.
  ldp x0, x1, [x19, #32]  // CalloutContext.integer_arguments[0]
  ldp x2, x3, [x19, #48]
  ldp x4, x5, [x19, #64]
  ldp x6, x7, [x19, #80]
  ldp d0, d1, [x19, #96]  // CalloutContext.double_arguments[0]
  ldp d2, d3, [x19, #112]
  ldp d4, d5, [x19, #128]
  ldp d6, d7, [x19, #144]
  ldr x8, [x19, #160]  // CalloutContext.r8

  // Call target.
  ldr lr, [x19, #168]  // CalloutContext.target
  blr lr

  // Save the ABI result registers.
  stp x0, x1, [x19, #32]  // CalloutContext.integer_arguments[0]
  stp d0, d1, [x19, #96]  // CalloutContext.double_arguments[0]
  stp d2, d3, [x19, #112]

  add sp, fp, -16
  ldp x19, x20, [sp], #16
  ldp fp, lr, [sp], #16
  ret
#if !defined(__APPLE__)
.size SimulatorFfiCalloutTrampoline,.-SimulatorFfiCalloutTrampoline
#endif

#if defined(__APPLE__)
.globl _SimulatorFfiCallbackTrampoline
_SimulatorFfiCallbackTrampoline:
#else
.globl SimulatorFfiCallbackTrampoline
.type SimulatorFfiCallbackTrampoline, %function
SimulatorFfiCallbackTrampoline:
#endif
  // FfiCallbackMetadata::NumCallbackTrampolinesPerPage() == 8150
  .rept 8150
  adr x9, 0
  b .Lbody
  .endr
.Lbody:
  mov x10, sp
  stp fp, lr, [sp, #-16]!
  mov fp, sp

  add sp, sp, -144  // Allocate CallbackContext

  // Save ABI argument registers.
  stp x0, x1, [sp, #0]  // CallbackContext.integer_arguments[0]
  stp x2, x3, [sp, #16]
  stp x4, x5, [sp, #32]
  stp x6, x7, [sp, #48]
  stp d0, d1, [sp, #64]  // CallbackContext.double_arguments[0]
  stp d2, d3, [sp, #80]
  stp d4, d5, [sp, #96]
  stp d6, d7, [sp, #112]
  str x8, [sp, #128]  // CallbackContext.r8
  str x10, [sp, #136]  // CallbackContext.sp

  // Pass arguments registers and thunk address to the runtime.
  mov x0, sp
  mov x1, x9  // I.e., which callback.
#if defined(__APPLE__)
  bl _DoRedirectedFfiCallback
#else
  bl DoRedirectedFfiCallback
#endif

  // Load ABI result registers.
  ldp x0, x1, [sp, #0]  // CallbackContext.integer_arguments[0]
  ldp d0, d1, [sp, #64]  // CallbackContext.double_arguments[0]
  ldp d2, d3, [sp, #80]

  mov sp, fp
  ldp fp, lr, [sp], #16
  ret
#if !defined(__APPLE__)
.size SimulatorFfiCallbackTrampoline,.-SimulatorFfiCallbackTrampoline
#endif

#if defined(__APPLE__)
.globl _SimulatorFfiCallbackTrampolineEnd
_SimulatorFfiCallbackTrampolineEnd:
#else
.globl SimulatorFfiCallbackTrampolineEnd
.type SimulatorFfiCallbackTrampolineEnd, %function
SimulatorFfiCallbackTrampolineEnd:
#endif
  brk 0

#endif  // defined(SIMULATOR_FFI)

#endif  // defined(__aarch64__) && (defined(SIMULATOR_FFI) || defined(DART_DYNAMIC_MODULES))
