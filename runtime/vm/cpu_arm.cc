// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

#if defined(TARGET_ARCH_ARM)

#if defined(HOST_ARCH_ARM)
#include <sys/syscall.h>  /* NOLINT */
#include <unistd.h>  /* NOLINT */
#endif

#include "vm/cpu.h"

namespace dart {

void CPU::FlushICache(uword start, uword size) {
#if defined(HOST_ARCH_ARM)
  // Nothing to do. Flushing no instructions.
  if (size == 0) {
    return;
  }

  // ARM recommends using the gcc intrinsic __clear_cache on Linux, and the
  // library call cacheflush from unistd.h on Android:
  // blogs.arm.com/software-enablement/141-caches-and-self-modifying-code/
  #if defined(__linux__) && !defined(ANDROID)
    extern void __clear_cache(char*, char*);
    char* beg = reinterpret_cast<char*>(start);
    char* end = reinterpret_cast<char*>(start + size);
    ::__clear_cache(beg, end);
  #elif defined(ANDROID)
    cacheflush(start, start + size, 0);
  #else
    #error FlushICache only tested/supported on Linux and Android
  #endif

#endif
}


const char* CPU::Id() {
  return
#if !defined(HOST_ARCH_ARM)
  "sim"
#endif  // !defined(HOST_ARCH_ARM)
  "arm";
}

}  // namespace dart

#endif  // defined TARGET_ARCH_ARM
