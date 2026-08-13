// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/thread.h"

#include "platform/utils.h"

namespace dart {
namespace bin {

void Thread::Start(const char* name,
                   ThreadStartFunction function,
                   uword parameter) {
  int result = TryStart(name, function, parameter);
  if (result != 0) {
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL("Could not start thread %s: %d (%s)", name, result,
          Utils::StrError(result, error_buf, kBufferSize));
  }
}

}  // namespace bin
}  // namespace dart
