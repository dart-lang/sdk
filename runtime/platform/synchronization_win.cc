// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT
#if defined(DART_HOST_OS_WINDOWS) && !defined(DART_USE_ABSL)

#include "platform/synchronization.h"

#include <process.h>  // NOLINT

#include "platform/address_sanitizer.h"
#include "platform/assert.h"
#include "platform/safe_stack.h"

namespace dart {

Mutex::Mutex() {
  InitializeSRWLock(&mutex_);
}

Mutex::~Mutex() {}

void Mutex::Lock() {
  DEBUG_ASSERT(!DisallowMutexLockingScope::is_active());

  AcquireSRWLockExclusive(&mutex_);
  owner_.Acquire();
}

bool Mutex::TryLock() {
  DEBUG_ASSERT(!DisallowMutexLockingScope::is_active());

  if (TryAcquireSRWLockExclusive(&mutex_) != 0) {
    owner_.Acquire();
    return true;
  }
  return false;
}

void Mutex::Unlock() {
  owner_.Release();
  ReleaseSRWLockExclusive(&mutex_);
}

ConditionVariable::ConditionVariable() {
  InitializeConditionVariable(&cv_);
}

ConditionVariable::~ConditionVariable() {}

ConditionVariable::WaitResult ConditionVariable::Wait(Mutex* mutex,
                                                      int64_t timeout_millis) {
  mutex->owner_.Release();
  Monitor::WaitResult retval = kNotified;
  if (timeout_millis == kNoTimeout) {
    SleepConditionVariableSRW(&cv_, &mutex->mutex_, INFINITE, 0);
  } else {
    // Wait for the given period of time for a Notify or a NotifyAll
    // event.
    if (!SleepConditionVariableSRW(&cv_, &mutex->mutex_, timeout_millis, 0)) {
      ASSERT(GetLastError() == ERROR_TIMEOUT);
      retval = kTimedOut;
    }
  }
  mutex->owner_.Acquire();
  return retval;
}

ConditionVariable::WaitResult ConditionVariable::WaitMicros(Mutex* mutex,
                                                            int64_t micros) {
  // TODO(johnmccutchan): Investigate sub-millisecond sleep times on Windows.
  int64_t millis = micros / kMicrosecondsPerMillisecond;
  if ((millis * kMicrosecondsPerMillisecond) < micros) {
    // We've been asked to sleep for a fraction of a millisecond,
    // this isn't supported on Windows. Bumps milliseconds up by one
    // so that we never return too early. We likely return late though.
    millis += 1;
  }
  return Wait(mutex, millis);
}

void ConditionVariable::Notify() {
  WakeConditionVariable(&cv_);
}

void ConditionVariable::NotifyAll() {
  WakeAllConditionVariable(&cv_);
}

}  // namespace dart

#endif  // defined(DART_HOST_OS_WINDOWS) && !defined(DART_USE_ABSL)
