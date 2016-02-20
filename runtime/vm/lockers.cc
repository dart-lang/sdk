// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/lockers.h"
#include "vm/safepoint.h"

namespace dart {


Monitor::WaitResult MonitorLocker::WaitWithSafepointCheck(Thread* thread,
                                                          int64_t millis) {
  ASSERT(thread == Thread::Current());
  thread->set_execution_state(Thread::kThreadInBlockedState);
  thread->EnterSafepoint();
  Monitor::WaitResult result = monitor_->Wait(millis);
  // First try a fast update of the thread state to indicate it is not at a
  // safepoint anymore.
  uword old_state = Thread::SetAtSafepoint(true, 0);
  uword addr =
      reinterpret_cast<uword>(thread) + Thread::safepoint_state_offset();
  if (AtomicOperations::CompareAndSwapWord(
          reinterpret_cast<uword*>(addr), old_state, 0) != old_state) {
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
    thread->set_execution_state(Thread::kThreadInBlockedState);
    thread->EnterSafepoint();
    mutex->Lock();
    // First try a fast update of the thread state to indicate it is not at a
    // safepoint anymore.
    uword old_state = Thread::SetAtSafepoint(true, 0);
    uword addr =
        reinterpret_cast<uword>(thread) + Thread::safepoint_state_offset();
    if (AtomicOperations::CompareAndSwapWord(
            reinterpret_cast<uword*>(addr), old_state, 0) != old_state) {
      // Fast update failed which means we could potentially be in the middle
      // of a safepoint operation and need to block for it.
      SafepointHandler* handler = thread->isolate()->safepoint_handler();
      handler->ExitSafepointUsingLock(thread);
    }
    thread->set_execution_state(Thread::kThreadInVM);
  }
}

}  // namespace dart
