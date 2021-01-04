// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/lockers.h"
#include "platform/assert.h"
#include "vm/heap/safepoint.h"
#include "vm/isolate.h"

namespace dart {

Monitor::WaitResult MonitorLocker::WaitWithSafepointCheck(Thread* thread,
                                                          int64_t millis) {
  ASSERT(thread == Thread::Current());
  ASSERT(thread->execution_state() == Thread::kThreadInVM);
#if defined(DEBUG)
  if (no_safepoint_scope_) {
    thread->DecrementNoSafepointScopeDepth();
  }
#endif
  thread->set_execution_state(Thread::kThreadInBlockedState);
  thread->EnterSafepoint();
  Monitor::WaitResult result = monitor_->Wait(millis);
  // First try a fast update of the thread state to indicate it is not at a
  // safepoint anymore.
  if (!thread->TryExitSafepoint()) {
    // Fast update failed which means we could potentially be in the middle
    // of a safepoint operation and need to block for it.
    monitor_->Exit();
    SafepointHandler* handler = thread->isolate_group()->safepoint_handler();
    handler->ExitSafepointUsingLock(thread);
    monitor_->Enter();
  }
  thread->set_execution_state(Thread::kThreadInVM);
#if defined(DEBUG)
  if (no_safepoint_scope_) {
    thread->IncrementNoSafepointScopeDepth();
  }
#endif
  return result;
}

SafepointMutexLocker::SafepointMutexLocker(ThreadState* thread, Mutex* mutex)
    : StackResource(thread), mutex_(mutex) {
  ASSERT(mutex != NULL);
  if (!mutex_->TryLock()) {
    // We did not get the lock and could potentially block, so transition
    // accordingly.
    Thread* thread = Thread::Current();
    if (thread != NULL) {
      TransitionVMToBlocked transition(thread);
      mutex->Lock();
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
      TransitionVMToBlocked transition(thread);
      monitor_->Enter();
    } else {
      monitor_->Enter();
    }
  }
}

Monitor::WaitResult SafepointMonitorLocker::Wait(int64_t millis) {
  Thread* thread = Thread::Current();
  if (thread != NULL) {
    Monitor::WaitResult result;
    {
      TransitionVMToBlocked transition(thread);
      result = monitor_->Wait(millis);
    }
    return result;
  } else {
    return monitor_->Wait(millis);
  }
}

}  // namespace dart
