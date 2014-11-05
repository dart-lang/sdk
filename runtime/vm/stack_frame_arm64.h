// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STACK_FRAME_ARM64_H_
#define VM_STACK_FRAME_ARM64_H_

namespace dart {

/* ARM64 Dart Frame Layout
               |                    | <- TOS
Callee frame   | ...                |
               | saved PP           |
               | callee's PC marker |
               | saved FP           |    (FP of current frame)
               | saved PC           |    (PC of current frame)
               +--------------------+
Current frame  | ...               T| <- SP of current frame
               | first local       T|
               | caller's PP       T|
               | PC marker          |    (current frame's code entry + offset)
               | caller's FP        | <- FP of current frame
               | caller's LR        |    (PC of caller frame)
               +--------------------+
Caller frame   | last parameter     | <- SP of caller frame
               |  ...               |

               T against a slot indicates it needs to be traversed during GC.
*/

static const int kDartFrameFixedSize = 4;  // PP, FP, LR, PC marker.
static const int kSavedPcSlotFromSp = -1;

static const int kFirstObjectSlotFromFp = -2;  // Used by GC to traverse stack.

static const int kFirstLocalSlotFromFp = -3;
static const int kSavedCallerPpSlotFromFp = -2;
static const int kPcMarkerSlotFromFp = -1;
static const int kSavedCallerFpSlotFromFp = 0;
static const int kSavedCallerPcSlotFromFp = 1;

static const int kParamEndSlotFromFp = 1;  // One slot past last parameter.
static const int kCallerSpSlotFromFp = 2;
static const int kSavedAboveReturnAddress = 3;  // Saved above return address.

// Entry and exit frame layout.
static const int kExitLinkSlotFromEntryFp = -20;

}  // namespace dart

#endif  // VM_STACK_FRAME_ARM64_H_
