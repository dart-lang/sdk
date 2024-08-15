// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"  // NOLINT

#if !defined(DART_USE_ABSL) &&                                                 \
    (defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_FUCHSIA) ||           \
     defined(DART_HOST_OS_MACOS) || defined(DART_HOST_OS_ANDROID))

#include "platform/synchronization.h"

#include <errno.h>  // NOLINT
#include <stdio.h>
#include <sys/time.h>  // NOLINT

#include "platform/utils.h"

namespace dart {

Mutex::Mutex() {
  pthread_mutexattr_t attr;
  int result = pthread_mutexattr_init(&attr);
  VALIDATE_PTHREAD_RESULT(result);

#if defined(DEBUG)
  result = pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK);
  VALIDATE_PTHREAD_RESULT(result);
#endif  // defined(DEBUG)

  result = pthread_mutex_init(&mutex_, &attr);
  // Verify that creating a pthread_mutex succeeded.
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_mutexattr_destroy(&attr);
  VALIDATE_PTHREAD_RESULT(result);
}

Mutex::~Mutex() {
  int result = pthread_mutex_destroy(&mutex_);
  // Verify that the pthread_mutex was destroyed.
  VALIDATE_PTHREAD_RESULT(result);
}

void Mutex::Lock() {
  DEBUG_ASSERT(!DisallowMutexLockingScope::is_active());

  int result = pthread_mutex_lock(&mutex_);
  // Specifically check for dead lock to help debugging.
  ASSERT(result != EDEADLK);
  ASSERT_PTHREAD_SUCCESS(result);  // Verify no other errors.
  owner_.Acquire();
}

bool Mutex::TryLock() {
  DEBUG_ASSERT(!DisallowMutexLockingScope::is_active());

  int result = pthread_mutex_trylock(&mutex_);
  // Return false if the lock is busy and locking failed.
  if (result == EBUSY) {
    return false;
  }
  ASSERT_PTHREAD_SUCCESS(result);  // Verify no other errors.
  owner_.Acquire();
  return true;
}

void Mutex::Unlock() {
  owner_.Release();
  int result = pthread_mutex_unlock(&mutex_);
  // Specifically check for wrong thread unlocking to aid debugging.
  ASSERT(result != EPERM);
  ASSERT_PTHREAD_SUCCESS(result);  // Verify no other errors.
}

ConditionVariable::ConditionVariable() {
  pthread_condattr_t cond_attr;
  int result = pthread_condattr_init(&cond_attr);
  VALIDATE_PTHREAD_RESULT(result);

#if !defined(DART_HOST_OS_MACOS)
  result = pthread_condattr_setclock(&cond_attr, CLOCK_MONOTONIC);
  VALIDATE_PTHREAD_RESULT(result);
#endif

  result = pthread_cond_init(&cv_, &cond_attr);
  VALIDATE_PTHREAD_RESULT(result);

  result = pthread_condattr_destroy(&cond_attr);
  VALIDATE_PTHREAD_RESULT(result);
}

ConditionVariable::~ConditionVariable() {
  int result = pthread_cond_destroy(&cv_);
  VALIDATE_PTHREAD_RESULT(result);
}

ConditionVariable::WaitResult ConditionVariable::Wait(Mutex* mutex,
                                                      int64_t millis) {
  static_assert(kNoTimeout * kMicrosecondsPerMillisecond == kNoTimeout);
  return WaitMicros(mutex, millis * kMicrosecondsPerMillisecond);
}

static int TimedWait(pthread_cond_t* cv,
                     pthread_mutex_t* mutex,
                     int64_t timeout_micros) {
  const int64_t secs = timeout_micros / kMicrosecondsPerSecond;
  const int64_t nanos = (timeout_micros - (secs * kMicrosecondsPerSecond)) *
                        kNanosecondsPerMicrosecond;

  struct timespec ts;
#if defined(DART_HOST_OS_MACOS)
  // On Mac OS X we can use non-portable pthread_cond_timedwait_relative_np
  // instead of computing timespec for the wakeup moment.
  ts.tv_sec = static_cast<int32_t>(
      Utils::Minimum(static_cast<int64_t>(kMaxInt32), secs));
  ts.tv_nsec = static_cast<long>(nanos);  // NOLINT (long used in timespec).
  return pthread_cond_timedwait_relative_np(cv, mutex, &ts);
#else
  // Otherwise we need to compute absolute timespec.
  int result = clock_gettime(CLOCK_MONOTONIC, &ts);
  if (result != 0) {
    return result;
  }

  ts.tv_sec += secs;
  ts.tv_nsec += nanos;
  if (ts.tv_nsec >= kNanosecondsPerSecond) {
    ts.tv_sec += 1;
    ts.tv_nsec -= kNanosecondsPerSecond;
  }

  return pthread_cond_timedwait(cv, mutex, &ts);
#endif
}

ConditionVariable::WaitResult ConditionVariable::WaitMicros(
    Mutex* mutex,
    int64_t timeout_micros) {
  mutex->owner_.Release();
  Monitor::WaitResult retval = kNotified;
  if (timeout_micros == kNoTimeout) {
    // Wait forever.
    int result = pthread_cond_wait(&cv_, &mutex->mutex_);
    VALIDATE_PTHREAD_RESULT(result);
  } else {
    int result = TimedWait(&cv_, &mutex->mutex_, timeout_micros);
    ASSERT((result == 0) || (result == ETIMEDOUT));
    if (result == ETIMEDOUT) {
      retval = kTimedOut;
    }
  }
  mutex->owner_.Acquire();
  return retval;
}

void ConditionVariable::Notify() {
  int result = pthread_cond_signal(&cv_);
  VALIDATE_PTHREAD_RESULT(result);
}

void ConditionVariable::NotifyAll() {
  int result = pthread_cond_broadcast(&cv_);
  VALIDATE_PTHREAD_RESULT(result);
}

}  // namespace dart

#endif  // !defined(DART_USE_ABSL) && (defined(DART_HOST_OS_LINUX) ||          \
        //                             defined(DART_HOST_OS_FUCHSIA) ||        \
        //                             defined(DART_HOST_OS_MACOS) ||          \
        //                             defined(DART_HOST_OS_ANDROID))
