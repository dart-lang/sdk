// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_SIGNAL_BLOCKER_H_
#define BIN_SIGNAL_BLOCKER_H_

#include "platform/globals.h"

#if defined(TARGET_OS_WINDOWS)
#error Do not include this file on Windows.
#endif

#include <signal.h>  // NOLINT

#include "platform/thread.h"

namespace dart {
namespace bin {

class ThreadSignalBlocker {
 public:
  explicit ThreadSignalBlocker(int sig) {
    sigset_t signal_mask;
    sigemptyset(&signal_mask);
    sigaddset(&signal_mask, sig);
    // Add sig to signal mask.
    int r = pthread_sigmask(SIG_BLOCK, &signal_mask, &old);
    USE(r);
    ASSERT(r == 0);
  }

  ThreadSignalBlocker(int sigs_count, const int sigs[]) {
    sigset_t signal_mask;
    sigemptyset(&signal_mask);
    for (int i = 0; i < sigs_count; i++) {
      sigaddset(&signal_mask, sigs[i]);
    }
    // Add sig to signal mask.
    int r = pthread_sigmask(SIG_BLOCK, &signal_mask, &old);
    USE(r);
    ASSERT(r == 0);
  }

  ~ThreadSignalBlocker() {
    // Restore signal mask.
    int r = pthread_sigmask(SIG_SETMASK, &old, NULL);
    USE(r);
    ASSERT(r == 0);
  }

 private:
  sigset_t old;
};


#define TEMP_FAILURE_RETRY_BLOCK_SIGNALS(expression)                           \
    ({ ThreadSignalBlocker tsb(SIGPROF);                                       \
       intptr_t __result;                                                      \
       do {                                                                    \
         __result = (expression);                                              \
       } while ((__result == -1L) && (errno == EINTR));                        \
       __result; })

#define VOID_TEMP_FAILURE_RETRY_BLOCK_SIGNALS(expression)                      \
    (static_cast<void>(TEMP_FAILURE_RETRY_BLOCK_SIGNALS(expression)))

}  // namespace bin
}  // namespace dart

#endif  // BIN_SIGNAL_BLOCKER_H_
