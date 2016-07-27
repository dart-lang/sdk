// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include "platform/globals.h"
#include "vm/os.h"

namespace dart {

// Exit with a failure code when we miss an EXPECT check.
static void failed_exit(void) {
  exit(255);
}

void DynamicAssertionHelper::Fail(const char* format, ...) {
  // Take only the last 1KB of the file name if it is longer.
  const intptr_t file_len = strlen(file_);
  const intptr_t file_offset = (file_len > (1 * KB)) ? file_len - (1 * KB) : 0;
  const char* file = file_ + file_offset;

  // Print the file and line number into the buffer.
  char buffer[4 * KB];
  intptr_t file_and_line_length =
      snprintf(buffer, sizeof(buffer), "%s: %d: error: ", file, line_);

  // Print the error message into the buffer.
  va_list arguments;
  va_start(arguments, format);
  vsnprintf(buffer + file_and_line_length,
            sizeof(buffer) - file_and_line_length,
            format,
            arguments);
  va_end(arguments);

  // Print the buffer on stderr and/or syslog.
  OS::PrintErr("%s\n", buffer);

  // In case of failed assertions, abort right away. Otherwise, wait
  // until the program is exiting before producing a non-zero exit
  // code through abort.
  // TODO(5411324): replace std::abort with OS::Abort so that we can handle
  // restoring of signal handlers before aborting.
  if (kind_ == ASSERT) {
    OS::Abort();
  }
  static bool failed = false;
  if (!failed) {
    atexit(&failed_exit);
  }
  failed = true;
}

}  // namespace dart
