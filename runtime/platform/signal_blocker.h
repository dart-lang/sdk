// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef PLATFORM_SIGNAL_BLOCKER_H_
#define PLATFORM_SIGNAL_BLOCKER_H_

#include "platform/globals.h"

#if defined(TARGET_OS_WINDOWS)
#error Do not include this file on Windows.
#endif

#include <signal.h>  // NOLINT

namespace dart {

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


// The definition below is copied from Linux and adapted to avoid lint
// errors (type long int changed to intptr_t and do/while split on
// separate lines with body in {}s) and to also block signals.
#define TEMP_FAILURE_RETRY(expression)                                         \
    ({ ThreadSignalBlocker tsb(SIGPROF);                                       \
       intptr_t __result;                                                      \
       do {                                                                    \
         __result = (expression);                                              \
       } while ((__result == -1L) && (errno == EINTR));                        \
       __result; })

// This is a version of TEMP_FAILURE_RETRY which does not use the value
// returned from the expression.
#define VOID_TEMP_FAILURE_RETRY(expression)                                    \
    (static_cast<void>(TEMP_FAILURE_RETRY(expression)))

// This macro can be used to insert checks that a call is made, that
// was expected to not return EINTR, but did it anyway.
#define NO_RETRY_EXPECTED(expression)                                          \
    ({ intptr_t __result = (expression);                                       \
       if (__result == -1L && errno == EINTR) {                                \
         FATAL("Unexpected EINTR errno");                                      \
       }                                                                       \
       __result; })

#define VOID_NO_RETRY_EXPECTED(expression)                                     \
    (static_cast<void>(NO_RETRY_EXPECTED(expression)))

// Define to check in debug mode, if a signal is currently being blocked.
#define CHECK_IS_BLOCKING(signal)                                              \
    ({ sigset_t signal_mask;                                                   \
       int __r = pthread_sigmask(SIG_BLOCK, NULL, &signal_mask);               \
       USE(__r);                                                               \
       ASSERT(__r == 0);                                                       \
       sigismember(&signal_mask, signal); })                                   \


// Versions of the above, that does not enter a signal blocking scope. Use only
// when a signal blocking scope is entered manually.
#define TEMP_FAILURE_RETRY_NO_SIGNAL_BLOCKER(expression)                       \
    ({ intptr_t __result;                                                      \
       ASSERT(CHECK_IS_BLOCKING(SIGPROF));                                     \
       do {                                                                    \
         __result = (expression);                                              \
       } while ((__result == -1L) && (errno == EINTR));                        \
       __result; })

#define VOID_TEMP_FAILURE_RETRY_NO_SIGNAL_BLOCKER(expression)                  \
    (static_cast<void>(TEMP_FAILURE_RETRY_NO_SIGNAL_BLOCKER(expression)))

}  // namespace dart

#endif  // PLATFORM_SIGNAL_BLOCKER_H_
