// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_INTERRUPTER_H_
#define VM_THREAD_INTERRUPTER_H_

#include "vm/allocation.h"
#include "vm/signal_handler.h"
#include "vm/thread.h"


namespace dart {

struct InterruptedThreadState {
  ThreadId tid;
  uintptr_t pc;
  uintptr_t csp;
  uintptr_t dsp;
  uintptr_t fp;
};

// When a thread is interrupted the thread specific interrupt callback will be
// invoked. Each callback is given an InterruptedThreadState and the user data
// pointer. When inside a thread interrupt callback doing any of the following
// is forbidden:
//   * Accessing TLS.
//   * Allocating memory.
//   * Taking a lock.
typedef void (*ThreadInterruptCallback)(const InterruptedThreadState& state,
                                        void* data);

// State stored per registered thread.
class InterruptableThreadState {
 public:
  ThreadId id;
  ThreadInterruptCallback callback;
  void* data;
};

class ThreadInterrupter : public AllStatic {
 public:
  static void InitOnce();

  static void Startup();
  static void Shutdown();

  // Delay between interrupts.
  static void SetInterruptPeriod(intptr_t period);

  // Wake up the thread interrupter thread.
  static void WakeUp();

  // Register the currently running thread for interrupts. If the current thread
  // is already registered, callback and data will be updated.
  static InterruptableThreadState* Register(ThreadInterruptCallback callback,
                                            void* data);
  // Unregister the currently running thread for interrupts.
  static void Unregister();

  // Get the current thread state. Will create a thread state if one hasn't
  // been allocated.
  static InterruptableThreadState* GetCurrentThreadState();
  // Get the current thread state. Will not create one if one doesn't exist.
  static InterruptableThreadState* CurrentThreadState();

  // Interrupt a thread.
  static void InterruptThread(InterruptableThreadState* thread_state);

 private:
  static const intptr_t kMaxThreads = 4096;
  static bool initialized_;
  static bool shutdown_;
  static bool thread_running_;
  static ThreadId interrupter_thread_id_;
  static Monitor* monitor_;
  static intptr_t interrupt_period_;
  static intptr_t current_wait_time_;
  static ThreadLocalKey thread_state_key_;

  static bool InDeepSleep() {
    return current_wait_time_ == Monitor::kNoTimeout;
  }

  static InterruptableThreadState* _EnsureThreadStateCreated();
  static void UpdateStateObject(ThreadInterruptCallback callback, void* data);

  static void SetCurrentThreadState(InterruptableThreadState* state);

  static void ThreadMain(uword parameters);

  static void InstallSignalHandler();

  friend class ThreadInterrupterVisitIsolates;
};

void ThreadInterruptNoOp(const InterruptedThreadState& state, void* data);

}  // namespace dart

#endif  // VM_THREAD_INTERRUPTER_H_
