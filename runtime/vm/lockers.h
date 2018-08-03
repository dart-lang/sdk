// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_LOCKERS_H_
#define RUNTIME_VM_LOCKERS_H_

#include "platform/assert.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/isolate.h"
#include "vm/os_thread.h"

namespace dart {

const bool kNoSafepointScope = true;
const bool kDontAssertNoSafepointScope = false;

/*
 * Normal mutex locker :
 * This locker abstraction should only be used when the enclosing code can
 * not trigger a safepoint. In debug mode this class increments the
 * no_safepoint_scope_depth variable for the current thread when the lock is
 * taken and decrements it when the lock is released. NOTE: please do not use
 * the passed in mutex object independent of the locker class, For example the
 * code below will not assert correctly:
 *    {
 *      MutexLocker ml(m);
 *      ....
 *      m->Exit();
 *      ....
 *      m->Enter();
 *      ...
 *    }
 * Always use the locker object even when the lock needs to be released
 * temporarily, e.g:
 *    {
 *      MutexLocker ml(m);
 *      ....
 *      ml.Exit();
 *      ....
 *      ml.Enter();
 *      ...
 *    }
 */
class MutexLocker : public ValueObject {
 public:
  explicit MutexLocker(Mutex* mutex, bool no_safepoint_scope = true)
      : mutex_(mutex), no_safepoint_scope_(no_safepoint_scope) {
    ASSERT(mutex != NULL);
#if defined(DEBUG)
    if (no_safepoint_scope_) {
      Thread* thread = Thread::Current();
      if (thread != NULL) {
        thread->IncrementNoSafepointScopeDepth();
      } else {
        no_safepoint_scope_ = false;
      }
    }
#endif
    mutex_->Lock();
  }

  virtual ~MutexLocker() {
    mutex_->Unlock();
#if defined(DEBUG)
    if (no_safepoint_scope_) {
      Thread::Current()->DecrementNoSafepointScopeDepth();
    }
#endif
  }

  void Lock() const {
#if defined(DEBUG)
    if (no_safepoint_scope_) {
      Thread::Current()->IncrementNoSafepointScopeDepth();
    }
#endif
    mutex_->Lock();
  }
  void Unlock() const {
    mutex_->Unlock();
#if defined(DEBUG)
    if (no_safepoint_scope_) {
      Thread::Current()->DecrementNoSafepointScopeDepth();
    }
#endif
  }

 private:
  Mutex* const mutex_;
  bool no_safepoint_scope_;

  DISALLOW_COPY_AND_ASSIGN(MutexLocker);
};

/*
 * Normal monitor locker :
 * This locker abstraction should only be used when the enclosing code can
 * not trigger a safepoint. In debug mode this class increments the
 * no_safepoint_scope_depth variable for the current thread when the lock is
 * taken and decrements it when the lock is released. NOTE: please do not use
 * the passed in mutex object independent of the locker class, For example the
 * code below will not assert correctly:
 *    {
 *      MonitorLocker ml(m);
 *      ....
 *      m->Exit();
 *      ....
 *      m->Enter();
 *      ...
 *    }
 * Always use the locker object even when the lock needs to be released
 * temporarily, e.g:
 *    {
 *      MonitorLocker ml(m);
 *      ....
 *      ml.Exit();
 *      ....
 *      ml.Enter();
 *      ...
 *    }
 */
class MonitorLocker : public ValueObject {
 public:
  explicit MonitorLocker(Monitor* monitor, bool no_safepoint_scope = true)
      : monitor_(monitor), no_safepoint_scope_(no_safepoint_scope) {
    ASSERT(monitor != NULL);
#if defined(DEBUG)
    if (no_safepoint_scope_) {
      Thread* thread = Thread::Current();
      if (thread != NULL) {
        thread->IncrementNoSafepointScopeDepth();
      } else {
        no_safepoint_scope_ = false;
      }
    }
#endif
    monitor_->Enter();
  }

  virtual ~MonitorLocker() {
    monitor_->Exit();
#if defined(DEBUG)
    if (no_safepoint_scope_) {
      Thread::Current()->DecrementNoSafepointScopeDepth();
    }
#endif
  }

  void Enter() const {
#if defined(DEBUG)
    if (no_safepoint_scope_) {
      Thread::Current()->IncrementNoSafepointScopeDepth();
    }
#endif
    monitor_->Enter();
  }
  void Exit() const {
    monitor_->Exit();
#if defined(DEBUG)
    if (no_safepoint_scope_) {
      Thread::Current()->DecrementNoSafepointScopeDepth();
    }
#endif
  }

  Monitor::WaitResult Wait(int64_t millis = Monitor::kNoTimeout) {
    return monitor_->Wait(millis);
  }

  Monitor::WaitResult WaitWithSafepointCheck(
      Thread* thread,
      int64_t millis = Monitor::kNoTimeout);

  Monitor::WaitResult WaitMicros(int64_t micros = Monitor::kNoTimeout) {
    return monitor_->WaitMicros(micros);
  }

  void Notify() { monitor_->Notify(); }

  void NotifyAll() { monitor_->NotifyAll(); }

 private:
  Monitor* const monitor_;
  bool no_safepoint_scope_;

  DISALLOW_COPY_AND_ASSIGN(MonitorLocker);
};

/*
 * Safepoint mutex locker :
 * This locker abstraction should be used when the enclosing code could
 * potentially trigger a safepoint.
 * This locker ensures that other threads that try to acquire the same lock
 * will be marked as being at a safepoint if they get blocked trying to
 * acquire the lock.
 * NOTE: please do not use the passed in mutex object independent of the locker
 * class, For example the code below will not work correctly:
 *    {
 *      SafepointMutexLocker ml(m);
 *      ....
 *      m->Exit();
 *      ....
 *      m->Enter();
 *      ...
 *    }
 */
class SafepointMutexLocker : public ValueObject {
 public:
  explicit SafepointMutexLocker(Mutex* mutex);
  virtual ~SafepointMutexLocker() { mutex_->Unlock(); }

 private:
  Mutex* const mutex_;

  DISALLOW_COPY_AND_ASSIGN(SafepointMutexLocker);
};

/*
 * Safepoint monitor locker :
 * This locker abstraction should be used when the enclosing code could
 * potentially trigger a safepoint.
 * This locker ensures that other threads that try to acquire the same lock
 * will be marked as being at a safepoint if they get blocked trying to
 * acquire the lock.
 * NOTE: please do not use the passed in monitor object independent of the
 * locker class, For example the code below will not work correctly:
 *    {
 *      SafepointMonitorLocker ml(m);
 *      ....
 *      m->Exit();
 *      ....
 *      m->Enter();
 *      ...
 *    }
 */
class SafepointMonitorLocker : public ValueObject {
 public:
  explicit SafepointMonitorLocker(Monitor* monitor);
  virtual ~SafepointMonitorLocker() { monitor_->Exit(); }

  Monitor::WaitResult Wait(int64_t millis = Monitor::kNoTimeout);

 private:
  Monitor* const monitor_;

  DISALLOW_COPY_AND_ASSIGN(SafepointMonitorLocker);
};

}  // namespace dart

#endif  // RUNTIME_VM_LOCKERS_H_
