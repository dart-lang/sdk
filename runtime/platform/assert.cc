// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"

#include <sstream>
#include <string>

#include "platform/globals.h"

namespace dart {

// Exit with a failure code when we miss an EXPECT check.
static void failed_exit(void) {
  exit(255);
}

void DynamicAssertionHelper::Fail(const char* format, ...) {
  std::ostringstream stream;
  stream << file_ << ":" << line_ << ": error: ";

  va_list arguments;
  va_start(arguments, format);
  char buffer[2 * KB];
  vsnprintf(buffer, sizeof(buffer), format, arguments);
  va_end(arguments);
  stream << buffer << std::endl;

  // Get the message from the string stream and dump it on stderr.
  std::string message = stream.str();
  fprintf(stderr, "%s", message.c_str());
  fflush(stderr);

  // In case of failed assertions, abort right away. Otherwise, wait
  // until the program is exiting before producing a non-zero exit
  // code through abort.
  // TODO(5411324): replace std::abort with OS::Abort so that we can handle
  // restoring of signal handlers before aborting.
  if (kind_ == ASSERT) {
    abort();
  }
  static bool failed = false;
  if (!failed) {
    atexit(&failed_exit);
  }
  failed = true;
}

}  // namespace dart
