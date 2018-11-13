// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_MACOS)

#include "platform/utils.h"

namespace dart {

char* Utils::StrNDup(const char* s, intptr_t n) {
// strndup has only been added to Mac OS X in 10.7. We are supplying
// our own copy here if needed.
#if !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) ||                 \
    __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ <= 1060
  intptr_t len = strlen(s);
  if ((n < 0) || (len < 0)) {
    return NULL;
  }
  if (n < len) {
    len = n;
  }
  char* result = reinterpret_cast<char*>(malloc(len + 1));
  if (result == NULL) {
    return NULL;
  }
  result[len] = '\0';
  return reinterpret_cast<char*>(memmove(result, s, len));
#else   // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
  return strndup(s, n);
#endif  // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
}

intptr_t Utils::StrNLen(const char* s, intptr_t n) {
// strnlen has only been added to Mac OS X in 10.7. We are supplying
// our own copy here if needed.
#if !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) ||                 \
    __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ <= 1060
  intptr_t len = 0;
  while ((len <= n) && (*s != '\0')) {
    s++;
    len++;
  }
  return len;
#else   // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
  return strnlen(s, n);
#endif  // !defined(__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__) || ...
}

int Utils::SNPrint(char* str, size_t size, const char* format, ...) {
  va_list args;
  va_start(args, format);
  int retval = VSNPrint(str, size, format, args);
  va_end(args);
  return retval;
}

int Utils::VSNPrint(char* str, size_t size, const char* format, va_list args) {
  int retval = vsnprintf(str, size, format, args);
  if (retval < 0) {
    FATAL1("Fatal error in Utils::VSNPrint with format '%s'", format);
  }
  return retval;
}

}  // namespace dart

#endif  // defined(HOST_OS_MACOS)
