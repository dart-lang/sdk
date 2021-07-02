// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STACK_FRAME_ARM64_H_
#define RUNTIME_VM_STACK_FRAME_ARM64_H_

#if !defined(RUNTIME_VM_STACK_FRAME_H_)
#error Do not include stack_frame_arm64.h directly; use stack_frame.h instead.
#endif

namespace dart {

/* ARM64 Dart Frame Layout
               |                    | <- TOS
Callee frame   | ...                |
               | saved PP           |
               | code object        |
               | saved FP           |    (FP of current frame)
               | saved PC           |    (PC of current frame)
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
static const int kLastParamSlotFromEntrySp = 0;

// Entry and exit frame layout.
#if defined(TARGET_OS_FUCHSIA)
static const int kExitLinkSlotFromEntryFp = -24;
COMPILE_ASSERT(kAbiPreservedCpuRegCount == 11);
#else
static const int kExitLinkSlotFromEntryFp = -23;
COMPILE_ASSERT(kAbiPreservedCpuRegCount == 10);
#endif
COMPILE_ASSERT(kAbiPreservedFpuRegCount == 8);

// For FFI native -> Dart callbacks, this is the number of stack slots between
// arguments passed on stack and arguments saved in callback prologue.
//
// 2 = return adddress (1) + saved frame pointer (1).
//
// If NativeCallbackTrampolines::Enabled(), then
// kNativeCallbackTrampolineStackDelta must be added as well.
constexpr intptr_t kCallbackSlotsBeforeSavedArguments = 2;

// For FFI calls passing in TypedData, we save it on the stack before entering
// a Dart frame. This denotes how to get to the backed up typed data.
static const int kFfiCallerTypedDataSlotFromFp = kCallerSpSlotFromFp;

}  // namespace dart

#endif  // RUNTIME_VM_STACK_FRAME_ARM64_H_
