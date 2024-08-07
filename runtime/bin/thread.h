// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_THREAD_H_
#define RUNTIME_BIN_THREAD_H_

#include "platform/globals.h"
#include "platform/synchronization.h"

namespace dart {
namespace bin {

class Thread {
 public:
  typedef void (*ThreadStartFunction)(uword parameter);

  // Start a thread running the specified function. Returns 0 if the
  // thread started successfully and a system specific error code if
  // the thread failed to start.
  static int Start(const char* name,
                   ThreadStartFunction function,
                   uword parameters);

  static intptr_t GetMaxStackSize();

  static void InitOnce();

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Thread);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_THREAD_H_
