// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_MIPS.
#if defined(TARGET_ARCH_MIPS)

#include "vm/instructions.h"
#include "vm/object.h"

namespace dart {

bool InstructionPattern::TestBytesWith(const int* data, int num_bytes) const {
  UNIMPLEMENTED();
  return false;
}


uword CallOrJumpPattern::TargetAddress() const {
  UNIMPLEMENTED();
  return 0;
}


void CallOrJumpPattern::SetTargetAddress(uword target) const {
  UNIMPLEMENTED();
}


const int* CallPattern::pattern() const {
  UNIMPLEMENTED();
  return NULL;
}


const int* JumpPattern::pattern() const {
  UNIMPLEMENTED();
  return NULL;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS

