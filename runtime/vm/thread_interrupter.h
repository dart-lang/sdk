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
  uintptr_t sp;
  uintptr_t fp;
};

// When a thread is interrupted the thread specific interrupt
// callback will be invoked at the interrupt period. Each callback is given an
// InterruptedThreadState and the thread specific data pointer. When inside a
// thread interrupt callback doing any of the following
// is forbidden:
//   * Accessing TLS.
//   * Allocating memory.
//   * Taking a lock.
typedef void (*ThreadInterruptCallback)(const InterruptedThreadState& state,
                                        void* data);

class ThreadInterrupter : public AllStatic {
 public:
  static void InitOnce();
  static void Shutdown();

  // Delay between interrupts.
  static void SetInterruptPeriod(intptr_t period);

  // Register the currently running thread for interrupts. If the current thread
  // is already registered, callback and data will be updated.
  static void Register(ThreadInterruptCallback callback, void* data);
  // Unregister the currently running thread for interrupts.
  static void Unregister();

  // Enable interrupts for this thread. Does not alter callback.
  static void Enable();
  // Disable interrupts for this thread. Does not alter callback.
  static void Disable();

 private:
  static const intptr_t kMaxThreads = 4096;
  static bool initialized_;
  static bool shutdown_;
  static bool thread_running_;
  static ThreadId interrupter_thread_id_;
  static Monitor* monitor_;
  static intptr_t interrupt_period_;
  static ThreadLocalKey thread_state_key_;
  // State stored per registered thread.
  struct ThreadState {
    ThreadId id;
    ThreadInterruptCallback callback;
    void* data;
  };

  static void UpdateStateObject(ThreadInterruptCallback callback, void* data);
  static ThreadState* CurrentThreadState();
  static void SetCurrentThreadState(ThreadState* state);

  // Registered thread table.
  static ThreadState** threads_;
  static intptr_t threads_capacity_;
  static intptr_t threads_size_;
  static void _EnsureThreadStateCreated();
  static void _Enable();
  static void _Disable();
  static void ResizeThreads(intptr_t new_capacity);
  static void AddThread(ThreadId id);
  static intptr_t FindThreadIndex(ThreadId id);
  static ThreadState* RemoveThread(intptr_t i);

  friend class ThreadInterrupterAndroid;
  friend class ThreadInterrupterMacOS;
  friend class ThreadInterrupterLinux;
  friend class ThreadInterrupterWin;

  static void InterruptThreads(int64_t current_time);
  static void ThreadMain(uword parameters);

  static void InstallSignalHandler();
};

void ThreadInterruptNoOp(const InterruptedThreadState& state, void* data);

}  // namespace dart

#endif  // VM_THREAD_INTERRUPTER_H_
