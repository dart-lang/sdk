// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_OS_THREAD_H_
#define RUNTIME_VM_OS_THREAD_H_

#include "platform/atomic.h"
#include "platform/globals.h"
#include "platform/safe_stack.h"
#include "platform/utils.h"
#include "vm/allocation.h"
#include "vm/globals.h"

// Declare the OS-specific types ahead of defining the generic classes.
#if defined(DART_USE_ABSL)
#include "vm/os_thread_absl.h"
#elif defined(DART_HOST_OS_ANDROID)
#include "vm/os_thread_android.h"
#elif defined(DART_HOST_OS_FUCHSIA)
#include "vm/os_thread_fuchsia.h"
#elif defined(DART_HOST_OS_LINUX)
#include "vm/os_thread_linux.h"
#elif defined(DART_HOST_OS_MACOS)
#include "vm/os_thread_macos.h"
#elif defined(DART_HOST_OS_WINDOWS)
#include "vm/os_thread_win.h"
#else
#error Unknown target os.
#endif

namespace dart {

// Forward declarations.
class Log;
class Mutex;
class ThreadState;
class TimelineEventBlock;

class Mutex {
 public:
  explicit Mutex(NOT_IN_PRODUCT(const char* name = "anonymous mutex"));
  ~Mutex();

  bool IsOwnedByCurrentThread() const;

 private:
  void Lock();
  bool TryLock();  // Returns false if lock is busy and locking failed.
  void Unlock();

  MutexData data_;
  NOT_IN_PRODUCT(const char* name_);
#if defined(DEBUG)
  ThreadId owner_;
#endif  // defined(DEBUG)

  friend class MallocLocker;
  friend class MutexLocker;
  friend class SafepointMutexLocker;
  friend class OSThreadIterator;
  friend class TimelineEventRecorder;
  friend class TimelineEventRingRecorder;
  friend class PageSpace;
  friend void Dart_TestMutex();
  DISALLOW_COPY_AND_ASSIGN(Mutex);
};

class BaseThread {
 public:
  bool is_os_thread() const { return is_os_thread_; }

 private:
  explicit BaseThread(bool is_os_thread) : is_os_thread_(is_os_thread) {}
  virtual ~BaseThread() {}

  bool is_os_thread_;

  friend class ThreadState;
  friend class OSThread;

  DISALLOW_IMPLICIT_CONSTRUCTORS(BaseThread);
};

// Low-level operations on OS platform threads.
class OSThread : public BaseThread {
 public:
  static const uword kInvalidStackLimit = ~static_cast<uword>(0);

  // The constructor of OSThread is never called directly, instead we call
  // this factory style method 'CreateOSThread' to create OSThread structures.
  // The method can return a nullptr if the Dart VM is in shutdown mode.
  static OSThread* CreateOSThread();
  ~OSThread();

  ThreadId id() const {
    ASSERT(id_ != OSThread::kInvalidThreadId);
    return id_;
  }

#ifdef SUPPORT_TIMELINE
  ThreadId trace_id() const {
    ASSERT(trace_id_ != OSThread::kInvalidThreadId);
    return trace_id_;
  }
#endif

  const char* name() const { return name_; }

  void SetName(const char* name);

  Mutex* timeline_block_lock() const { return &timeline_block_lock_; }

  // Only safe to access when holding |timeline_block_lock_|.
  TimelineEventBlock* TimelineBlockLocked() const {
    ASSERT(timeline_block_lock()->IsOwnedByCurrentThread());
    return timeline_block_;
  }

  // Only safe to access when holding |timeline_block_lock_|.
  void SetTimelineBlockLocked(TimelineEventBlock* block) {
    ASSERT(timeline_block_lock()->IsOwnedByCurrentThread());
    timeline_block_ = block;
  }

  Log* log() const { return log_; }

  uword stack_base() const { return stack_base_; }
  uword stack_limit() const { return stack_limit_; }
  uword overflow_stack_limit() const { return stack_limit_ + stack_headroom_; }

  bool HasStackHeadroom() { return HasStackHeadroom(stack_headroom_); }
  bool HasStackHeadroom(intptr_t headroom) {
    return GetCurrentStackPointer() > (stack_limit_ + headroom);
  }

  // May fail for the main thread on Linux if resources are low.
  static bool GetCurrentStackBounds(uword* lower, uword* upper);

