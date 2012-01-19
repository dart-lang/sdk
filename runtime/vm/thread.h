// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_H_
#define VM_THREAD_H_

#include "platform/assert.h"
#include "platform/thread.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/isolate.h"

namespace dart {

class MutexLocker : public StackResource {
 public:
  explicit MutexLocker(Mutex* mutex) :
    StackResource(Isolate::Current()),
    mutex_(mutex) {
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


class MonitorLocker : public StackResource {
 public:
  explicit MonitorLocker(Monitor* monitor)
      : StackResource(Isolate::Current()),
        monitor_(monitor) {
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


#endif  // VM_THREAD_H_
