// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_LOCKERS_H_
#define VM_LOCKERS_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/isolate.h"
#include "vm/thread.h"

namespace dart {

class MutexLocker : public ValueObject {
 public:
  explicit MutexLocker(Mutex* mutex) : mutex_(mutex) {
    ASSERT(mutex != NULL);
    // TODO(iposva): Consider adding a no GC scope here.
    mutex_->Lock();
  }

  virtual ~MutexLocker() {
    mutex_->Unlock();
    // TODO(iposva): Consider decrementing the no GC scope here.
  }

 private:
  Mutex* const mutex_;

  DISALLOW_COPY_AND_ASSIGN(MutexLocker);
};


class MonitorLocker : public ValueObject {
 public:
  explicit MonitorLocker(Monitor* monitor) : monitor_(monitor) {
    ASSERT(monitor != NULL);
    // TODO(iposva): Consider adding a no GC scope here.
    monitor_->Enter();
  }

  virtual ~MonitorLocker() {
    monitor_->Exit();
    // TODO(iposva): Consider decrementing the no GC scope here.
  }

  Monitor::WaitResult Wait(int64_t millis = Monitor::kNoTimeout) {
    return monitor_->Wait(millis);
  }

  Monitor::WaitResult WaitMicros(int64_t micros = Monitor::kNoTimeout) {
    return monitor_->WaitMicros(micros);
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

}  // namespace dart


#endif  // VM_LOCKERS_H_
