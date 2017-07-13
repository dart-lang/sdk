// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_THREAD_INTERRUPTER_H_
#define RUNTIME_VM_THREAD_INTERRUPTER_H_

#include "vm/allocation.h"
#include "vm/os_thread.h"
#include "vm/signal_handler.h"
#include "vm/thread.h"

namespace dart {

struct InterruptedThreadState {
  uintptr_t pc;
  uintptr_t csp;
  uintptr_t dsp;
  uintptr_t fp;
  uintptr_t lr;
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

  // Interrupt a thread.
  static void InterruptThread(OSThread* thread);

 private:
  static const intptr_t kMaxThreads = 4096;
  static bool initialized_;
  static bool shutdown_;
  static bool thread_running_;
  static bool woken_up_;
  static ThreadJoinId interrupter_thread_id_;
  static Monitor* monitor_;
  static intptr_t interrupt_period_;
  static intptr_t current_wait_time_;

  static bool IsDebuggerAttached();

  static bool InDeepSleep() {
    return current_wait_time_ == Monitor::kNoTimeout;
  }

  static void ThreadMain(uword parameters);

  static void InstallSignalHandler();

  static void RemoveSignalHandler();

  friend class ThreadInterrupterVisitIsolates;
};

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_INTERRUPTER_H_
