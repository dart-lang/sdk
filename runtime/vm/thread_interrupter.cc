// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_interrupter.h"

#include "vm/flags.h"
#include "vm/lockers.h"
#include "vm/os.h"
#include "vm/simulator.h"

namespace dart {

// Notes:
//
// The ThreadInterrupter interrupts all threads actively running isolates once
// per interrupt period (default is 1 millisecond). While the thread is
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
// The ThreadInterrupter has a single monitor (monitor_). This monitor is used
// to synchronize startup, shutdown, and waking up from a deep sleep.
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
intptr_t ThreadInterrupter::current_wait_time_ = Monitor::kNoTimeout;
ThreadLocalKey ThreadInterrupter::thread_state_key_ =
    Thread::kUnsetThreadLocalKey;


void ThreadInterrupter::InitOnce() {
  ASSERT(!initialized_);
  ASSERT(thread_state_key_ == Thread::kUnsetThreadLocalKey);
  thread_state_key_ = Thread::CreateThreadLocal();
  ASSERT(thread_state_key_ != Thread::kUnsetThreadLocalKey);
  monitor_ = new Monitor();
  ASSERT(monitor_ != NULL);
  initialized_ = true;
}


void ThreadInterrupter::Startup() {
  ASSERT(initialized_);
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
  {
    MonitorLocker shutdown_ml(monitor_);
    if (shutdown_) {
      // Already shutdown.
      return;
    }
    shutdown_ = true;
    // Notify.
    monitor_->Notify();
    ASSERT(initialized_);
    if (FLAG_trace_thread_interrupter) {
      OS::Print("ThreadInterrupter shutting down.\n");
    }
  }
#if defined(TARGET_OS_WINDOWS)
  // On Windows, a thread's exit-code can leak into the process's exit-code,
  // if exiting 'at same time' as the process ends. By joining with the thread
  // here, we avoid this race condition.
  ASSERT(interrupter_thread_id_ != Thread::kInvalidThreadId);
  Thread::Join(interrupter_thread_id_);
  interrupter_thread_id_ = Thread::kInvalidThreadId;
#else
  // On non-Windows platforms, just wait for the thread interrupter to signal
  // that it has exited the loop.
  {
    MonitorLocker shutdown_ml(monitor_);
    while (thread_running_) {
      // Wait for thread to exit.
      shutdown_ml.Wait();
    }
  }
#endif
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter shut down.\n");
  }
}

// Delay between interrupts.
void ThreadInterrupter::SetInterruptPeriod(intptr_t period) {
  if (shutdown_) {
    return;
  }
  ASSERT(initialized_);
  ASSERT(period > 0);
  interrupt_period_ = period;
}


void ThreadInterrupter::WakeUp() {
  ASSERT(initialized_);
  {
    MonitorLocker ml(monitor_);
    if (!InDeepSleep()) {
      // No need to notify, regularly waking up.
      return;
    }
    // Notify the interrupter to wake it from its deep sleep.
    ml.Notify();
  }
}

// Register the currently running thread for interrupts. If the current thread
// is already registered, callback and data will be updated.
InterruptableThreadState* ThreadInterrupter::Register(
    ThreadInterruptCallback callback, void* data) {
  if (shutdown_) {
    return NULL;
  }
  ASSERT(initialized_);
  InterruptableThreadState* state = _EnsureThreadStateCreated();
  // Set callback and data.
  UpdateStateObject(callback, data);
  return state;
}


// Unregister the currently running thread for interrupts.
void ThreadInterrupter::Unregister() {
  if (shutdown_) {
    return;
  }
  ASSERT(initialized_);
  _EnsureThreadStateCreated();
  // Clear callback and data.
  UpdateStateObject(NULL, NULL);
}


InterruptableThreadState* ThreadInterrupter::_EnsureThreadStateCreated() {
  InterruptableThreadState* state = CurrentThreadState();
  if (state == NULL) {
    // Create thread state object lazily.
    ThreadId current_thread = Thread::GetCurrentThreadId();
    if (FLAG_trace_thread_interrupter) {
      intptr_t tid = Thread::ThreadIdToIntPtr(current_thread);
      OS::Print("ThreadInterrupter Tracking %p\n",
                reinterpret_cast<void*>(tid));
    }
    // Note: We currently do not free a thread's InterruptableThreadState.
    state = new InterruptableThreadState();
    ASSERT(state != NULL);
    state->callback = NULL;
    state->data = NULL;
    state->id = current_thread;
    SetCurrentThreadState(state);
  }
  return state;
}


void ThreadInterrupter::UpdateStateObject(ThreadInterruptCallback callback,
                                          void* data) {
  InterruptableThreadState* state = CurrentThreadState();
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


InterruptableThreadState* ThreadInterrupter::GetCurrentThreadState() {
  return _EnsureThreadStateCreated();
}


InterruptableThreadState* ThreadInterrupter::CurrentThreadState() {
  InterruptableThreadState* state = reinterpret_cast<InterruptableThreadState*>(
      Thread::GetThreadLocal(thread_state_key_));
  return state;
}


void ThreadInterrupter::SetCurrentThreadState(InterruptableThreadState* state) {
  Thread::SetThreadLocal(thread_state_key_, reinterpret_cast<uword>(state));
}


void ThreadInterruptNoOp(const InterruptedThreadState& state, void* data) {
  // NoOp.
}


class ThreadInterrupterVisitIsolates : public IsolateVisitor {
 public:
  ThreadInterrupterVisitIsolates() {
    profiled_thread_count_ = 0;
  }

  void VisitIsolate(Isolate* isolate) {
    ASSERT(isolate != NULL);
    profiled_thread_count_ += isolate->ProfileInterrupt();
  }

  intptr_t profiled_thread_count() const {
    return profiled_thread_count_;
  }

  void set_profiled_thread_count(intptr_t profiled_thread_count) {
    profiled_thread_count_ = profiled_thread_count;
  }

 private:
  intptr_t profiled_thread_count_;
};


void ThreadInterrupter::ThreadMain(uword parameters) {
  ASSERT(initialized_);
  InstallSignalHandler();
  if (FLAG_trace_thread_interrupter) {
    OS::Print("ThreadInterrupter thread running.\n");
  }
  {
    // Signal to main thread we are ready.
    MonitorLocker startup_ml(monitor_);
    interrupter_thread_id_ = Thread::GetCurrentThreadId();
    thread_running_ = true;
    startup_ml.Notify();
  }
  {
    ThreadInterrupterVisitIsolates visitor;
    current_wait_time_ = interrupt_period_;
    MonitorLocker wait_ml(monitor_);
    while (!shutdown_) {
      intptr_t r = wait_ml.WaitMicros(current_wait_time_);

      if ((r == Monitor::kNotified) && InDeepSleep()) {
        // Woken up from deep sleep.
        ASSERT(visitor.profiled_thread_count() == 0);
        // Return to regular interrupts.
        current_wait_time_ = interrupt_period_;
      }

      // Reset count before visiting isolates.
      visitor.set_profiled_thread_count(0);
      Isolate::VisitIsolates(&visitor);

      if (visitor.profiled_thread_count() == 0) {
        // No isolates were profiled. In order to reduce unnecessary CPU
        // load, we will wait until we are notified before attempting to
        // interrupt again.
        current_wait_time_ = Monitor::kNoTimeout;
        continue;
      }

      ASSERT(current_wait_time_ != Monitor::kNoTimeout);
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
