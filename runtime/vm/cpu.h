// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_CPU_H_
#define VM_CPU_H_

#include "vm/allocation.h"

namespace dart {

// Forward Declarations.
class Instance;
class UnhandledException;


class CPU : public AllStatic {
 public:
  static void FlushICache(uword start, uword size);
  static void JumpToExceptionHandler(uword pc,
                                     uword sp,
                                     uword fp,
                                     const Instance& exception_object,
                                     const Instance& stacktrace_object);
  static void JumpToUnhandledExceptionHandler(
      uword pc,
      uword sp,
      uword fp,
      const UnhandledException& unhandled_exception);
  static const char* Id();
};

}  // namespace dart

#endif  // VM_CPU_H_