  // Returns the current C++ stack pointer. Equivalent taking the address of a
  // stack allocated local, but plays well with AddressSanitizer and SafeStack.
  // Accurate enough for stack overflow checks but not accurate enough for
  // alignment checks.
  static uword GetCurrentStackPointer();

#if defined(USING_SAFE_STACK)
  static uword GetCurrentSafestackPointer();
  static void SetCurrentSafestackPointer(uword ssp);
#endif

#if !defined(PRODUCT)
  // Used to temporarily disable or enable thread interrupts.
  void DisableThreadInterrupts();
  void EnableThreadInterrupts();
  bool ThreadInterruptsEnabled();
#endif  // !defined(PRODUCT)

  // The currently executing thread, or nullptr if not yet initialized.
  static OSThread* TryCurrent() {
    BaseThread* thread = GetCurrentTLS();
    OSThread* os_thread = nullptr;
    if (thread != nullptr) {
      if (thread->is_os_thread()) {
        os_thread = reinterpret_cast<OSThread*>(thread);
      } else {
        ThreadState* vm_thread = reinterpret_cast<ThreadState*>(thread);
        os_thread = GetOSThreadFromThread(vm_thread);
      }
    }
    return os_thread;
  }

  // The currently executing thread. If there is no currently executing thread,
  // a new OSThread is created and returned.
  static OSThread* Current() {
    OSThread* os_thread = TryCurrent();
    if (os_thread == nullptr) {
      os_thread = CreateAndSetUnknownThread();
    }
    return os_thread;
  }
  static void SetCurrent(OSThread* current) { SetCurrentTLS(current); }

  static ThreadState* CurrentVMThread() { return current_vm_thread_; }
#if defined(DEBUG)
  static void SetCurrentVMThread(ThreadState* thread) {
    current_vm_thread_ = thread;
  }
#endif

  // TODO(5411455): Use flag to override default value and Validate the
  // stack size by querying OS.
  static uword GetSpecifiedStackSize() {
    intptr_t headroom =
        OSThread::CalculateHeadroom(OSThread::GetMaxStackSize());
    ASSERT(headroom < OSThread::GetMaxStackSize());
    uword stack_size = OSThread::GetMaxStackSize() - headroom;
    return stack_size;
  }
  static BaseThread* GetCurrentTLS() {
    return reinterpret_cast<BaseThread*>(OSThread::GetThreadLocal(thread_key_));
  }
  static void SetCurrentTLS(BaseThread* value);

  typedef void (*ThreadStartFunction)(uword parameter);
  typedef void (*ThreadDestructor)(void* parameter);

  // Start a thread running the specified function. Returns 0 if the
  // thread started successfully and a system specific error code if
  // the thread failed to start.
  static int Start(const char* name,
                   ThreadStartFunction function,
                   uword parameter);

  static ThreadLocalKey CreateThreadLocal(
      ThreadDestructor destructor = nullptr);
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
  // called when the returned id will eventually be passed to OSThread::Join().
  static ThreadJoinId GetCurrentThreadJoinId(OSThread* thread);

  // Called at VM startup and shutdown.
  static void Init();

  static bool IsThreadInList(ThreadId id);

  static void DisableOSThreadCreation();
  static void EnableOSThreadCreation();

  static constexpr intptr_t kStackSizeBufferMax = (16 * KB * kWordSize);
  static constexpr float kStackSizeBufferFraction = 0.5;

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
  ThreadState* thread() const { return thread_; }
  void set_thread(ThreadState* value) { thread_ = value; }

  static void Cleanup();
#ifdef SUPPORT_TIMELINE
  static ThreadId GetCurrentThreadTraceId();
#endif  // SUPPORT_TIMELINE

  // Retrieves the name given to the current thread at the OS level and returns
  // it as a heap-allocated string that must eventually be freed by the caller
  // using free. Returns |nullptr| when the name cannot be retrieved.
  static char* GetCurrentThreadName();
  static OSThread* GetOSThreadFromThread(ThreadState* thread);
  static void AddThreadToListLocked(OSThread* thread);
  static void RemoveThreadFromList(OSThread* thread);
  static OSThread* CreateAndSetUnknownThread();

  static uword CalculateHeadroom(uword stack_size) {
    uword headroom = kStackSizeBufferFraction * stack_size;
    return (headroom > kStackSizeBufferMax) ? kStackSizeBufferMax : headroom;
  }

  static ThreadLocalKey thread_key_;

  const ThreadId id_;
#if defined(DEBUG)
  // In DEBUG mode we use this field to ensure that GetCurrentThreadJoinId is
  // only called once per OSThread.
  ThreadJoinId join_id_ = kInvalidThreadJoinId;
#endif
#ifdef SUPPORT_TIMELINE
  const ThreadId trace_id_;  // Used to interface with tracing tools.
#endif
  char* name_;  // A name for this thread.

  mutable Mutex timeline_block_lock_;
  // The block that the timeline recorder has permitted this thread to write
  // events to.
  TimelineEventBlock* timeline_block_ = nullptr;

  // All |Thread|s are registered in the thread list.
  OSThread* thread_list_next_ = nullptr;

#if !defined(PRODUCT)
  // Thread interrupts disabled by default.
  RelaxedAtomic<uintptr_t> thread_interrupt_disabled_ = {1};
  bool prepared_for_interrupts_ = false;
  void* thread_interrupter_state_ = nullptr;
#endif  // !defined(PRODUCT)

  Log* log_;
  uword stack_base_ = 0;
  uword stack_limit_ = 0;
  uword stack_headroom_ = 0;
  ThreadState* thread_ = nullptr;
  // The ThreadPool::Worker which owns this OSThread. If this OSThread was not
  // started by a ThreadPool it will be nullptr. This TLS value is not
  // protected and should only be read/written by the OSThread itself.
  void* owning_thread_pool_worker_ = nullptr;

  // thread_list_lock_ cannot have a static lifetime because the order in which
  // destructors run is undefined. At the moment this lock cannot be deleted
  // either since otherwise, if a thread only begins to run after we have
  // started to run TLS destructors for a call to exit(), there will be a race
  // on its deletion in CreateOSThread().
  static Mutex* thread_list_lock_;
  static OSThread* thread_list_head_;
  static bool creation_enabled_;

  // Inline initialization is important for avoiding unnecessary TLS
  // initialization checks at each use.
  static inline thread_local ThreadState* current_vm_thread_ = nullptr;

  friend class Thread;  // to access set_thread(Thread*).
  friend class OSThreadIterator;
  friend class ThreadInterrupterFuchsia;
  friend class ThreadInterrupterMacOS;
  friend class ThreadInterrupterWin;
  friend class ThreadPool;  // to access owning_thread_pool_worker_
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

class Monitor {
 public:
  enum WaitResult { kNotified, kTimedOut };

  static constexpr int64_t kNoTimeout = 0;

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
  friend class SafepointRwLock;
  friend void Dart_TestMonitor();
  DISALLOW_COPY_AND_ASSIGN(Monitor);
};

inline bool Mutex::IsOwnedByCurrentThread() const {
#if defined(DEBUG)
  return owner_ == OSThread::GetCurrentThreadId();
#else
  UNREACHABLE();
  return false;
#endif
}

// Mark when we are running in a signal handler (Linux, Android) or with a
// suspended thread (Windows, Mac, Fuchia). During this time, we cannot take
// locks, access Thread/Isolate::Current(), or use malloc.
class ThreadInterruptScope : public ValueObject {
#if defined(DEBUG)
 public:
  ThreadInterruptScope() {
    ASSERT(!in_thread_interrupt_scope_);  // We don't use nested signals.
    in_thread_interrupt_scope_ = true;

    // Poison attempts to use Thread::Current. This is much cheaper than adding
    // an assert in Thread::Current itself.
    saved_current_vm_thread_ = OSThread::CurrentVMThread();
    OSThread::SetCurrentVMThread(reinterpret_cast<ThreadState*>(0xabababab));
  }

  ~ThreadInterruptScope() {
    OSThread::SetCurrentVMThread(saved_current_vm_thread_);
    in_thread_interrupt_scope_ = false;
  }

  static bool in_thread_interrupt_scope() { return in_thread_interrupt_scope_; }

 private:
  ThreadState* saved_current_vm_thread_;
  static inline thread_local bool in_thread_interrupt_scope_ = false;
#endif  // DEBUG
};

}  // namespace dart

#endif  // RUNTIME_VM_OS_THREAD_H_
