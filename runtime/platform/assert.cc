// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "include/dart_api.h"
#include "platform/globals.h"
#include "platform/syslog.h"

namespace dart {

bool Expect::failed_ = false;

void DynamicAssertionHelper::Print(const char* format, va_list arguments) {
  // Take only the last 1KB of the file name if it is longer.
  const intptr_t file_len = strlen(file_);
  const intptr_t file_offset = (file_len > (1 * KB)) ? file_len - (1 * KB) : 0;
  const char* file = file_ + file_offset;

  // Print the file and line number into the buffer.
  char buffer[4 * KB];
  MSAN_UNPOISON(buffer, sizeof(buffer));
  intptr_t file_and_line_length =
      snprintf(buffer, sizeof(buffer), "%s: %d: error: ", file, line_);

  // Print the error message into the buffer.
  vsnprintf(buffer + file_and_line_length,
            sizeof(buffer) - file_and_line_length, format, arguments);

  // Print the buffer on stderr and/or syslog.
  Syslog::PrintErr("%s\n", buffer);
}

void Assert::Fail(const char* format, ...) {
  va_list arguments;
  va_start(arguments, format);
  Print(format, arguments);
  va_end(arguments);

  // Abort right away.
  Dart_DumpNativeStackTrace(NULL);
  Dart_PrepareToAbort();
  abort();
}

void Expect::Fail(const char* format, ...) {
  va_list arguments;
  va_start(arguments, format);
  Print(format, arguments);
  va_end(arguments);

  // Wait until the program is exiting before producing a non-zero exit
  // code through abort.
  failed_ = true;
}

}  // namespace dart
