// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/simulator.h"
#include "vm/thread_interrupter.h"

namespace dart {

// Notes:
//
// The ThreadInterrupter interrupts all registered threads once per
// interrupt period (default is every millisecond). While the thread is
// interrupted, the thread's interrupt callback is invoked. Callbacks cannot
// rely on being executed on the interrupted thread.
//
// There are two mechanisms used to interrupt a thread. The first, used on OSs
// with pthreads (Android, Linux, and Mac), is thread specific signal delivery.
// The second, used on Windows, is explicit suspend and resume thread system
// calls. Signal delivery forbids taking locks and allocating memory (which
// takes a lock). Explicit suspend and resume means that the interrupt callback
// will not be executing on the interrupted thread, making it meaningless to
// access TLS from within the thread interrupt callback. Combining these
// limitations, thread interrupt callbacks are forbidden from:
//
//   * Accessing TLS.
//   * Allocating memory.
//   * Taking a lock.
//
// The ThreadInterrupter has a single monitor (monitor_). This monitor guards
// access to the list of threads registered to receive interrupts (threads_).
//
// A thread can only register and unregister itself. Each thread has a heap
// allocated ThreadState. A thread's ThreadState is lazily allocated the first
// time the thread is registered. A pointer to a thread's ThreadState is stored
// in the list of threads registered to receive interrupts (threads_) and in
// thread local storage. When a thread's ThreadState is being modified, the
// thread local storage pointer is temporarily set to NULL while the
// modification is occurring. After the ThreadState has been updated, the
// thread local storage pointer is set again. This has an important side
// effect: if the thread is interrupted by a signal handler during a ThreadState
// update the signal handler will immediately return.

DEFINE_FLAG(bool, trace_thread_interrupter, false,
            "Trace thread interrupter");

bool ThreadInterrupter::initialized_ = false;
bool ThreadInterrupter::shutdown_ = false;
bool ThreadInterrupter::thread_running_ = false;
ThreadId ThreadInterrupter::interrupter_thread_id_ = Thread::kInvalidThreadId;
Monitor* ThreadInterrupter::monitor_ = NULL;
intptr_t ThreadInterrupter::interrupt_period_ = 1000;
ThreadLocalKey ThreadInterrupter::thread_state_key_ =
    Thread::kUnsetThreadLocalKey;
ThreadInterrupter::ThreadState** ThreadInterrupter::threads_ = NULL;
intptr_t ThreadInterrupter::threads_capacity_ = 0;
intptr_t ThreadInterrupter::threads_size_ = 0;


void ThreadInterrupter::InitOnce() {
  ASSERT(!initialized_);
  initialized_ = true;
  ASSERT(thread_state_key_ == Thread::kUnsetThreadLocalKey);
  thread_state_key_ = Thread::CreateThreadLocal();
  ASSERT(thread_state_key_ != Thread::kUnsetThreadLocalKey);
  monitor_ = new Monitor();
  ResizeThreads(16);
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter starting up.\n");
  }
  ASSERT(interrupter_thread_id_ == Thread::kInvalidThreadId);
  {
    MonitorLocker startup_ml(monitor_);
    Thread::Start(ThreadMain, 0);
    while (!thread_running_) {
      startup_ml.Wait();
    }
  }
  ASSERT(interrupter_thread_id_ != Thread::kInvalidThreadId);
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter running.\n");
  }
}


void ThreadInterrupter::Shutdown() {
  if (shutdown_) {
    // Already shutdown.
    return;
  }
  ASSERT(initialized_);
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter shutting down.\n");
  }
  intptr_t size_at_shutdown = 0;
  {
    MonitorLocker ml(monitor_);
    shutdown_ = true;
    size_at_shutdown = threads_size_;
    threads_size_ = 0;
    threads_capacity_ = 0;
    free(threads_);
    threads_ = NULL;
  }
  {
    MonitorLocker shutdown_ml(monitor_);
    while (thread_running_) {
      shutdown_ml.Wait();
    }
  }
  interrupter_thread_id_ = Thread::kInvalidThreadId;
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter shut down (%" Pd ").\n", size_at_shutdown);
  }
}

