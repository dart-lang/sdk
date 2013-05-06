// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STACK_FRAME_ARM_H_
#define VM_STACK_FRAME_ARM_H_

namespace dart {

/* ARM Dart Frame Layout

               |                   | <- TOS
Callee frame   | ...               |
               | current LR        |    (PC of current frame)
               | PC Marker         |    (callee's frame code entry)
               +-------------------+
Current frame  | ...               | <- SP of current frame
               | first local       |
               | caller's PP       |
               | caller's FP       | <- FP of current frame
               | caller's LR       |    (PC of caller frame)
               | PC Marker         |    (current frame's code entry)
               +-------------------+
Caller frame   | last parameter    |
               |  ...              |
*/

static const int kLastParamSlotIndex = 3;  // From fp.
static const int kFirstLocalSlotIndex = -2;  // From fp.
static const int kPcSlotIndexFromSp = -2;

}  // namespace dart

#endif  // VM_STACK_FRAME_ARM_H_

