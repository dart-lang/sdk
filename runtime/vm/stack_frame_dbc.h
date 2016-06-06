// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STACK_FRAME_DBC_H_
#define VM_STACK_FRAME_DBC_H_

namespace dart {

/* DBC Frame Layout

IMPORTANT: On DBC stack is growing upwards which is different from all other
architectures. This enables effecient addressing for locals via unsigned index.

               |                    | <- TOS
Callee frame   | ...                |
               | saved FP           |    (FP of current frame)
               | saved PC           |    (PC of current frame)
               | code object        |
               | function object    |
               +--------------------+
Current frame  | ...               T| <- SP of current frame
               | ...               T|
               | first local       T| <- FP of current frame
               | caller's FP       *|
               | caller's PC       *|
               | code object       T|    (current frame's code object)
               | function object   T|    (current frame's function object)
               +--------------------+
Caller frame   | last parameter     | <- SP of caller frame
               |  ...               |

               T against a slot indicates it needs to be traversed during GC.
               * against a slot indicates that it can be traversed during GC
                 because it will look like a smi to the visitor.
*/

static const int kDartFrameFixedSize = 4;  // Function, Code, PC, FP
static const int kSavedPcSlotFromSp = 3;

static const int kFirstObjectSlotFromFp = -4;  // Used by GC to traverse stack.

static const int kSavedCallerFpSlotFromFp = -1;
static const int kSavedCallerPpSlotFromFp = kSavedCallerFpSlotFromFp;
static const int kSavedCallerPcSlotFromFp = -2;
static const int kCallerSpSlotFromFp = -kDartFrameFixedSize-1;
static const int kPcMarkerSlotFromFp = -3;
static const int kFunctionSlotFromFp = -4;

// Note: These constants don't match actual DBC behavior. This is done because
// setting kFirstLocalSlotFromFp to 0 breaks assumptions spread across the code.
// Instead for the purposes of local variable allocation we pretend that DBC
// behaves as other architectures (stack growing downwards) and later fix
// these indices during code generation in the backend.
static const int kParamEndSlotFromFp = 4;  // One slot past last parameter.
static const int kFirstLocalSlotFromFp = -1;


DART_FORCE_INLINE static uword LocalVarAddress(uword fp, intptr_t index) {
  ASSERT(index != 0);
  if (index > 0) {
     return fp - index * kWordSize;
  } else {
     return fp - (index + 1) * kWordSize;
  }
}

DART_FORCE_INLINE static uword ParamAddress(uword fp, intptr_t reverse_index) {
  return fp - (kDartFrameFixedSize + reverse_index) * kWordSize;
}

DART_FORCE_INLINE static bool IsCalleeFrameOf(uword fp, uword other_fp) {
  return other_fp > fp;
}

static const int kExitLinkSlotFromEntryFp = 0;

// Value for stack limit that is used to cause an interrupt.
// Note that on DBC stack is growing upwards so interrupt limit is 0 unlike
// on all other architectures.
static const uword kInterruptStackLimit = 0;

}  // namespace dart

#endif  // VM_STACK_FRAME_DBC_H_
