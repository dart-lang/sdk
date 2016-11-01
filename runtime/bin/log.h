// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_LOG_H_
#define RUNTIME_BIN_LOG_H_

#include <stdarg.h>

#include "platform/globals.h"

namespace dart {
namespace bin {

class Log {
 public:
  // Print formatted output for debugging.
  static void Print(const char* format, ...) PRINTF_ATTRIBUTE(1, 2) {
    va_list args;
    va_start(args, format);
    VPrint(format, args);
    va_end(args);
  }

  static void VPrint(const char* format, va_list args);

  static void PrintErr(const char* format, ...) PRINTF_ATTRIBUTE(1, 2) {
    va_list args;
    va_start(args, format);
    VPrintErr(format, args);
    va_end(args);
  }

  static void VPrintErr(const char* format, va_list args);

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Log);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_LOG_H_
