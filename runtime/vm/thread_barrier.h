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
  explicit ThreadBarrier(intptr_t num_threads, intptr_t initial = 0)
      : ref_count_(num_threads),
        monitor_(),
        participating_(initial),
        remaining_(initial),
        generation_(0) {}

  bool TryEnter() {
    MonitorLocker ml(&monitor_);
    if (generation_ != 0) {
      return false;
    }
    remaining_++;
    participating_++;
    return true;
  }

  void Sync() {
    MonitorLocker ml(&monitor_);
    const intptr_t g = generation_;
    remaining_--;
    if (remaining_ == 0) {
      // I'm last, advance to the next generation and wake the others.
      generation_++;
      remaining_ = participating_;
      ml.NotifyAll();
    } else {
      // Waiting for others.
      while (g == generation_) {
        ml.Wait();
      }
    }
  }

  void Release() {
    intptr_t old = ref_count_.fetch_sub(1, std::memory_order_acq_rel);
    ASSERT(old > 0);
    if (old == 1) {
      delete this;
    }
  }

 private:
  std::atomic<intptr_t> ref_count_;

  Monitor monitor_;
  intptr_t participating_;
  intptr_t remaining_;
  intptr_t generation_;

  DISALLOW_COPY_AND_ASSIGN(ThreadBarrier);
};

}  // namespace dart

#endif  // RUNTIME_VM_THREAD_BARRIER_H_
