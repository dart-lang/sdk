// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/cpu.h"
#include "vm/constants_x64.h"
#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

void ShortCallPattern::SetTargetAddress(uword target) const {
  ASSERT(IsValid());
  *reinterpret_cast<uint32_t*>(start() + 1) = target - start() - kLengthInBytes;
  CPU::FlushICache(start() + 1, kWordSize);
}


bool DecodeLoadObjectFromPoolOrThread(uword pc,
                                      const Code& code,
                                      Object* obj) {
  ASSERT(code.ContainsInstructionAt(pc));

  uint8_t* bytes = reinterpret_cast<uint8_t*>(pc);
  COMPILE_ASSERT(PP == R15);
  if (((bytes[0] == 0x49) && (bytes[1] == 0x8b) && (bytes[2] == 0x9f)) ||
      ((bytes[0] == 0x49) && (bytes[1] == 0x8b) && (bytes[2] == 0x87)) ||
      ((bytes[0] == 0x4d) && (bytes[1] == 0x8b) && (bytes[2] == 0xa7)) ||
      ((bytes[0] == 0x4d) && (bytes[1] == 0x8b) && (bytes[2] == 0x9f)) ||
      ((bytes[0] == 0x4d) && (bytes[1] == 0x8b) && (bytes[2] == 0x97))) {
    intptr_t index = IndexFromPPLoad(pc + 3);
    const ObjectPool& pool = ObjectPool::Handle(code.object_pool());
    if (pool.InfoAt(index) == ObjectPool::kTaggedObject) {
      *obj = pool.ObjectAt(index);
      return true;
    }
  }
  COMPILE_ASSERT(THR == R14);
  if (((bytes[0] == 0x49) && (bytes[1] == 0x8b) && (bytes[2] == 0x86)) ||
      ((bytes[0] == 0x49) && (bytes[1] == 0x8b) && (bytes[2] == 0xb6)) ||
      ((bytes[0] == 0x49) && (bytes[1] == 0x8b) && (bytes[2] == 0x96)) ||
      ((bytes[0] == 0x49) && (bytes[1] == 0x8b) && (bytes[2] == 0x9e)) ||
      ((bytes[0] == 0x4d) && (bytes[1] == 0x8b) && (bytes[2] == 0x9e)) ||
      ((bytes[0] == 0x4d) && (bytes[1] == 0x8b) && (bytes[2] == 0xa6))) {
    int32_t offset = *reinterpret_cast<int32_t*>(pc + 3);
    return Thread::ObjectAtOffset(offset, obj);
  }
  if (((bytes[0] == 0x41) && (bytes[1] == 0xff) && (bytes[2] == 0x76)) ||
      ((bytes[0] == 0x49) && (bytes[1] == 0x3b) && (bytes[2] == 0x66)) ||
      ((bytes[0] == 0x49) && (bytes[1] == 0x8b) && (bytes[2] == 0x46)) ||
      ((bytes[0] == 0x4d) && (bytes[1] == 0x8b) && (bytes[2] == 0x5e)) ||
      ((bytes[0] == 0x4d) && (bytes[1] == 0x8b) && (bytes[2] == 0x66)) ||
      ((bytes[0] == 0x4d) && (bytes[1] == 0x8b) && (bytes[2] == 0x6e))) {
    uint8_t offset = *reinterpret_cast<uint8_t*>(pc + 3);
    return Thread::ObjectAtOffset(offset, obj);
  }

  return false;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
