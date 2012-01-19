// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_THREAD_H_
#define BIN_THREAD_H_

#include "platform/assert.h"
#include "platform/thread.h"

class MutexLocker  {
 public:
  explicit MutexLocker(dart::Mutex* mutex) : mutex_(mutex) {
    ASSERT(mutex != NULL);
    mutex_->Lock();
  }

  virtual ~MutexLocker() {
    mutex_->Unlock();
  }

 private:
  dart::Mutex* const mutex_;

  DISALLOW_COPY_AND_ASSIGN(MutexLocker);
};


class MonitorLocker {
 public:
  explicit MonitorLocker(dart::Monitor* monitor) : monitor_(monitor) {
    ASSERT(monitor != NULL);
    monitor_->Enter();
  }

  virtual ~MonitorLocker() {
    monitor_->Exit();
  }

  dart::Monitor::WaitResult Wait(int64_t millis = dart::Monitor::kNoTimeout) {
    return monitor_->Wait(millis);
  }

  void Notify() {
    monitor_->Notify();
  }

  void NotifyAll() {
    monitor_->NotifyAll();
  }

 private:
  dart::Monitor* const monitor_;

  DISALLOW_COPY_AND_ASSIGN(MonitorLocker);
};

#endif  // BIN_THREAD_H_
