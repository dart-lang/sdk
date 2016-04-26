// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"
#if defined(TARGET_ARCH_DBC)

#include "vm/cpu.h"


namespace dart {


void CPU::FlushICache(uword start, uword size) {
  // Nothing to do.
}


const char* CPU::Id() {
  return "dbc";
}


}  // namespace dart

#endif  // defined TARGET_ARCH_DBC
