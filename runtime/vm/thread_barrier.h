// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_THREAD_BARRIER_H_
#define RUNTIME_VM_THREAD_BARRIER_H_

#include "vm/globals.h"
#include "vm/lockers.h"
#include "vm/os_thread.h"

namespace dart {

// Thread barrier with:
// * fixed (at construction) number n of participating threads {T1,T2,T3,...,Tn}
// * unknown number of rounds.
// Requirements:
// * there is some R such that each participating thread makes
//   R calls to Sync() followed by its one and only call to Exit().
// Guarantees:
// * for any two threads Ti and Tj and round number r <= R,
//   everything done by Ti before its r'th call to Sync() happens before
//   everything done by Tj after its r'th call to Sync().
// Note:
// * it's not required that the thread that constructs the barrier participates.
//
// Example usage with 3 threads (1 controller + 2 workers) and 3 rounds:
//
// T1:
// ThreadBarrier barrier(3);
// Dart::thread_pool()->Run(              T2:
//     new FooTask(&barrier));            fooSetup();
// Dart::thread_pool()->Run(              ...                T3:
//     new BarTask(&barrier));            ...                barSetup();
// barrier.Sync();                        barrier_->Sync();  barrier_->Sync();
// /* Both tasks have finished setup */   ...                ...
// prepareWorkForTasks();                 ...                ...
// barrier.Sync();                        barrier_->Sync();  barrier_->Sync();
// /* Idle while tasks are working */     fooWork();         barWork();
// barrier.Sync();                        barrier_->Sync();  barrier_->Sync();
// collectResultsFromTasks();             barrier_->Exit();  barrier_->Exit();
// barrier.Exit();
//
// Note that the calls to Sync() "line up" in time, but there is no such
// guarantee for Exit().
//
class ThreadBarrier {
 public:
  explicit ThreadBarrier(intptr_t num_threads,
                         Monitor* monitor,
                         Monitor* done_monitor)
      : num_threads_(num_threads),
        monitor_(monitor),
        remaining_(num_threads),
        parity_(false),
        done_monitor_(done_monitor),
        done_(false) {
    ASSERT(remaining_ > 0);
  }

  void Sync() {
    MonitorLocker ml(monitor_);
    ASSERT(remaining_ > 0);
    if (--remaining_ > 0) {
      // I'm not last to arrive; wait until next round.
      bool old_parity = parity_;
      while (parity_ == old_parity) {
        ml.Wait();
      }
    } else {
      // Last one to arrive initiates the next round.
      remaining_ = num_threads_;
      parity_ = !parity_;
      // Tell everyone else about the new round.
      ml.NotifyAll();
    }
  }

  void Exit() {
    bool last = false;
    {
      MonitorLocker ml(monitor_);
      ASSERT(remaining_ > 0);
      last = (--remaining_ == 0);
    }
    if (last) {
      // Last one to exit sets done_.
      MonitorLocker ml(done_monitor_);
      ASSERT(!done_);
      done_ = true;
      // Tell the destructor in case it's already waiting.
      ml.Notify();
    }
  }

  ~ThreadBarrier() {
    MonitorLocker ml(done_monitor_);
    // Wait for everyone to exit before destroying the monitors.
    while (!done_) {
      ml.Wait();
    }
    ASSERT(remaining_ == 0);
  }

 private:
  const intptr_t num_threads_;

  Monitor* monitor_;
  intptr_t remaining_;
  bool parity_;

  Monitor* done_monitor_;  // TODO(koda): Try to optimize this away.
  bool done_;

  DISALLOW_COPY_AND_ASSIGN(ThreadBarrier);
};

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_BARRIER_H_
