// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT

#if defined(DART_USE_ABSL)

#include "platform/synchronization.h"

#include "platform/assert.h"
#include "platform/utils.h"

namespace dart {

Mutex::Mutex() {}

Mutex::~Mutex() {}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Mutex::Lock() {
  mutex_.Lock();
  owner_.Acquire();
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
bool Mutex::TryLock() {
  if (!mutex_.TryLock()) {
    return false;
  }
  owner_.Acquire();
  return true;
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void Mutex::Unlock() {
  owner_.Release();
  mutex_.Unlock();
}

ConditionVariable::ConditionVariable() {}

ConditionVariable::~ConditionVariable() {}

ABSL_NO_THREAD_SAFETY_ANALYSIS
ConditionVariable::WaitResult ConditionVariable::Wait(Mutex* mutex,
                                                      int64_t timeout_millis) {
  static_assert(kNoTimeout * kMicrosecondsPerMillisecond == kNoTimeout);
  return WaitMicros(mutex, timeout_millis * kMicrosecondsPerMillisecond);
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
ConditionVariable::WaitResult ConditionVariable::WaitMicros(
    Mutex* mutex,
    int64_t timeout_micros) {
  mutex->owner_.Release();
  Monitor::WaitResult retval = kNotified;
  if (timeout_micros == kNoTimeout) {
    // Wait forever.
    cv_.Wait(&mutex->mutex_);
  } else {
    if (cv_.WaitWithTimeout(&mutex->mutex_,
                            absl::Microseconds(timeout_micros))) {
      retval = kTimedOut;
    }
  }
  mutex->owner_.Acquire();
  return retval;
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void ConditionVariable::Notify() {
  cv_.Signal();
}

ABSL_NO_THREAD_SAFETY_ANALYSIS
void ConditionVariable::NotifyAll() {
  cv_.SignalAll();
}

}  // namespace dart

#endif  // defined(DART_USE_ABSL)
