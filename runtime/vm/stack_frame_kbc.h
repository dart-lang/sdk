// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STACK_FRAME_KBC_H_
#define RUNTIME_VM_STACK_FRAME_KBC_H_

#include "platform/globals.h"

namespace dart {

/* Kernel Bytecode Frame Layout

IMPORTANT: KBC stack is growing upwards which is different from all other
architectures. This enables efficient addressing for locals via unsigned index.

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
               | caller's FP        |
               | caller's PC        |
               | code object       T|    (current frame's code object)
               | function object   T|    (current frame's function object)
               +--------------------+
Caller frame   | last parameter     | <- SP of caller frame
               |  ...               |

               T against a slot indicates it needs to be traversed during GC.
*/

static const int kKBCDartFrameFixedSize = 4;  // Function, Code, PC, FP
static const int kKBCSavedPcSlotFromSp = 3;

static const int kKBCFirstObjectSlotFromFp = -4;  // Used by GC.
static const int kKBCLastFixedObjectSlotFromFp = -3;

static const int kKBCSavedCallerFpSlotFromFp = -1;
static const int kKBCSavedCallerPcSlotFromFp = -2;
static const int kKBCCallerSpSlotFromFp = -kKBCDartFrameFixedSize - 1;
static const int kKBCPcMarkerSlotFromFp = -3;
static const int kKBCFunctionSlotFromFp = -4;
static const int kKBCParamEndSlotFromFp = 4;

// Entry and exit frame layout.
static const int kKBCEntrySavedSlots = 3;
static const int kKBCExitLinkSlotFromEntryFp = 0;
static const int kKBCSavedArgDescSlotFromEntryFp = 1;
static const int kKBCSavedPpSlotFromEntryFp = 2;

// Value for stack limit that is used to cause an interrupt.
// Note that on KBC stack is growing upwards so interrupt limit is 0 unlike
// on all other architectures.
static const uword kKBCInterruptStackLimit = 0;

}  // namespace dart

#endif  // RUNTIME_VM_STACK_FRAME_KBC_H_
