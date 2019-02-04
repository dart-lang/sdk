// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/code_patcher.h"
#include "vm/instructions.h"
#include "vm/instructions_x64.h"

#include "vm/constants_x64.h"
#include "vm/cpu.h"
#include "vm/object.h"

namespace dart {

// [start] is the address of a displacement inside a load instruction
intptr_t IndexFromPPLoadDisp8(uword start) {
  int8_t offset = *reinterpret_cast<int8_t*>(start);
  return ObjectPool::IndexFromOffset(offset);
}

intptr_t IndexFromPPLoadDisp32(uword start) {
  int32_t offset = *reinterpret_cast<int32_t*>(start);
  return ObjectPool::IndexFromOffset(offset);
}

bool DecodeLoadObjectFromPoolOrThread(uword pc, const Code& code, Object* obj) {
  ASSERT(code.ContainsInstructionAt(pc));

  uint8_t* bytes = reinterpret_cast<uint8_t*>(pc);

  COMPILE_ASSERT(PP == R15);
  if ((bytes[0] == 0x49) || (bytes[0] == 0x4d)) {
    if ((bytes[1] == 0x8b) || (bytes[1] == 0x3b)) {  // movq, cmpq
      if ((bytes[2] & 0xc7) == (0x80 | (PP & 7))) {  // [r15+disp32]
        intptr_t index = IndexFromPPLoadDisp32(pc + 3);
        const ObjectPool& pool = ObjectPool::Handle(code.object_pool());
        if (!pool.IsNull()) {
          if (pool.TypeAt(index) == ObjectPool::EntryType::kTaggedObject) {
            *obj = pool.ObjectAt(index);
            return true;
          }
        }
      }
      if ((bytes[2] & 0xc7) == (0x40 | (PP & 7))) {  // [r15+disp8]
        intptr_t index = IndexFromPPLoadDisp8(pc + 3);
        const ObjectPool& pool = ObjectPool::Handle(code.object_pool());
        if (!pool.IsNull()) {
          if (pool.TypeAt(index) == ObjectPool::EntryType::kTaggedObject) {
            *obj = pool.ObjectAt(index);
            return true;
          }
        }
      }
    }
  }

  COMPILE_ASSERT(THR == R14);
  if ((bytes[0] == 0x49) || (bytes[0] == 0x4d)) {
    if ((bytes[1] == 0x8b) || (bytes[1] == 0x3b)) {   // movq, cmpq
      if ((bytes[2] & 0xc7) == (0x80 | (THR & 7))) {  // [r14+disp32]
        int32_t offset = *reinterpret_cast<int32_t*>(pc + 3);
        return Thread::ObjectAtOffset(offset, obj);
      }
      if ((bytes[2] & 0xc7) == (0x40 | (THR & 7))) {  // [r14+disp8]
        uint8_t offset = *reinterpret_cast<uint8_t*>(pc + 3);
        return Thread::ObjectAtOffset(offset, obj);
      }
    }
  }
  if (((bytes[0] == 0x41) && (bytes[1] == 0xff) && (bytes[2] == 0x76))) {
    // push [r14+disp8]
    uint8_t offset = *reinterpret_cast<uint8_t*>(pc + 3);
    return Thread::ObjectAtOffset(offset, obj);
  }

  return false;
}

intptr_t TypeTestingStubCallPattern::GetSubtypeTestCachePoolIndex() {
  static int16_t pattern_disp8[] = {
      0x4d, 0x8b, 0x4f, -1,  // movq R9, [PP + offset]
      0xff, 0x53, 0x07,      // callq [RBX + 0x7]
  };
  static int16_t pattern_disp32[] = {
      0x4d, 0x8b, 0x8f, -1, -1, -1, -1,  // movq R9, [PP + offset]
      0xff, 0x53, 0x07,                  // callq [RBX + 0x7]
  };
  if (MatchesPattern(pc_, pattern_disp8, ARRAY_SIZE(pattern_disp8))) {
    return IndexFromPPLoadDisp8(pc_ - 4);
  } else if (MatchesPattern(pc_, pattern_disp32, ARRAY_SIZE(pattern_disp32))) {
    return IndexFromPPLoadDisp32(pc_ - 7);
  } else {
    FATAL1("Failed to decode at %" Px, pc_);
  }
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
