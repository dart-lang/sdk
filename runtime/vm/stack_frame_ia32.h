// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STACK_FRAME_IA32_H_
#define VM_STACK_FRAME_IA32_H_

namespace dart {

/* IA32 Dart Frame Layout

               |                   | <- TOS
Callee frame   | ...               |
               | current ret addr  |    (PC of current frame)
               +-------------------+
Current frame  | ...               | <- ESP of current frame
               | first local       |
               | PC Marker         |    (current frame's code entry)
               | caller's EBP      | <- EBP of current frame
               | caller's ret addr |    (PC of caller frame)
               +-------------------+
Caller frame   | last parameter    |
               |  ...              |
*/

static const int kLastParamSlotIndex = 2;  // From fp.
static const int kFirstLocalSlotIndex = -2;  // From fp.
static const int kPcSlotIndexFromSp = -1;

}  // namespace dart

#endif  // VM_STACK_FRAME_IA32_H_

