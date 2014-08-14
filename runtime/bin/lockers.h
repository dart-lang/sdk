// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_LOCKERS_H_
#define BIN_LOCKERS_H_

#include "bin/thread.h"
#include "platform/assert.h"


namespace dart {
namespace bin {

class MutexLocker  {
 public:
  explicit MutexLocker(Mutex* mutex) : mutex_(mutex) {
    ASSERT(mutex != NULL);
    mutex_->Lock();
  }

  virtual ~MutexLocker() {
    mutex_->Unlock();
  }

 private:
  Mutex* const mutex_;

  DISALLOW_COPY_AND_ASSIGN(MutexLocker);
};


class MonitorLocker {
 public:
  explicit MonitorLocker(Monitor* monitor) : monitor_(monitor) {
    ASSERT(monitor != NULL);
    monitor_->Enter();
  }

  virtual ~MonitorLocker() {
    monitor_->Exit();
  }

  Monitor::WaitResult Wait(int64_t millis = Monitor::kNoTimeout) {
    return monitor_->Wait(millis);
  }

  void Notify() {
    monitor_->Notify();
  }

  void NotifyAll() {
    monitor_->NotifyAll();
  }

 private:
  Monitor* const monitor_;

  DISALLOW_COPY_AND_ASSIGN(MonitorLocker);
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_LOCKERS_H_
