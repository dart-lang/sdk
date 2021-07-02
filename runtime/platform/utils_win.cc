// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)

#include <io.h>  // NOLINT
#include "platform/allocation.h"
#include "platform/utils.h"

namespace dart {

char* Utils::StrNDup(const char* s, intptr_t n) {
  intptr_t len = strlen(s);
  if ((n < 0) || (len < 0)) {
    return NULL;
  }
  if (n < len) {
    len = n;
  }
  char* result = reinterpret_cast<char*>(malloc(len + 1));
  result[len] = '\0';
  return reinterpret_cast<char*>(memmove(result, s, len));
}

char* Utils::StrDup(const char* s) {
  return _strdup(s);
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
  if (str == NULL || size == 0) {
    int retval = _vscprintf(format, args);
    if (retval < 0) {
      FATAL1("Fatal error in Utils::VSNPrint with format '%s'", format);
    }
    return retval;
  }
  va_list args_copy;
  va_copy(args_copy, args);
  int written = _vsnprintf(str, size, format, args_copy);
  va_end(args_copy);
  if (written < 0) {
    // _vsnprintf returns -1 if the number of characters to be written is
    // larger than 'size', so we call _vscprintf which returns the number
    // of characters that would have been written.
    va_list args_retry;
    va_copy(args_retry, args);
    written = _vscprintf(format, args_retry);
    if (written < 0) {
      FATAL1("Fatal error in Utils::VSNPrint with format '%s'", format);
    }
    va_end(args_retry);
  }
  // Make sure to zero-terminate the string if the output was
  // truncated or if there was an error.
  // The static cast is safe here as we have already determined that 'written'
  // is >= 0.
  if (static_cast<size_t>(written) >= size) {
    str[size - 1] = '\0';
  }
  return written;
}

int Utils::Close(int fildes) {
  return _close(fildes);
}
size_t Utils::Read(int filedes, void* buf, size_t nbyte) {
  return _read(filedes, buf, nbyte);
}
int Utils::Unlink(const char* path) {
  return _unlink(path);
}

}  // namespace dart

#endif  // defined(HOST_OS_WINDOWS)
