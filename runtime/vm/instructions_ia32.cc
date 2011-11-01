// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

bool Instruction::TestBytesWith(const int* data, int num_bytes) const {
  ASSERT(data != NULL);
  const uint8_t* byte_array = reinterpret_cast<const uint8_t*>(start_);
  for (int i = 0; i < num_bytes; i++) {
    // Skip comparison for data[i] < 0.
    if ((data[i] >= 0) && (byte_array[i] != (0xFF & data[i]))) {
      return false;
    }
  }
  return true;
}


uword CallOrJump::TargetAddress() const {
  ASSERT(IsValid());
  return start() + kLengthInBytes + *reinterpret_cast<uword*>(start() + 1);
}


void CallOrJump::SetTargetAddress(uword target) const {
  ASSERT(IsValid());
  *reinterpret_cast<uword*>(start() + 1) = target - start() - kLengthInBytes;
}


const int* Call::pattern() const {
  static const int kCallPattern[kLengthInBytes] = {0xE8, -1, -1, -1, -1};
  return kCallPattern;
}


const int* Jump::pattern() const {
  static const int kJumpPattern[kLengthInBytes] = {0xE9, -1, -1, -1, -1};
  return kJumpPattern;
}


}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
