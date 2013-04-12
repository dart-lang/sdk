// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

#if defined(TARGET_ARCH_MIPS)

#if defined(HOST_ARCH_MIPS)
#include <asm/cachectl.h> /* NOLINT */
#include <sys/syscall.h>  /* NOLINT */
#include <unistd.h>  /* NOLINT */
#endif

#include "vm/cpu.h"

namespace dart {

void CPU::FlushICache(uword start, uword size) {
#if defined(HOST_ARCH_MIPS)
  int res;
  // See http://www.linux-mips.org/wiki/Cacheflush_Syscall.
  res = syscall(__NR_cacheflush, start, size, ICACHE);
  ASSERT(res == 0);
#else  // defined(HOST_ARCH_MIPS)
  // When running in simulated mode we do not need to flush the ICache because
  // we are not running on the actual hardware.
#endif  // defined(HOST_ARCH_MIPS)
}


const char* CPU::Id() {
  return "mips";
}

}  // namespace dart

#endif  // defined TARGET_ARCH_MIPS
