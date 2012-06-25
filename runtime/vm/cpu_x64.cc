// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

#if defined(TARGET_ARCH_X64)

#include "vm/cpu.h"

#include "vm/constants_x64.h"
#include "vm/heap.h"
#include "vm/isolate.h"
#include "vm/object.h"

namespace dart {

void CPU::FlushICache(uword start, uword size) {
  // Nothing to be done here.
}


const char* CPU::Id() {
  return "x64";
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
