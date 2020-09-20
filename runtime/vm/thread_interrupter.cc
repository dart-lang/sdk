// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_interrupter.h"

#include "vm/flags.h"
#include "vm/lockers.h"
#include "vm/os.h"
#include "vm/simulator.h"

namespace dart {

#ifndef PRODUCT

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

DEFINE_FLAG(bool, trace_thread_interrupter, false, "Trace thread interrupter");

bool ThreadInterrupter::initialized_ = false;
bool ThreadInterrupter::shutdown_ = false;
bool ThreadInterrupter::thread_running_ = false;
bool ThreadInterrupter::woken_up_ = false;
ThreadJoinId ThreadInterrupter::interrupter_thread_id_ =
    OSThread::kInvalidThreadJoinId;
Monitor* ThreadInterrupter::monitor_ = NULL;
intptr_t ThreadInterrupter::interrupt_period_ = 1000;
intptr_t ThreadInterrupter::current_wait_time_ = Monitor::kNoTimeout;
// Note this initial state means there is one sample buffer reader. This
// allows the EnterSampleReader during Cleanup (needed to ensure the buffer can
// be safely freed) to be balanced by a ExitSampleReader during Init.
std::atomic<intptr_t> ThreadInterrupter::sample_buffer_lock_ = {-1};
std::atomic<intptr_t> ThreadInterrupter::sample_buffer_waiters_ = {1};

void ThreadInterrupter::Init() {
  ASSERT(!initialized_);
  if (monitor_ == NULL) {
    monitor_ = new Monitor();
  }
  ASSERT(monitor_ != NULL);
  initialized_ = true;
  shutdown_ = false;
}

void ThreadInterrupter::Startup() {
  ASSERT(initialized_);
  if (IsDebuggerAttached()) {
    MonitorLocker shutdown_ml(monitor_);
    shutdown_ = true;
    if (FLAG_trace_thread_interrupter) {
      OS::PrintErr(
          "ThreadInterrupter disabled because a debugger is attached.\n");
    }
    return;
  }
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter starting up.\n");
  }
  ASSERT(interrupter_thread_id_ == OSThread::kInvalidThreadJoinId);
  {
    MonitorLocker startup_ml(monitor_);
    OSThread::Start("Dart Profiler ThreadInterrupter", ThreadMain, 0);
    while (!thread_running_) {
      startup_ml.Wait();
    }
  }
  ASSERT(interrupter_thread_id_ != OSThread::kInvalidThreadJoinId);
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter running.\n");
  }

  ExitSampleReader();
}

void ThreadInterrupter::Cleanup() {
  {
    MonitorLocker shutdown_ml(monitor_);
    if (shutdown_) {
      // Already shutdown.
      return;
    }
    shutdown_ = true;
    // Notify.
    shutdown_ml.Notify();
    ASSERT(initialized_);
    if (FLAG_trace_thread_interrupter) {
      OS::PrintErr("ThreadInterrupter shutting down.\n");
    }
  }

  // Join the thread.
  ASSERT(interrupter_thread_id_ != OSThread::kInvalidThreadJoinId);
  OSThread::Join(interrupter_thread_id_);
  interrupter_thread_id_ = OSThread::kInvalidThreadJoinId;
  initialized_ = false;

  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter shut down.\n");
  }

  // Wait for outstanding signals.
  EnterSampleReader();
}

// Delay between interrupts.
void ThreadInterrupter::SetInterruptPeriod(intptr_t period) {
  if (!initialized_) {
    // Profiler may not be enabled.
    return;
  }
  MonitorLocker ml(monitor_);
  if (shutdown_) {
    return;
  }
  ASSERT(initialized_);
  ASSERT(period > 0);
  interrupt_period_ = period;
}

void ThreadInterrupter::WakeUp() {
  if (monitor_ == NULL) {
    // Early call.
    return;
  }
  {
    MonitorLocker ml(monitor_);
    if (shutdown_) {
      // Late call
      return;
    }
    if (!initialized_) {
      // Early call.
      return;
    }
    woken_up_ = true;
    if (!InDeepSleep()) {
      // No need to notify, regularly waking up.
      return;
    }
    // Notify the interrupter to wake it from its deep sleep.
    ml.Notify();
  }
}

void ThreadInterrupter::ThreadMain(uword parameters) {
  ASSERT(initialized_);
  InstallSignalHandler();
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter thread running.\n");
  }
  {
    // Signal to main thread we are ready.
    MonitorLocker startup_ml(monitor_);
    OSThread* os_thread = OSThread::Current();
    ASSERT(os_thread != NULL);
    interrupter_thread_id_ = OSThread::GetCurrentThreadJoinId(os_thread);
    thread_running_ = true;
    startup_ml.Notify();
  }
  {
    intptr_t interrupted_thread_count = 0;
    MonitorLocker wait_ml(monitor_);
    current_wait_time_ = interrupt_period_;
    while (!shutdown_) {
      intptr_t r = wait_ml.WaitMicros(current_wait_time_);

      if (shutdown_) {
        break;
      }

      if ((r == Monitor::kNotified) && InDeepSleep()) {
        // Woken up from deep sleep.
        ASSERT(interrupted_thread_count == 0);
        // Return to regular interrupts.
        current_wait_time_ = interrupt_period_;
      } else if (current_wait_time_ != interrupt_period_) {
        // The interrupt period may have been updated via the service protocol.
        current_wait_time_ = interrupt_period_;
      }

      // Reset count before interrupting any threads.
      interrupted_thread_count = 0;

      // Temporarily drop the monitor while we interrupt threads.
      wait_ml.Exit();

      {
        OSThreadIterator it;
        while (it.HasNext()) {
          OSThread* thread = it.Next();
          if (thread->ThreadInterruptsEnabled()) {
            interrupted_thread_count++;
            InterruptThread(thread);
          }
        }
      }

      // Take the monitor lock again.
      wait_ml.Enter();

      // Now that we have the lock, check if we were signaled to wake up while
      // interrupting threads.
      if (!woken_up_ && (interrupted_thread_count == 0)) {
        // No threads were interrupted and we were not signaled to interrupt
        // new threads. In order to reduce unnecessary CPU load, we will wait
        // until we are notified before attempting to interrupt again.
        current_wait_time_ = Monitor::kNoTimeout;
        continue;
      }

      woken_up_ = false;

      ASSERT(current_wait_time_ != Monitor::kNoTimeout);
    }
  }
  RemoveSignalHandler();
  if (FLAG_trace_thread_interrupter) {
    OS::PrintErr("ThreadInterrupter thread exiting.\n");
  }
  {
    // Signal to main thread we are exiting.
    MonitorLocker shutdown_ml(monitor_);
    thread_running_ = false;
    shutdown_ml.Notify();
  }
}

#endif  // !PRODUCT

}  // namespace dart