// Delay between interrupts.
void ThreadInterrupter::SetInterruptPeriod(intptr_t period) {
  if (shutdown_) {
    return;
  }
  ASSERT(initialized_);
  ASSERT(period > 0);
  {
    MonitorLocker ml(monitor_);
    interrupt_period_ = period;
  }
}


// Register the currently running thread for interrupts. If the current thread
// is already registered, callback and data will be updated.
void ThreadInterrupter::Register(ThreadInterruptCallback callback, void* data) {
  if (shutdown_) {
    return;
  }
  ASSERT(initialized_);
  {
    MonitorLocker ml(monitor_);
    _EnsureThreadStateCreated();
    // Set callback and data.
    UpdateStateObject(callback, data);
    _Enable();
  }
}


// Unregister the currently running thread for interrupts.
void ThreadInterrupter::Unregister() {
  if (shutdown_) {
    return;
  }
  ASSERT(initialized_);
  {
    MonitorLocker ml(monitor_);
    _EnsureThreadStateCreated();
    // Clear callback and data.
    UpdateStateObject(NULL, NULL);
    _Disable();
  }
}


void ThreadInterrupter::Enable() {
  if (shutdown_) {
    return;
  }
  ASSERT(initialized_);
  {
    MonitorLocker ml(monitor_);
    _EnsureThreadStateCreated();
    _Enable();
  }
}


void ThreadInterrupter::Disable() {
  if (shutdown_) {
    return;
  }
  ASSERT(initialized_);
  {
    MonitorLocker ml(monitor_);
    _EnsureThreadStateCreated();
    _Disable();
  }
}


void ThreadInterrupter::_EnsureThreadStateCreated() {
  ThreadState* state = CurrentThreadState();
  if (state == NULL) {
    // Create thread state object lazily.
    ThreadId current_thread = Thread::GetCurrentThreadId();
    if (FLAG_trace_thread_interrupter) {
      intptr_t tid = Thread::ThreadIdToIntPtr(current_thread);
      OS::Print("ThreadInterrupter Tracking %p\n",
                reinterpret_cast<void*>(tid));
    }
    state = new ThreadState();
    state->callback = NULL;
    state->data = NULL;
    state->id = current_thread;
    SetCurrentThreadState(state);
  }
}


void ThreadInterrupter::_Enable() {
  // Must be called with monitor_ locked.
  ThreadId current_thread = Thread::GetCurrentThreadId();
  if (Thread::Compare(current_thread, interrupter_thread_id_)) {
    return;
  }
  intptr_t i = FindThreadIndex(current_thread);
  if (i >= 0) {
    return;
  }
  AddThread(current_thread);
  if (FLAG_trace_thread_interrupter) {
    intptr_t tid = Thread::ThreadIdToIntPtr(current_thread);
    OS::Print("ThreadInterrupter Added %p\n", reinterpret_cast<void*>(tid));
  }
}

void ThreadInterrupter::_Disable() {
  // Must be called with monitor_ locked.
  ThreadId current_thread = Thread::GetCurrentThreadId();
  if (Thread::Compare(current_thread, interrupter_thread_id_)) {
    return;
  }
  intptr_t index = FindThreadIndex(current_thread);
  if (index < 0) {
    // Not registered.
    return;
  }
  ThreadState* state = RemoveThread(index);
  ASSERT(state != NULL);
  ASSERT(state == ThreadInterrupter::CurrentThreadState());
  if (FLAG_trace_thread_interrupter) {
    intptr_t tid = Thread::ThreadIdToIntPtr(current_thread);
    OS::Print("ThreadInterrupter Removed %p\n", reinterpret_cast<void*>(tid));
  }
}

