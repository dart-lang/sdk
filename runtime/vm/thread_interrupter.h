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
  static void Init();

  static void Startup();
  static void Cleanup();

  // Delay between interrupts.
  static void SetInterruptPeriod(intptr_t period);

  // Wake up the thread interrupter thread.
  static void WakeUp();

  // Interrupt a thread.
  static void InterruptThread(OSThread* thread);

  class SampleBufferWriterScope : public ValueObject {
   public:
    SampleBufferWriterScope() {
      intptr_t old_value = sample_buffer_lock_.load(std::memory_order_relaxed);
      intptr_t new_value;
      do {
        if (old_value < 0) {
          entered_lock_ = false;
          return;
        }
        new_value = old_value + 1;
      } while (!sample_buffer_lock_.compare_exchange_weak(
          old_value, new_value, std::memory_order_acquire));
      entered_lock_ = true;
    }

    ~SampleBufferWriterScope() {
      if (!entered_lock_) return;
      intptr_t old_value = sample_buffer_lock_.load(std::memory_order_relaxed);
      intptr_t new_value;
      do {
        ASSERT(old_value > 0);
        new_value = old_value - 1;
      } while (!sample_buffer_lock_.compare_exchange_weak(
          old_value, new_value, std::memory_order_release));
    }

    bool CanSample() const {
      return entered_lock_ &&
             sample_buffer_waiters_.load(std::memory_order_relaxed) == 0;
    }

   private:
    bool entered_lock_;
    DISALLOW_COPY_AND_ASSIGN(SampleBufferWriterScope);
  };

  class SampleBufferReaderScope : public ValueObject {
   public:
    SampleBufferReaderScope() { EnterSampleReader(); }
    ~SampleBufferReaderScope() { ExitSampleReader(); }

   private:
    DISALLOW_COPY_AND_ASSIGN(SampleBufferReaderScope);
  };

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

  // Something like a reader-writer lock. Positive values indictate there are
  // outstanding signal handlers that can write to the sample buffer. Negative
  // values indicate there are outstanding sample buffer processors that can
  // read from the sample buffer. A reader will spin-wait to enter the lock. A
  // writer will give up if it fails to enter lock, causing samples to be
  // skipping while we are processing the sample buffer or trying to shut down.
  static std::atomic<intptr_t> sample_buffer_lock_;
  static std::atomic<intptr_t> sample_buffer_waiters_;

  static bool IsDebuggerAttached();

  static bool InDeepSleep() {
    return current_wait_time_ == Monitor::kNoTimeout;
  }

  static void ThreadMain(uword parameters);

  static void InstallSignalHandler();

  static void RemoveSignalHandler();

  static void EnterSampleReader() {
    sample_buffer_waiters_.fetch_add(1, std::memory_order_relaxed);

    intptr_t old_value = sample_buffer_lock_.load(std::memory_order_relaxed);
    intptr_t new_value;
    do {
      if (old_value > 0) {
        old_value = sample_buffer_lock_.load(std::memory_order_relaxed);
        continue;  // Spin waiting for outstanding SIGPROFs to complete.
      }
      new_value = old_value - 1;
    } while (!sample_buffer_lock_.compare_exchange_weak(
        old_value, new_value, std::memory_order_acquire));
  }

  static void ExitSampleReader() {
    sample_buffer_waiters_.fetch_sub(1, std::memory_order_relaxed);

    intptr_t old_value = sample_buffer_lock_.load(std::memory_order_relaxed);
    intptr_t new_value;
    do {
      ASSERT(old_value < 0);
      new_value = old_value + 1;
    } while (!sample_buffer_lock_.compare_exchange_weak(
        old_value, new_value, std::memory_order_release));
  }

  friend class ThreadInterrupterVisitIsolates;
};

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_INTERRUPTER_H_
