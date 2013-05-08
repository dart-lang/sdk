// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STACK_FRAME_IA32_H_
#define VM_STACK_FRAME_IA32_H_

namespace dart {

/* IA32 Dart Frame Layout

               |                    | <- TOS
Callee frame   | ...                |
               | current ret addr   |    (PC of current frame)
               +--------------------+
Current frame  | ...                | <- ESP of current frame
               | first local        |
               | PC marker          |    (current frame's code entry + offset)
               | caller's EBP       | <- EBP of current frame
               | caller's ret addr  |    (PC of caller frame)
               +--------------------+
Caller frame   | last parameter     | <- ESP of caller frame
               |  ...               |
*/

static const int kSavedPcSlotFromSp = -1;
static const int kFirstLocalSlotFromFp = -2;
static const int kPcMarkerSlotFromFp = -1;
static const int kSavedCallerFpSlotFromFp = 0;
static const int kParamEndSlotFromFp = 1;  // Same slot as caller's ret addr.
static const int kCallerSpSlotFromFp = 2;

// Entry and exit frame layout.
static const int kSavedContextSlotFromEntryFp = -5;
static const int kExitLinkSlotFromEntryFp = -4;

}  // namespace dart

#endif  // VM_STACK_FRAME_IA32_H_

