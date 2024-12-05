// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_SYNCHRONIZATION_H_
#define RUNTIME_PLATFORM_SYNCHRONIZATION_H_

#include "platform/allocation.h"
#include "platform/threads.h"

#if defined(DART_USE_ABSL)
#include "third_party/absl/synchronization/mutex.h"
#endif

namespace dart {

#if defined(DART_USE_ABSL)
using MutexImpl = absl::Mutex;
using ConditionVariableImpl = absl::CondVar;
#elif defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_FUCHSIA) ||          \
    defined(DART_HOST_OS_MACOS) || defined(DART_HOST_OS_ANDROID)
using MutexImpl = pthread_mutex_t;
using ConditionVariableImpl = pthread_cond_t;
#elif defined(DART_HOST_OS_WINDOWS)
using MutexImpl = SRWLOCK;
using ConditionVariableImpl = CONDITION_VARIABLE;
#else
#error Unknown target os.
#endif

// Mark when we are running in a signal handler (Linux, Android) or with a
// suspended thread (Windows, Mac, Fuchia). During this time, we cannot take
// locks.
class DisallowMutexLockingScope : public ValueObject {
#if defined(DEBUG)
 public:
  DisallowMutexLockingScope() {
    ASSERT(!is_active_);
    is_active_ = true;
  }

  ~DisallowMutexLockingScope() { is_active_ = false; }

  static bool is_active() { return is_active_; }

 private:
  static inline thread_local bool is_active_ = false;
#endif  // DEBUG
};

class Mutex {
 public:
  Mutex();
  ~Mutex();

  bool IsOwnedByCurrentThread() const {
    return owner_.IsOwnedByCurrentThread();
  }

  void Lock();
  bool TryLock();  // Returns false if lock is busy and locking failed.
  void Unlock();

 private:
  MutexImpl mutex_;
  platform::ThreadBoundResource owner_;

  friend class ConditionVariable;
  DISALLOW_COPY_AND_ASSIGN(Mutex);
};

class ConditionVariable {
 public:
  enum WaitResult { kNotified, kTimedOut };
  static constexpr int64_t kNoTimeout = 0;

  ConditionVariable();
  ~ConditionVariable();

  WaitResult Wait(Mutex* mutex, int64_t timeout_millis = kNoTimeout);

  WaitResult WaitMicros(Mutex* mutex, int64_t timeout_micros = kNoTimeout);

  void Notify();
  void NotifyAll();

 private:
  ConditionVariableImpl cv_;

  DISALLOW_COPY_AND_ASSIGN(ConditionVariable);
};

class Monitor {
 public:
  using WaitResult = ConditionVariable::WaitResult;
  static constexpr WaitResult kNotified = ConditionVariable::kNotified;
  static constexpr WaitResult kTimedOut = ConditionVariable::kTimedOut;

  static constexpr int64_t kNoTimeout = ConditionVariable::kNoTimeout;

  Monitor() {}
  ~Monitor() {}

  bool IsOwnedByCurrentThread() const {
    return mutex_.IsOwnedByCurrentThread();
  }

  bool TryEnter() { return mutex_.TryLock(); }
  void Enter() { return mutex_.Lock(); }
  void Exit() { return mutex_.Unlock(); }

  // Wait for notification or timeout.
  WaitResult Wait(int64_t timeout_millis) {
    return cv_.Wait(&mutex_, timeout_millis);
  }

  WaitResult WaitMicros(int64_t timeout_micros) {
    return cv_.WaitMicros(&mutex_, timeout_micros);
  }

  // Notify waiting threads.
  void Notify() { cv_.Notify(); }

  void NotifyAll() { cv_.NotifyAll(); }

 private:
  Mutex mutex_;  // OS-specific data.
  ConditionVariable cv_;

  DISALLOW_COPY_AND_ASSIGN(Monitor);
};

}  // namespace dart

#endif  // RUNTIME_PLATFORM_SYNCHRONIZATION_H_
