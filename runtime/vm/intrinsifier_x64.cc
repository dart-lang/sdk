// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"  // Needed here to get TARGET_ARCH_X64.
#if defined(TARGET_ARCH_X64)

#include "vm/intrinsifier.h"

namespace dart {

bool Intrinsifier::Intrinsify(const Function& function, Assembler* assembler) {
  return false;
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
