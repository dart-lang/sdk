// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OS_THREAD_H_
#define RUNTIME_VM_OS_THREAD_H_

#include "platform/globals.h"
#include "vm/allocation.h"
#include "vm/globals.h"

// Declare the OS-specific types ahead of defining the generic classes.
#if defined(HOST_OS_ANDROID)
#include "vm/os_thread_android.h"
#elif defined(HOST_OS_FUCHSIA)
#include "vm/os_thread_fuchsia.h"
#elif defined(HOST_OS_LINUX)
#include "vm/os_thread_linux.h"
#elif defined(HOST_OS_MACOS)
#include "vm/os_thread_macos.h"
#elif defined(HOST_OS_WINDOWS)
#include "vm/os_thread_win.h"
#else
#error Unknown target os.
#endif

namespace dart {

// Forward declarations.
class Log;
class Mutex;
class Thread;
class TimelineEventBlock;

class BaseThread {
 public:
  bool is_os_thread() const { return is_os_thread_; }

 private:
  explicit BaseThread(bool is_os_thread) : is_os_thread_(is_os_thread) {}
  ~BaseThread() {}

  bool is_os_thread_;

  friend class Thread;
  friend class OSThread;

  DISALLOW_IMPLICIT_CONSTRUCTORS(BaseThread);
};

// Low-level operations on OS platform threads.
class OSThread : public BaseThread {
 public:
  // The constructor of OSThread is never called directly, instead we call
  // this factory style method 'CreateOSThread' to create OSThread structures.
  // The method can return a NULL if the Dart VM is in shutdown mode.
  static OSThread* CreateOSThread();
  ~OSThread();

  ThreadId id() const {
    ASSERT(id_ != OSThread::kInvalidThreadId);
    return id_;
  }

#ifndef PRODUCT
  ThreadId trace_id() const {
    ASSERT(trace_id_ != OSThread::kInvalidThreadId);
    return trace_id_;
  }
#endif

  const char* name() const { return name_; }

  void SetName(const char* name);

  void set_name(const char* name) {
    ASSERT(OSThread::Current() == this);
    ASSERT(name_ == NULL);
    ASSERT(name != NULL);
    name_ = strdup(name);
  }

  Mutex* timeline_block_lock() const { return timeline_block_lock_; }

  // Only safe to access when holding |timeline_block_lock_|.
  TimelineEventBlock* timeline_block() const { return timeline_block_; }

  // Only safe to access when holding |timeline_block_lock_|.
  void set_timeline_block(TimelineEventBlock* block) {
    timeline_block_ = block;
  }

  Log* log() const { return log_; }

  uword stack_base() const { return stack_base_; }
  void set_stack_base(uword stack_base) { stack_base_ = stack_base; }

  // Retrieve the stack address bounds for profiler.
  bool GetProfilerStackBounds(uword* lower, uword* upper) const {
    uword stack_upper = stack_base_;
    if (stack_upper == 0) {
      return false;
    }
    uword stack_lower = stack_upper - GetSpecifiedStackSize();
    *lower = stack_lower;
    *upper = stack_upper;
    return true;
  }

  static bool GetCurrentStackBounds(uword* lower, uword* upper);

  // Used to temporarily disable or enable thread interrupts.
  void DisableThreadInterrupts();
  void EnableThreadInterrupts();
  bool ThreadInterruptsEnabled();

  // The currently executing thread, or NULL if not yet initialized.
  static OSThread* TryCurrent() {
    BaseThread* thread = GetCurrentTLS();
    OSThread* os_thread = NULL;
    if (thread != NULL) {
      if (thread->is_os_thread()) {
        os_thread = reinterpret_cast<OSThread*>(thread);
      } else {
        Thread* vm_thread = reinterpret_cast<Thread*>(thread);
        os_thread = GetOSThreadFromThread(vm_thread);
      }
    }
    return os_thread;
  }

  // The currently executing thread. If there is no currently executing thread,
  // a new OSThread is created and returned.
  static OSThread* Current() {
    OSThread* os_thread = TryCurrent();
    if (os_thread == NULL) {
      os_thread = CreateAndSetUnknownThread();
    }
    return os_thread;
  }
  static void SetCurrent(OSThread* current);

  // TODO(5411455): Use flag to override default value and Validate the
  // stack size by querying OS.
  static uword GetSpecifiedStackSize() {
    ASSERT(OSThread::kStackSizeBuffer < OSThread::GetMaxStackSize());
    uword stack_size = OSThread::GetMaxStackSize() - OSThread::kStackSizeBuffer;
    return stack_size;
  }
  static BaseThread* GetCurrentTLS() {
    return reinterpret_cast<BaseThread*>(OSThread::GetThreadLocal(thread_key_));
  }
  static void SetCurrentTLS(uword value) { SetThreadLocal(thread_key_, value); }

  typedef void (*ThreadStartFunction)(uword parameter);
  typedef void (*ThreadDestructor)(void* parameter);

  // Start a thread running the specified function. Returns 0 if the
  // thread started successfuly and a system specific error code if
  // the thread failed to start.
  static int Start(const char* name,
                   ThreadStartFunction function,
                   uword parameter);

  static ThreadLocalKey CreateThreadLocal(ThreadDestructor destructor = NULL);
  static void DeleteThreadLocal(ThreadLocalKey key);
  static uword GetThreadLocal(ThreadLocalKey key) {
    return ThreadInlineImpl::GetThreadLocal(key);
  }
  static ThreadId GetCurrentThreadId();
  static void SetThreadLocal(ThreadLocalKey key, uword value);
  static intptr_t GetMaxStackSize();
  static void Join(ThreadJoinId id);
  static intptr_t ThreadIdToIntPtr(ThreadId id);
  static ThreadId ThreadIdFromIntPtr(intptr_t id);
  static bool Compare(ThreadId a, ThreadId b);

