// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_STACK_FRAME_IA32_H_
#define RUNTIME_VM_STACK_FRAME_IA32_H_

#if !defined(RUNTIME_VM_STACK_FRAME_H_)
#error Do not include stack_frame_ia32.h directly; use stack_frame.h instead.
#endif

namespace dart {

/* IA32 Dart Frame Layout

               |                    | <- TOS
Callee frame   | ...                |
               | saved EBP          |    (EBP of current frame)
               | saved PC           |    (PC of current frame)
               +--------------------+
Current frame  | ...               T| <- ESP of current frame
               | first local       T|
               | code object       T|    (current frame's code object)
               | caller's EBP       | <- EBP of current frame
               | caller's ret addr  |    (PC of caller frame)
               +--------------------+
Caller frame   | last parameter     | <- ESP of caller frame
               |  ...               |

               T against a slot indicates it needs to be traversed during GC.
*/

static const int kDartFrameFixedSize = 3;  // PC marker, EBP, PC.
static const int kSavedPcSlotFromSp = -1;

static const int kFirstObjectSlotFromFp = -1;  // Used by GC to traverse stack.
static const int kLastFixedObjectSlotFromFp = -1;

static const int kFirstLocalSlotFromFp = -2;
static const int kPcMarkerSlotFromFp = -1;
static const int kSavedCallerFpSlotFromFp = 0;
static const int kSavedCallerPcSlotFromFp = 1;
static const int kParamEndSlotFromFp = 1;  // One slot past last parameter.
static const int kCallerSpSlotFromFp = 2;
static const int kLastParamSlotFromEntrySp = 1;  // Skip return address.

// No pool pointer on IA32 (indicated by aliasing saved fp).
static const int kSavedCallerPpSlotFromFp = kSavedCallerFpSlotFromFp;

// Entry and exit frame layout.
static const int kExitLinkSlotFromEntryFp = -8;

// All arguments are passed on the stack, so none need to be saved. Therefore
// there is no frame for holding the saved arguments.
//
// If NativeCallbackTrampolines::Enabled(), then
// kNativeCallbackTrampolineStackDelta must be added as well.
constexpr intptr_t kCallbackSlotsBeforeSavedArguments = 0;

// For FFI calls passing in TypedData, we save it on the stack before entering
// a Dart frame. This denotes how to get to the backed up typed data.
static const int kFfiCallerTypedDataSlotFromFp = kCallerSpSlotFromFp;

}  // namespace dart

#endif  // RUNTIME_VM_STACK_FRAME_IA32_H_
