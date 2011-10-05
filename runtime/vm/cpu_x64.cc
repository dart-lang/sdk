// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/globals.h"

#if defined(TARGET_ARCH_X64)

#include "vm/cpu.h"

namespace dart {

void CPU::FlushICache(uword start, uword size) {
  // Nothing to be done here.
}


void CPU::JumpToExceptionHandler(uword pc,
                                 uword sp,
                                 uword fp,
                                 const Instance& exception_object,
                                 const Instance& stacktrace_object) {
  UNIMPLEMENTED();
}


void CPU::JumpToUnhandledExceptionHandler(
    uword pc,
    uword sp,
    uword fp,
    const UnhandledException& unhandled_exception) {
  UNIMPLEMENTED();
}


const char* CPU::Id() {
  return "x64";
}

}  // namespace dart

#endif  // defined TARGET_ARCH_X64
