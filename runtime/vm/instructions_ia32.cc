// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_IA32.
#if defined(TARGET_ARCH_IA32)

#include "vm/instructions.h"
#include "vm/instructions_ia32.h"

#include "vm/cpu.h"
#include "vm/object.h"

namespace dart {

bool DecodeLoadObjectFromPoolOrThread(uword pc, const Code& code, Object* obj) {
  ASSERT(code.ContainsInstructionAt(pc));
  return false;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_IA32
