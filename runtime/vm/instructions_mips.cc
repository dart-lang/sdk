// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/constants_mips.h"
#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

CallPattern::CallPattern(uword pc, const Code& code)
    : end_(reinterpret_cast<uword*>(pc)),
      pool_index_(DecodePoolIndex()),
      object_pool_(Array::Handle(code.ObjectPool())) { }


uword CallPattern::Back(int n) const {
  ASSERT(n > 0);
  return *(end_ - n);
}


int CallPattern::DecodePoolIndex() {
  UNIMPLEMENTED();
  return 0;
}


uword CallPattern::TargetAddress() const {
  UNIMPLEMENTED();
  return 0;
}


void CallPattern::SetTargetAddress(uword target_address) const {
  UNIMPLEMENTED();
}


JumpPattern::JumpPattern(uword pc) : pc_(pc) { }


bool JumpPattern::IsValid() const {
  UNIMPLEMENTED();
  return false;
}


uword JumpPattern::TargetAddress() const {
  UNIMPLEMENTED();
  return 0;
}


void JumpPattern::SetTargetAddress(uword target_address) const {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS

