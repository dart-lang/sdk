// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_DBC)

#include "vm/runtime_entry.h"

#include "vm/compiler/assembler/assembler.h"
#include "vm/simulator.h"
#include "vm/stub_code.h"

namespace dart {

uword RuntimeEntry::GetEntryPoint() const {
  return reinterpret_cast<uword>(function());
}

void RuntimeEntry::Call(Assembler* assembler, intptr_t argument_count) const {
  UNIMPLEMENTED();
}

}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
