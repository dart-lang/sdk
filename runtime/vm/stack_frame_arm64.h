// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_STACK_FRAME_ARM64_H_
#define VM_STACK_FRAME_ARM64_H_

namespace dart {

// TODO(zra):
// These are the values for ARM. Fill in the values for ARM64 as they are
// needed.

static const int kDartFrameFixedSize = 4;  // PP, FP, LR, PC marker.
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
static const int kSavedContextSlotFromEntryFp = -27;
static const int kExitLinkSlotFromEntryFp = -26;
static const int kSavedVMTagSlotFromEntryFp = -25;

}  // namespace dart

#endif  // VM_STACK_FRAME_ARM64_H_
