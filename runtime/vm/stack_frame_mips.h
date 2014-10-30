// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STACK_FRAME_MIPS_H_
#define VM_STACK_FRAME_MIPS_H_

namespace dart {

/* MIPS Dart Frame Layout

               |                    | <- TOS
Callee frame   | ...                |
               | current RA         |    (PC of current frame)
               | callee's PC marker |
               +--------------------+
Current frame  | ...               T| <- SP of current frame
               | first local       T|
               | caller's PP       T|
               | caller's FP        | <- FP of current frame
               | caller's RA        |    (PC of caller frame)
               | PC marker          |    (current frame's code entry + offset)
               +--------------------+
Caller frame   | last parameter     | <- SP of caller frame
               |  ...               |

               T against a slot indicates it needs to be traversed during GC.
*/

static const int kDartFrameFixedSize = 4;  // PP, FP, RA, PC marker.
static const int kSavedPcSlotFromSp = -2;

static const int kFirstObjectSlotFromFp = -1;  // Used by GC to traverse stack.

static const int kFirstLocalSlotFromFp = -2;
static const int kSavedCallerPpSlotFromFp = -1;
static const int kSavedCallerFpSlotFromFp = 0;
static const int kSavedCallerPcSlotFromFp = 1;
static const int kPcMarkerSlotFromFp = 2;
static const int kParamEndSlotFromFp = 2;  // One slot past last parameter.
static const int kCallerSpSlotFromFp = 3;

// Entry and exit frame layout.
static const int kExitLinkSlotFromEntryFp = -22;

}  // namespace dart

#endif  // VM_STACK_FRAME_MIPS_H_