void ThreadInterrupter::UpdateStateObject(ThreadInterruptCallback callback,
                                          void* data) {
  // Must be called with monitor_ locked.
  ThreadState* state = CurrentThreadState();
  ThreadId current_thread = Thread::GetCurrentThreadId();
  ASSERT(state != NULL);
  ASSERT(Thread::Compare(state->id, Thread::GetCurrentThreadId()));
  SetCurrentThreadState(NULL);
  // It is now safe to modify the state object. If an interrupt occurs,
  // the current thread state will be NULL.
  state->callback = callback;
  state->data = data;
  SetCurrentThreadState(state);
  if (FLAG_trace_thread_interrupter) {
    intptr_t tid = Thread::ThreadIdToIntPtr(current_thread);
    if (callback == NULL) {
      OS::Print("ThreadInterrupter Cleared %p\n", reinterpret_cast<void*>(tid));
    } else {
      OS::Print("ThreadInterrupter Updated %p\n", reinterpret_cast<void*>(tid));
    }
  }
}


ThreadInterrupter::ThreadState* ThreadInterrupter::CurrentThreadState() {
  ThreadState* state = reinterpret_cast<ThreadState*>(
      Thread::GetThreadLocal(thread_state_key_));
  return state;
}


void ThreadInterrupter::SetCurrentThreadState(ThreadState* state) {
  Thread::SetThreadLocal(thread_state_key_, reinterpret_cast<uword>(state));
}


void ThreadInterrupter::ResizeThreads(intptr_t new_capacity) {
  // Must be called with monitor_ locked.
  ASSERT(new_capacity < kMaxThreads);
  ASSERT(new_capacity > threads_capacity_);
  ThreadState* state = NULL;
  threads_ = reinterpret_cast<ThreadState**>(
      realloc(threads_, sizeof(state) * new_capacity));
  for (intptr_t i = threads_capacity_; i < new_capacity; i++) {
    threads_[i] = NULL;
  }
  threads_capacity_ = new_capacity;
}


void ThreadInterrupter::AddThread(ThreadId id) {
  // Must be called with monitor_ locked.
  if (threads_ == NULL) {
    // We are shutting down.
    return;
  }
  ThreadState* state = CurrentThreadState();
  if (state->callback == NULL) {
    // No callback.
    return;
  }
  if (threads_size_ == threads_capacity_) {
    ResizeThreads(threads_capacity_ == 0 ? 16 : threads_capacity_ * 2);
  }
  threads_[threads_size_] = state;
  threads_size_++;
}


intptr_t ThreadInterrupter::FindThreadIndex(ThreadId id) {
  // Must be called with monitor_ locked.
  if (threads_ == NULL) {
    // We are shutting down.
    return -1;
  }
  for (intptr_t i = 0; i < threads_size_; i++) {
    if (threads_[i]->id == id) {
      return i;
    }
  }
  return -1;
}


ThreadInterrupter::ThreadState* ThreadInterrupter::RemoveThread(intptr_t i) {
  // Must be called with monitor_ locked.
  if (threads_ == NULL) {
    // We are shutting down.
    return NULL;
  }
  ASSERT(i < threads_size_);
  ThreadState* state = threads_[i];
  ASSERT(state != NULL);
  intptr_t last = threads_size_ - 1;
  if (i != last) {
    threads_[i] = threads_[last];
  }
  // Mark last as NULL.
  threads_[last] = NULL;
  // Pop.
  threads_size_--;
  return state;
}


void ThreadInterruptNoOp(const InterruptedThreadState& state, void* data) {
  // NoOp.
}

void ThreadInterrupter::ThreadMain(uword parameters) {
  ASSERT(initialized_);
  InstallSignalHandler();
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter thread running.\n");
  }
  {
    // Signal to main thread we are ready.
    MonitorLocker startup_ml(monitor_);
    thread_running_ = true;
    interrupter_thread_id_ = Thread::GetCurrentThreadId();
    startup_ml.Notify();
  }
  {
    MonitorLocker ml(monitor_);
    while (!shutdown_) {
      int64_t current_time = OS::GetCurrentTimeMicros();
      InterruptThreads(current_time);
      ml.WaitMicros(interrupt_period_);
    }
  }
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter thread exiting.\n");
  }
  {
    // Signal to main thread we are exiting.
    MonitorLocker shutdown_ml(monitor_);
    thread_running_ = false;
    shutdown_ml.Notify();
  }
}

}  // namespace dart
