// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/cpu.h"
#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

intptr_t IndexFromPPLoad(uword start) {
  int32_t offset = *reinterpret_cast<int32_t*>(start);
  return ObjectPool::IndexFromOffset(offset);
}


uword JumpPattern::TargetAddress() const {
  ASSERT(IsValid());
  int index = IndexFromPPLoad(start() + 3);
  return object_pool_.RawValueAt(index);
}


void JumpPattern::SetTargetAddress(uword target) const {
  ASSERT(IsValid());
  int index = IndexFromPPLoad(start() + 3);
  object_pool_.SetRawValueAt(index, target);
  // No need to flush the instruction cache, since the code is not modified.
}


void ShortCallPattern::SetTargetAddress(uword target) const {
  ASSERT(IsValid());
  *reinterpret_cast<uint32_t*>(start() + 1) = target - start() - kLengthInBytes;
  CPU::FlushICache(start() + 1, kWordSize);
}


}  // namespace dart

#endif  // defined TARGET_ARCH_X64
