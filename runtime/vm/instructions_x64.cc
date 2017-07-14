// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/instructions.h"
#include "vm/instructions_x64.h"

#include "vm/constants_x64.h"
#include "vm/cpu.h"
#include "vm/object.h"

namespace dart {

bool DecodeLoadObjectFromPoolOrThread(uword pc, const Code& code, Object* obj) {
  ASSERT(code.ContainsInstructionAt(pc));

  uint8_t* bytes = reinterpret_cast<uint8_t*>(pc);

  COMPILE_ASSERT(PP == R15);
  if ((bytes[0] == 0x49) || (bytes[0] == 0x4d)) {
    if ((bytes[1] == 0x8b) || (bytes[1] == 0x3b)) {  // movq, cmpq
      if ((bytes[2] & 0xc7) == (0x80 | (PP & 7))) {  // [r15+disp32]
        intptr_t index = IndexFromPPLoad(pc + 3);
        const ObjectPool& pool = ObjectPool::Handle(code.object_pool());
        if (pool.InfoAt(index) == ObjectPool::kTaggedObject) {
          *obj = pool.ObjectAt(index);
          return true;
        }
      }
      if ((bytes[2] & 0xc7) == (0x40 | (PP & 7))) {  // [r15+disp8]
        intptr_t index = IndexFromPPLoadDisp8(pc + 3);
        const ObjectPool& pool = ObjectPool::Handle(code.object_pool());
        if (pool.InfoAt(index) == ObjectPool::kTaggedObject) {
          *obj = pool.ObjectAt(index);
          return true;
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

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
