// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_ARM64)

#include "vm/runtime_entry.h"

#include "vm/assembler.h"
#include "vm/simulator.h"
#include "vm/stub_code.h"

namespace dart {

#define __ assembler->

void RuntimeEntry::Call(Assembler* assembler, intptr_t argument_count) const {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM64
