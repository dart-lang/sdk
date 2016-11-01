// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STACK_FRAME_X64_H_
#define RUNTIME_VM_STACK_FRAME_X64_H_

namespace dart {

/* X64 Dart Frame Layout

               |                    | <- TOS
Callee frame   | ...                |
               | saved PP           |
               | code object        |
               | saved RBP          |    (RBP of current frame)
               | saved PC           |    (PC of current frame)
               +--------------------+
Current frame  | ...               T| <- RSP of current frame
               | first local       T|
               | caller's PP       T|
               | code object       T|    (current frame's code object)
               | caller's RBP       | <- RBP of current frame
               | caller's ret addr  |    (PC of caller frame)
               +--------------------+
Caller frame   | last parameter     | <- RSP of caller frame
               |  ...               |

               T against a slot indicates it needs to be traversed during GC.
*/

static const int kDartFrameFixedSize = 4;  // PC marker, RBP, PP, PC.
static const int kSavedPcSlotFromSp = -1;

static const int kFirstObjectSlotFromFp = -1;  // Used by GC to traverse stack.

static const int kFirstLocalSlotFromFp = -3;
static const int kSavedCallerPpSlotFromFp = -2;
static const int kPcMarkerSlotFromFp = -1;
static const int kSavedCallerFpSlotFromFp = 0;
static const int kSavedCallerPcSlotFromFp = 1;

static const int kParamEndSlotFromFp = 1;  // One slot past last parameter.
static const int kCallerSpSlotFromFp = 2;
static const int kSavedAboveReturnAddress = 3;  // Saved above return address.

// Entry and exit frame layout.
#if defined(_WIN64)
static const int kExitLinkSlotFromEntryFp = -32;
#else
static const int kExitLinkSlotFromEntryFp = -10;
#endif  // defined(_WIN64)

}  // namespace dart

#endif  // RUNTIME_VM_STACK_FRAME_X64_H_