  // This function can be called only once per OSThread, and should only be
  // called when the retunred id will eventually be passed to OSThread::Join().
  static ThreadJoinId GetCurrentThreadJoinId(OSThread* thread);

  // Called at VM startup and shutdown.
  static void InitOnce();

  static bool IsThreadInList(ThreadId id);

  static void DisableOSThreadCreation();
  static void EnableOSThreadCreation();

  static const intptr_t kStackSizeBuffer = (4 * KB * kWordSize);

  static const ThreadId kInvalidThreadId;
  static const ThreadJoinId kInvalidThreadJoinId;

 private:
  // The constructor is private as CreateOSThread should be used
  // to create a new OSThread structure.
  OSThread();

  // These methods should not be used in a generic way and hence
  // are private, they have been added to solve the problem of
  // accessing the VM thread structure from an OSThread object
  // in the windows thread interrupter which is used for profiling.
  // We could eliminate this requirement if the windows thread interrupter
  // is implemented differently.
  Thread* thread() const { return thread_; }
  void set_thread(Thread* value) { thread_ = value; }

  static void Cleanup();
#ifndef PRODUCT
  static ThreadId GetCurrentThreadTraceId();
#endif  // PRODUCT
  static OSThread* GetOSThreadFromThread(Thread* thread);
  static void AddThreadToListLocked(OSThread* thread);
  static void RemoveThreadFromList(OSThread* thread);
  static OSThread* CreateAndSetUnknownThread();

  static ThreadLocalKey thread_key_;

  const ThreadId id_;
#if defined(DEBUG)
  // In DEBUG mode we use this field to ensure that GetCurrentThreadJoinId is
  // only called once per OSThread.
  ThreadJoinId join_id_;
#endif
#ifndef PRODUCT
  const ThreadId trace_id_;  // Used to interface with tracing tools.
#endif
  char* name_;  // A name for this thread.

  Mutex* timeline_block_lock_;
  TimelineEventBlock* timeline_block_;

  // All |Thread|s are registered in the thread list.
  OSThread* thread_list_next_;

  uintptr_t thread_interrupt_disabled_;
  Log* log_;
  uword stack_base_;
  Thread* thread_;

  // thread_list_lock_ cannot have a static lifetime because the order in which
  // destructors run is undefined. At the moment this lock cannot be deleted
  // either since otherwise, if a thread only begins to run after we have
  // started to run TLS destructors for a call to exit(), there will be a race
  // on its deletion in CreateOSThread().
  static Mutex* thread_list_lock_;
  static OSThread* thread_list_head_;
  static bool creation_enabled_;

  friend class Isolate;  // to access set_thread(Thread*).
  friend class OSThreadIterator;
  friend class ThreadInterrupterWin;
  friend class ThreadInterrupterFuchsia;
};

// Note that this takes the thread list lock, prohibiting threads from coming
// on- or off-line.
class OSThreadIterator : public ValueObject {
 public:
  OSThreadIterator();
  ~OSThreadIterator();

  // Returns false when there are no more threads left.
  bool HasNext() const;

  // Returns the current thread and moves forward.
  OSThread* Next();

 private:
  OSThread* next_;
};

class Mutex {
 public:
  Mutex();
  ~Mutex();

#if defined(DEBUG)
  bool IsOwnedByCurrentThread() const {
    return owner_ == OSThread::GetCurrentThreadId();
  }
#else
  bool IsOwnedByCurrentThread() const {
    UNREACHABLE();
    return false;
  }
#endif

 private:
  void Lock();
  bool TryLock();  // Returns false if lock is busy and locking failed.
  void Unlock();

  MutexData data_;
#if defined(DEBUG)
  ThreadId owner_;
#endif  // defined(DEBUG)

  friend class MallocLocker;
  friend class MutexLocker;
  friend class SafepointMutexLocker;
  friend class OSThreadIterator;
  friend class TimelineEventBlockIterator;
  friend class TimelineEventRecorder;
  friend class PageSpace;
  friend void Dart_TestMutex();
  DISALLOW_COPY_AND_ASSIGN(Mutex);
};

class Monitor {
 public:
  enum WaitResult { kNotified, kTimedOut };

  static const int64_t kNoTimeout = 0;

  Monitor();
  ~Monitor();

#if defined(DEBUG)
  bool IsOwnedByCurrentThread() const {
    return owner_ == OSThread::GetCurrentThreadId();
  }
#else
  bool IsOwnedByCurrentThread() const {
    UNREACHABLE();
    return false;
  }
#endif

 private:
  bool TryEnter();  // Returns false if lock is busy and locking failed.
  void Enter();
  void Exit();

  // Wait for notification or timeout.
  WaitResult Wait(int64_t millis);
  WaitResult WaitMicros(int64_t micros);

  // Notify waiting threads.
  void Notify();
  void NotifyAll();

  MonitorData data_;  // OS-specific data.
#if defined(DEBUG)
  ThreadId owner_;
#endif  // defined(DEBUG)

  friend class MonitorLocker;
  friend class SafepointMonitorLocker;
  friend void Dart_TestMonitor();
  DISALLOW_COPY_AND_ASSIGN(Monitor);
};

}  // namespace dart

#endif  // RUNTIME_VM_OS_THREAD_H_
