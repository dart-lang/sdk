// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

#if defined(TARGET_ARCH_MIPS)

#if defined(HOST_ARCH_MIPS)
#include <sys/syscall.h>  /* NOLINT */
#include <unistd.h>  /* NOLINT */
#endif

#include "vm/cpu.h"

namespace dart {

void CPU::FlushICache(uword start, uword size) {
  UNIMPLEMENTED();
}


const char* CPU::Id() {
  return "mips";
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
