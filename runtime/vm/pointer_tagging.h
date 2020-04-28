// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_POINTER_TAGGING_H_
#define RUNTIME_VM_POINTER_TAGGING_H_

#include "platform/assert.h"
#include "platform/globals.h"

// This header defines constants associated with pointer tagging:
//
//    * which bits determine whether or not this is a Smi value or a heap
//      pointer;
//    * which bits determine whether this is a pointer into a new or an old
//      space.

namespace dart {

// Dart VM aligns all objects by 2 words in in the old space and misaligns them
// in new space. This allows to distinguish new and old pointers by their bits.
//
// Note: these bits depend on the word size.
template <intptr_t word_size, intptr_t word_size_log2>
struct ObjectAlignment {
  // Alignment offsets are used to determine object age.
  static constexpr intptr_t kNewObjectAlignmentOffset = word_size;
  static constexpr intptr_t kOldObjectAlignmentOffset = 0;
  static constexpr intptr_t kNewObjectBitPosition = word_size_log2;

  // Object sizes are aligned to kObjectAlignment.
  static constexpr intptr_t kObjectAlignment = 2 * word_size;
  static constexpr intptr_t kObjectAlignmentLog2 = word_size_log2 + 1;
  static constexpr intptr_t kObjectAlignmentMask = kObjectAlignment - 1;

  // Discriminate between true and false based on the alignment bit.
  static constexpr intptr_t kBoolValueBitPosition = kObjectAlignmentLog2;
  static constexpr intptr_t kBoolValueMask = 1 << kBoolValueBitPosition;

  static constexpr intptr_t kTrueOffsetFromNull = kObjectAlignment * 2;
  static constexpr intptr_t kFalseOffsetFromNull = kObjectAlignment * 3;
};

using HostObjectAlignment = ObjectAlignment<kWordSize, kWordSizeLog2>;

static constexpr intptr_t kNewObjectAlignmentOffset =
    HostObjectAlignment::kNewObjectAlignmentOffset;
static constexpr intptr_t kOldObjectAlignmentOffset =
    HostObjectAlignment::kOldObjectAlignmentOffset;
static constexpr intptr_t kNewObjectBitPosition =
    HostObjectAlignment::kNewObjectBitPosition;
static constexpr intptr_t kObjectAlignment =
    HostObjectAlignment::kObjectAlignment;
static constexpr intptr_t kObjectAlignmentLog2 =
    HostObjectAlignment::kObjectAlignmentLog2;
static constexpr intptr_t kObjectAlignmentMask =
    HostObjectAlignment::kObjectAlignmentMask;
static constexpr intptr_t kBoolValueBitPosition =
    HostObjectAlignment::kBoolValueBitPosition;
static constexpr intptr_t kBoolValueMask = HostObjectAlignment::kBoolValueMask;
static constexpr intptr_t kTrueOffsetFromNull =
    HostObjectAlignment::kTrueOffsetFromNull;
static constexpr intptr_t kFalseOffsetFromNull =
    HostObjectAlignment::kFalseOffsetFromNull;

// The largest value of kObjectAlignment across all configurations.
static constexpr intptr_t kMaxObjectAlignment = 16;
COMPILE_ASSERT(kMaxObjectAlignment >= kObjectAlignment);

// On all targets heap pointers are tagged by set least significant bit.
//
// To recover address of the actual heap object kHeapObjectTag needs to be
// subtracted from the tagged pointer value.
//
// Smi-s (small integers) have least significant bit cleared.
//
// To recover the integer value tagged pointer value needs to be shifted
// right by kSmiTagShift.
enum {
  kSmiTag = 0,
  kHeapObjectTag = 1,
  kSmiTagSize = 1,
  kSmiTagMask = 1,
  kSmiTagShift = 1,
};

}  // namespace dart

#endif  // RUNTIME_VM_POINTER_TAGGING_H_
