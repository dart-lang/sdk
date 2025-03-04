// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Callout trampoline from the simulator. This is not written as VM stub because
// we need it be executable in contexts where we cannot JIT. (Alternatively, we
// could start requiring the VM snapshot to be provided in every mode.)

#if defined(__aarch64__)

.text

#if defined(__APPLE__)
.globl _FfiCalloutTrampoline
_FfiCalloutTrampoline:
#else
.globl FfiCalloutTrampoline
.type FfiCalloutTrampoline, %function
FfiCalloutTrampoline:
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
.Lcopy:
  ldp x2, x3, [x1, #-16]!  // From Dart FP
  stp x2, x3, [sp, #-16]!  // To C SP
  cmp x1, x0
  b.gt .Lcopy

  // Load the ABI argument registers. Note that Dart FFI does not support
  // full 128-bit SIMD arguments, so we don't need to set the full V
  // registers.
  ldr x0, [x19, #32]  // CalloutContext.integer_arguments[0]
  ldr x1, [x19, #40]
  ldr x2, [x19, #48]
  ldr x3, [x19, #56]
  ldr x4, [x19, #64]
  ldr x5, [x19, #72]
  ldr x6, [x19, #80]
  ldr x7, [x19, #88]
  ldr d0, [x19, #96]  // CalloutContext.double_arguments[0]
  ldr d1, [x19, #104]
  ldr d2, [x19, #112]
  ldr d3, [x19, #120]
  ldr d4, [x19, #128]
  ldr d5, [x19, #136]
  ldr d6, [x19, #144]
  ldr d7, [x19, #152]
  ldr x8, [x19, #160]  // CalloutContext.r8

  // Call target.
  ldr lr, [x19, #168]  // CalloutContext.target
  blr lr

  // Save the ABI result registers.
  str x0, [x19, #32]  // CalloutContext.integer_arguments[0]
  str x1, [x19, #40]
  str d0, [x19, #96]  // CalloutContext.double_arguments[0]
  str d1, [x19, #104]

  add sp, fp, -16
  ldp x19, x20, [sp], #16
  ldp fp, lr, [sp], #16
  ret
#if !defined(__APPLE__)
.size FfiCalloutTrampoline,.-FfiCalloutTrampoline
#endif

#endif  // defined(__aarch64__)
