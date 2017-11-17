// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/lockers.h"
#include "platform/assert.h"
#include "vm/safepoint.h"

namespace dart {

Monitor::WaitResult MonitorLocker::WaitWithSafepointCheck(Thread* thread,
                                                          int64_t millis) {
  ASSERT(thread == Thread::Current());
  ASSERT(thread->execution_state() == Thread::kThreadInVM);
  thread->set_execution_state(Thread::kThreadInBlockedState);
  thread->EnterSafepoint();
  Monitor::WaitResult result = monitor_->Wait(millis);
  // First try a fast update of the thread state to indicate it is not at a
  // safepoint anymore.
  if (!thread->TryExitSafepoint()) {
    // Fast update failed which means we could potentially be in the middle
    // of a safepoint operation and need to block for it.
    monitor_->Exit();
    SafepointHandler* handler = thread->isolate()->safepoint_handler();
    handler->ExitSafepointUsingLock(thread);
    monitor_->Enter();
  }
  thread->set_execution_state(Thread::kThreadInVM);
  return result;
}

SafepointMutexLocker::SafepointMutexLocker(Mutex* mutex) : mutex_(mutex) {
  ASSERT(mutex != NULL);
  if (!mutex_->TryLock()) {
    // We did not get the lock and could potentially block, so transition
    // accordingly.
    Thread* thread = Thread::Current();
    if (thread != NULL) {
      thread->set_execution_state(Thread::kThreadInBlockedState);
      thread->EnterSafepoint();
      mutex->Lock();
      // Update thread state and block if a safepoint operation is in progress.
      thread->ExitSafepoint();
      thread->set_execution_state(Thread::kThreadInVM);
    } else {
      mutex->Lock();
    }
  }
}

SafepointMonitorLocker::SafepointMonitorLocker(Monitor* monitor)
    : monitor_(monitor) {
  ASSERT(monitor_ != NULL);
  if (!monitor_->TryEnter()) {
    // We did not get the lock and could potentially block, so transition
    // accordingly.
    Thread* thread = Thread::Current();
    if (thread != NULL) {
      thread->set_execution_state(Thread::kThreadInBlockedState);
      thread->EnterSafepoint();
      monitor_->Enter();
      // Update thread state and block if a safepoint operation is in progress.
      thread->ExitSafepoint();
      thread->set_execution_state(Thread::kThreadInVM);
    } else {
      monitor_->Enter();
    }
  }
}

Monitor::WaitResult SafepointMonitorLocker::Wait(int64_t millis) {
  Thread* thread = Thread::Current();
  if (thread != NULL) {
    thread->set_execution_state(Thread::kThreadInBlockedState);
    thread->EnterSafepoint();
    Monitor::WaitResult result = monitor_->Wait(millis);
    // First try a fast update of the thread state to indicate it is not at a
    // safepoint anymore.
    if (!thread->TryExitSafepoint()) {
      // Fast update failed which means we could potentially be in the middle
      // of a safepoint operation and need to block for it.
      monitor_->Exit();
      SafepointHandler* handler = thread->isolate()->safepoint_handler();
      handler->ExitSafepointUsingLock(thread);
      monitor_->Enter();
    }
    thread->set_execution_state(Thread::kThreadInVM);
    return result;
  } else {
    return monitor_->Wait(millis);
  }
}

}  // namespace dart
