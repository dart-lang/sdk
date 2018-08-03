// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STACK_FRAME_ARM_H_
#define RUNTIME_VM_STACK_FRAME_ARM_H_

namespace dart {

/* ARM Dart Frame Layout

               |                    | <- TOS
Callee frame   | ...                |
               | saved PP           |    (PP of current frame)
               | code object        |
               | saved FP           |    (FP of current frame)
               | saved LR           |    (PC of current frame)
               +--------------------+
Current frame  | ...               T| <- SP of current frame
               | first local       T|
               | caller's PP       T|
               | code object       T|    (current frame's code object)
               | caller's FP        | <- FP of current frame
               | caller's LR        |    (PC of caller frame)
               +--------------------+
Caller frame   | last parameter     | <- SP of caller frame
               |  ...               |

               T against a slot indicates it needs to be traversed during GC.
*/

static const int kDartFrameFixedSize = 4;  // PP, FP, LR, PC marker.
static const int kSavedPcSlotFromSp = -1;

static const int kFirstObjectSlotFromFp = -1;  // Used by GC to traverse stack.
static const int kLastFixedObjectSlotFromFp = -2;

static const int kFirstLocalSlotFromFp = -3;
static const int kSavedCallerPpSlotFromFp = -2;
static const int kPcMarkerSlotFromFp = -1;
static const int kSavedCallerFpSlotFromFp = 0;
static const int kSavedCallerPcSlotFromFp = 1;
static const int kParamEndSlotFromFp = 1;  // One slot past last parameter.
static const int kCallerSpSlotFromFp = 2;

// Entry and exit frame layout.
#if defined(TARGET_OS_MACOS) || defined(TARGET_OS_MACOS_IOS)
static const int kExitLinkSlotFromEntryFp = -26;
COMPILE_ASSERT(kAbiPreservedCpuRegCount == 6);
COMPILE_ASSERT(kAbiPreservedFpuRegCount == 4);
#else
static const int kExitLinkSlotFromEntryFp = -27;
COMPILE_ASSERT(kAbiPreservedCpuRegCount == 7);
COMPILE_ASSERT(kAbiPreservedFpuRegCount == 4);
#endif

}  // namespace dart

#endif  // RUNTIME_VM_STACK_FRAME_ARM_H_
