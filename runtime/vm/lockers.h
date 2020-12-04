// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_LOCKERS_H_
#define RUNTIME_VM_LOCKERS_H_

#include "platform/assert.h"
#include "platform/growable_array.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/os_thread.h"
#include "vm/thread.h"

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
  explicit MutexLocker(Mutex* mutex)
      :
#if defined(DEBUG)
        no_safepoint_scope_(true),
#endif
        mutex_(mutex) {
    ASSERT(mutex != nullptr);
#if defined(DEBUG)
    Thread* thread = Thread::Current();
    if ((thread != nullptr) &&
        (thread->execution_state() != Thread::kThreadInNative)) {
      thread->IncrementNoSafepointScopeDepth();
    } else {
      no_safepoint_scope_ = false;
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
  DEBUG_ONLY(bool no_safepoint_scope_;)
  Mutex* const mutex_;

  DISALLOW_COPY_AND_ASSIGN(MutexLocker);
};

/*
 * Normal monitor locker :
 * This locker abstraction should only be used when the enclosed code can
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

// Leaves the given monitor during the scope of the object.
class MonitorLeaveScope : public ValueObject {
 public:
  explicit MonitorLeaveScope(MonitorLocker* monitor)
      : monitor_locker_(monitor) {
    monitor_locker_->Exit();
  }

  virtual ~MonitorLeaveScope() { monitor_locker_->Enter(); }

 private:
  MonitorLocker* const monitor_locker_;

  DISALLOW_COPY_AND_ASSIGN(MonitorLeaveScope);
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
class SafepointMutexLocker : public StackResource {
 public:
  explicit SafepointMutexLocker(Mutex* mutex)
      : SafepointMutexLocker(ThreadState::Current(), mutex) {}
  SafepointMutexLocker(ThreadState* thread, Mutex* mutex);
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

  void NotifyAll() { monitor_->NotifyAll(); }

 private:
  Monitor* const monitor_;

  DISALLOW_COPY_AND_ASSIGN(SafepointMonitorLocker);
};

class RwLock {
 public:
  RwLock() {}
  ~RwLock() {}

 private:
  friend class ReadRwLocker;
  friend class WriteRwLocker;

  void EnterRead() {
    MonitorLocker ml(&monitor_);
    while (state_ == -1) {
      ml.Wait();
    }
    ++state_;
  }
  void LeaveRead() {
    MonitorLocker ml(&monitor_);
    ASSERT(state_ > 0);
    if (--state_ == 0) {
      ml.NotifyAll();
    }
  }

  void EnterWrite() {
    MonitorLocker ml(&monitor_);
    while (state_ != 0) {
      ml.Wait();
    }
    state_ = -1;
  }
  void LeaveWrite() {
    MonitorLocker ml(&monitor_);
    ASSERT(state_ == -1);
    state_ = 0;
    ml.NotifyAll();
  }

  Monitor monitor_;
  // [state_] > 0  : The lock is held by multiple readers.
  // [state_] == 0 : The lock is free (no readers/writers).
  // [state_] == -1: The lock is held by a single writer.
  intptr_t state_ = 0;
};

class SafepointRwLock {
 public:
  SafepointRwLock() {}
  ~SafepointRwLock() {}

#if defined(DEBUG)
  bool IsCurrentThreadReader() {
    ThreadId id = OSThread::GetCurrentThreadId();
    if (IsCurrentThreadWriter()) {
      return true;
    }
    MutexLocker ml(&reader_ids_mutex_);
    for (intptr_t i = readers_ids_.length() - 1; i >= 0; i--) {
      if (readers_ids_.At(i) == id) {
        return true;
      }
    }
    return false;
  }
#endif  // defined(DEBUG)

  bool IsCurrentThreadWriter() {
    return writer_id_ == OSThread::GetCurrentThreadId();
  }

 private:
  friend class SafepointReadRwLocker;
  friend class SafepointWriteRwLocker;

  // returns [true] if read lock was acuired,
  // returns [false] if the thread didn't have to acquire read lock due
  // to the thread already holding write lock
  bool EnterRead() {
    SafepointMonitorLocker ml(&monitor_);
    if (IsCurrentThreadWriter()) {
      return false;
    }
    while (state_ < 0) {
      ml.Wait();
    }
#if defined(DEBUG)
    {
      MutexLocker ml(&reader_ids_mutex_);
      readers_ids_.Add(OSThread::GetCurrentThreadId());
    }
#endif
    ++state_;
    return true;
  }
  void LeaveRead() {
    SafepointMonitorLocker ml(&monitor_);
    ASSERT(state_ > 0);
#if defined(DEBUG)
    {
      MutexLocker ml(&reader_ids_mutex_);
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

  void EnterWrite() {
    SafepointMonitorLocker ml(&monitor_);
    if (IsCurrentThreadWriter()) {
      state_--;
      return;
    }
    while (state_ != 0) {
      ml.Wait();
    }
    writer_id_ = OSThread::GetCurrentThreadId();
    state_ = -1;
  }
  void LeaveWrite() {
    SafepointMonitorLocker ml(&monitor_);
    ASSERT(state_ < 0);
    state_++;
    if (state_ < 0) {
      return;
    }
    writer_id_ = OSThread::kInvalidThreadId;
    ml.NotifyAll();
  }

  Monitor monitor_;
  // [state_] > 0  : The lock is held by multiple readers.
  // [state_] == 0 : The lock is free (no readers/writers).
  // [state_] < 0  : The lock is held by a single writer (possibly nested).
  intptr_t state_ = 0;

#if defined(DEBUG)
  Mutex reader_ids_mutex_;
  MallocGrowableArray<ThreadId> readers_ids_;
#endif
  ThreadId writer_id_ = OSThread::kInvalidThreadId;
};

/*
 * Locks a given [RwLock] for reading purposes.
 *
 * It will block while the lock is held by a writer.
 *
 * If this locker is long'jmped over (e.g. on a background compiler thread) the
 * lock will be freed.
 *
 * NOTE: If the locking operation blocks (due to a writer) it will not check
 * for a pending safepoint operation.
 */
class ReadRwLocker : public StackResource {
 public:
  ReadRwLocker(ThreadState* thread_state, RwLock* rw_lock)
      : StackResource(thread_state), rw_lock_(rw_lock) {
    rw_lock_->EnterRead();
  }
  ~ReadRwLocker() { rw_lock_->LeaveRead(); }

 private:
  RwLock* rw_lock_;
};

/*
 * In addition to what [ReadRwLocker] does, this implementation also gets into a
 * safepoint if necessary.
 */
class SafepointReadRwLocker : public StackResource {
 public:
  SafepointReadRwLocker(ThreadState* thread_state, SafepointRwLock* rw_lock)
      : StackResource(thread_state), rw_lock_(rw_lock) {
    ASSERT(rw_lock_ != nullptr);
    if (!rw_lock_->EnterRead()) {
      // if lock didn't have to be acquired, it doesn't have to be released.
      rw_lock_ = nullptr;
    }
  }
  ~SafepointReadRwLocker() {
    if (rw_lock_ != nullptr) {
      rw_lock_->LeaveRead();
    }
  }

 private:
  SafepointRwLock* rw_lock_;
};

/*
 * Locks a given [RwLock] for writing purposes.
 *
 * It will block while the lock is held by one or more readers.
 *
 * If this locker is long'jmped over (e.g. on a background compiler thread) the
 * lock will be freed.
 *
 * NOTE: If the locking operation blocks (due to a writer) it will not check
 * for a pending safepoint operation.
 */
class WriteRwLocker : public StackResource {
 public:
  WriteRwLocker(ThreadState* thread_state, RwLock* rw_lock)
      : StackResource(thread_state), rw_lock_(rw_lock) {
    rw_lock_->EnterWrite();
  }

  ~WriteRwLocker() { rw_lock_->LeaveWrite(); }

 private:
  RwLock* rw_lock_;
};

/*
 * In addition to what [WriteRwLocker] does, this implementation also gets into a
 * safepoint if necessary.
 */
class SafepointWriteRwLocker : public StackResource {
 public:
  SafepointWriteRwLocker(ThreadState* thread_state, SafepointRwLock* rw_lock)
      : StackResource(thread_state), rw_lock_(rw_lock) {
    rw_lock_->EnterWrite();
  }

  ~SafepointWriteRwLocker() { rw_lock_->LeaveWrite(); }

 private:
  SafepointRwLock* rw_lock_;
};

}  // namespace dart

#endif  // RUNTIME_VM_LOCKERS_H_
