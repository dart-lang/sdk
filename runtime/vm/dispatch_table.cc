// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/dispatch_table.h"

#include "platform/assert.h"

namespace dart {

intptr_t DispatchTable::OriginElement() {
#if defined(TARGET_ARCH_X64)
  // Max negative byte offset / 8
  return 16;
#elif defined(TARGET_ARCH_ARM)
  // Max negative load offset / 4
  return 1023;
#elif defined(TARGET_ARCH_ARM64)
  // Max consecutive sub immediate value
  return 4096;
#else
  // No AOT on IA32
  UNREACHABLE();
  return 0;
#endif
}

intptr_t DispatchTable::LargestSmallOffset() {
#if defined(TARGET_ARCH_X64)
  // Origin + Max positive byte offset / 8
  return 31;
#elif defined(TARGET_ARCH_ARM)
  // Origin + Max positive load offset / 4
  return 2046;
#elif defined(TARGET_ARCH_ARM64)
  // Origin + Max consecutive add immediate value
  return 8192;
#else
  // No AOT on IA32
  UNREACHABLE();
  return 0;
#endif
}

const uword* DispatchTable::ArrayOrigin() const {
  return &array_.get()[OriginElement()];
}

}  // namespace dart
