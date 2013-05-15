// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STACK_FRAME_X64_H_
#define VM_STACK_FRAME_X64_H_

namespace dart {

/* X64 Dart Frame Layout

               |                    | <- TOS
Callee frame   | ...                |
               | saved RBP          |    (RBP of current frame)
               | saved PC           |    (PC of current frame)
               +--------------------+
Current frame  | ...                | <- RSP of current frame
               | first local        |
               | PC marker          |    (current frame's code entry + offset)
               | caller's RBP       | <- RBP of current frame
               | caller's ret addr  |    (PC of caller frame)
               +--------------------+
Caller frame   | last parameter     | <- RSP of caller frame
               |  ...               |
*/

static const int kDartFrameFixedSize = 3;  // PC marker, RBP, PC.
static const int kSavedPcSlotFromSp = -1;
static const int kFirstLocalSlotFromFp = -2;
static const int kPcMarkerSlotFromFp = -1;
static const int kSavedCallerFpSlotFromFp = 0;
static const int kSavedCallerPcSlotFromFp = 1;
static const int kParamEndSlotFromFp = 1;  // One slot past last parameter.
static const int kCallerSpSlotFromFp = 2;

// No pool pointer on X64 (indicated by aliasing saved fp).
static const int kSavedCallerPpSlotFromFp = kSavedCallerFpSlotFromFp;

// Entry and exit frame layout.
static const int kSavedContextSlotFromEntryFp = -9;
static const int kExitLinkSlotFromEntryFp = -8;

}  // namespace dart

#endif  // VM_STACK_FRAME_X64_H_

