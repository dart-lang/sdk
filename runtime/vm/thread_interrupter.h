// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_THREAD_INTERRUPTER_H_
#define VM_THREAD_INTERRUPTER_H_

#include "vm/allocation.h"
#include "vm/signal_handler.h"
#include "vm/os_thread.h"
#include "vm/thread.h"

namespace dart {

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
  static void Register(ThreadInterruptCallback callback, void* data);

  // Unregister the currently running thread for interrupts.
  static void Unregister();

  // Interrupt a thread.
  static void InterruptThread(Thread* thread);

 private:
  static const intptr_t kMaxThreads = 4096;
  static bool initialized_;
  static bool shutdown_;
  static bool thread_running_;
  static ThreadId interrupter_thread_id_;
  static Monitor* monitor_;
  static intptr_t interrupt_period_;
  static intptr_t current_wait_time_;

  static bool InDeepSleep() {
    return current_wait_time_ == Monitor::kNoTimeout;
  }

  static void UpdateStateObject(ThreadInterruptCallback callback, void* data);

  static void ThreadMain(uword parameters);

  static void InstallSignalHandler();

  static void RemoveSignalHandler();

  friend class ThreadInterrupterVisitIsolates;
};

void ThreadInterruptNoOp(const InterruptedThreadState& state, void* data);

}  // namespace dart

#endif  // VM_THREAD_INTERRUPTER_H_
