// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_PLATFORM_LOCKERS_H_
#define RUNTIME_PLATFORM_LOCKERS_H_

#include "platform/assert.h"
#include "platform/synchronization.h"

namespace dart {
namespace platform {

class MutexLocker {
 public:
  explicit MutexLocker(Mutex* mutex) : mutex_(mutex) {
    ASSERT(mutex != nullptr);
    mutex_->Lock();
  }

  virtual ~MutexLocker() { mutex_->Unlock(); }

 private:
  Mutex* const mutex_;

  DISALLOW_COPY_AND_ASSIGN(MutexLocker);
};

class MonitorLocker {
 public:
  explicit MonitorLocker(Monitor* monitor) : monitor_(monitor) {
    ASSERT(monitor != nullptr);
    monitor_->Enter();
  }

  virtual ~MonitorLocker() { monitor_->Exit(); }

  Monitor::WaitResult Wait(int64_t millis = Monitor::kNoTimeout) {
    return monitor_->Wait(millis);
  }

  void Notify() { monitor_->Notify(); }

  void NotifyAll() { monitor_->NotifyAll(); }

 private:
  Monitor* const monitor_;

  DISALLOW_COPY_AND_ASSIGN(MonitorLocker);
};

}  // namespace platform
}  // namespace dart

#endif  // RUNTIME_PLATFORM_LOCKERS_H_
