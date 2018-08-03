// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_LINUX)

#include "platform/utils.h"

namespace dart {

char* Utils::StrNDup(const char* s, intptr_t n) {
  return strndup(s, n);
}

intptr_t Utils::StrNLen(const char* s, intptr_t n) {
  return strnlen(s, n);
}

int Utils::SNPrint(char* str, size_t size, const char* format, ...) {
  va_list args;
  va_start(args, format);
  int retval = VSNPrint(str, size, format, args);
  va_end(args);
  return retval;
}

int Utils::VSNPrint(char* str, size_t size, const char* format, va_list args) {
  MSAN_UNPOISON(str, size);
  int retval = vsnprintf(str, size, format, args);
  if (retval < 0) {
    FATAL1("Fatal error in Utils::VSNPrint with format '%s'", format);
  }
  return retval;
}

}  // namespace dart

#endif  // defined(HOST_OS_LINUX)
