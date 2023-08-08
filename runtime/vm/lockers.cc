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
    thread->ExitSafepointUsingLock();
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
  ASSERT(mutex != nullptr);
  if (!mutex_->TryLock()) {
    // We did not get the lock and could potentially block, so transition
    // accordingly.
    Thread* thread = Thread::Current();
    if (thread != nullptr) {
      TransitionVMToBlocked transition(thread);
      mutex->Lock();
    } else {
      mutex->Lock();
    }
  }
}

void SafepointMonitorLocker::AcquireLock() {
  ASSERT(monitor_ != nullptr);
  if (!monitor_->TryEnter()) {
    // We did not get the lock and could potentially block, so transition
    // accordingly.
    Thread* thread = Thread::Current();
    if (thread != nullptr) {
      TransitionVMToBlocked transition(thread);
      monitor_->Enter();
    } else {
      monitor_->Enter();
    }
  }
}

void SafepointMonitorLocker::ReleaseLock() {
  monitor_->Exit();
}

Monitor::WaitResult SafepointMonitorLocker::Wait(int64_t millis) {
  Thread* thread = Thread::Current();
  if (thread != nullptr) {
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

#if defined(DEBUG)
bool SafepointRwLock::IsCurrentThreadReader() {
  ThreadId id = OSThread::GetCurrentThreadId();
  if (IsCurrentThreadWriter()) {
    return true;
  }
  MonitorLocker ml(&monitor_);
  for (intptr_t i = readers_ids_.length() - 1; i >= 0; i--) {
    if (readers_ids_.At(i) == id) {
      return true;
    }
  }
  return false;
}
#endif  // defined(DEBUG)

bool SafepointRwLock::EnterRead() {
  // No need to safepoint if the current thread is not attached.
  auto thread = Thread::Current();
  // Attempt to acquire a lock while owning a safepoint could lead to a deadlock
  // (some other thread might be forced to a safepoint while holding this lock).
  //
  // Though if the lock was already acquired by this thread before entering a
  // safepoint, we do allow the nested acquire (which is a NOP).
  DEBUG_ASSERT(thread == nullptr || thread->CanAcquireSafepointLocks() ||
               IsCurrentThreadReader());

  const bool can_block_without_safepoint = thread == nullptr;

  bool acquired_read_lock = false;
  if (!TryEnterRead(can_block_without_safepoint, &acquired_read_lock)) {
    // Important: must never hold monitor_ when blocking for safepoint.
    TransitionVMToBlocked transition(thread);
    const bool ok = TryEnterRead(/*can_block=*/true, &acquired_read_lock);
    RELEASE_ASSERT(ok);
    RELEASE_ASSERT(acquired_read_lock);
  }
  return acquired_read_lock;
}

bool SafepointRwLock::TryEnterRead(bool can_block, bool* acquired_read_lock) {
  MonitorLocker ml(&monitor_);
  if (IsCurrentThreadWriter()) {
    *acquired_read_lock = false;
    return true;
  }
  if (can_block) {
    while (state_ < 0) {
      ml.Wait();
    }
  }
  if (state_ >= 0) {
    ++state_;
    DEBUG_ONLY(readers_ids_.Add(OSThread::GetCurrentThreadId()));
    *acquired_read_lock = true;
    return true;
  }
  return false;
}

void SafepointRwLock::LeaveRead() {
  MonitorLocker ml(&monitor_);
  ASSERT(state_ > 0);
#if defined(DEBUG)
  {
    intptr_t i = readers_ids_.length() - 1;
    ThreadId id = OSThread::GetCurrentThreadId();
    while (i >= 0) {
      if (readers_ids_.At(i) == id) {
        readers_ids_.RemoveAt(i);
        break;
      }
      i--;
    }
    ASSERT(i >= 0);
  }
#endif
  if (--state_ == 0) {
    ml.NotifyAll();
  }
}

void SafepointRwLock::EnterWrite() {
  // No need to safepoint if the current thread is not attached.
  auto thread = Thread::Current();
  // Attempt to acquire a lock while owning a safepoint could lead to a deadlock
  // (some other thread might be forced to a safepoint while holding this lock).
  //
  // Though if the lock was already acquired by this thread before entering a
  // safepoint, we do allow the nested acquire (which is a NOP).
  DEBUG_ASSERT(thread == nullptr || thread->CanAcquireSafepointLocks() ||
               IsCurrentThreadWriter());

  const bool can_block_without_safepoint = thread == nullptr;

  if (!TryEnterWrite(can_block_without_safepoint)) {
    // Important: must never hold monitor_ when blocking for safepoint.
    TransitionVMToBlocked transition(thread);
    const bool ok = TryEnterWrite(/*can_block=*/true);
    RELEASE_ASSERT(ok);
  }
}

bool SafepointRwLock::TryEnterWrite(bool can_block) {
  MonitorLocker ml(&monitor_);
  if (IsCurrentThreadWriter()) {
    state_--;
    return true;
  }
  if (can_block) {
    while (state_ != 0) {
      ml.Wait();
    }
  }
  if (state_ == 0) {
    writer_id_ = OSThread::GetCurrentThreadId();
    state_ = -1;
    return true;
  }
  return false;
}

void SafepointRwLock::LeaveWrite() {
  MonitorLocker ml(&monitor_);
  ASSERT(state_ < 0);
  if (++state_ < 0) {
    return;
  }
  writer_id_ = OSThread::kInvalidThreadId;
  ml.NotifyAll();
}

}  // namespace dart
