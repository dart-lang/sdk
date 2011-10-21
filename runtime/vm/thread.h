// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_H_
#define VM_THREAD_H_

#include "vm/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"

// Declare the OS-specific types ahead of defining the generic classes.
#if defined(TARGET_OS_LINUX)
#include "vm/thread_linux.h"
#elif defined(TARGET_OS_MACOS)
#include "vm/thread_macos.h"
#elif defined(TARGET_OS_WINDOWS)
#include "vm/thread_win.h"
#else
#error Unknown target os.
#endif

namespace dart {

class Thread {
 public:
  // Function to be called on thread start.
  typedef void (*ThreadStartFunction) (uword parameter);

  // TODO(iposva): Define the proper interface for spawning and killing threads.
  Thread(ThreadStartFunction function, uword parameters);
  ~Thread();

 private:
  ThreadData data_;

  DISALLOW_COPY_AND_ASSIGN(Thread);
};


class Mutex {
 public:
  Mutex();
  ~Mutex();

  void Lock();
  bool TryLock();
  void Unlock();

 private:
  MutexData data_;

  DISALLOW_COPY_AND_ASSIGN(Mutex);
};


class Monitor {
 public:
  enum WaitResult {
    kNotified,
    kTimedOut
  };

  static const int64_t kNoTimeout = 0;

  Monitor();
  ~Monitor();

  void Enter();
  void Exit();

  // Wait for notification or timeout.
  WaitResult Wait(int64_t millis);

  // Notify waiting threads.
  void Notify();
  void NotifyAll();

 private:
  MonitorData data_;  // OS-specific data.

  DISALLOW_COPY_AND_ASSIGN(Monitor);
};


class MutexLocker : public StackResource {
 public:
  explicit MutexLocker(Mutex* mutex) : StackResource(), mutex_(mutex) {
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
      : StackResource(),
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
