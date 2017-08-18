// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/thread_barrier.h"
#include "platform/assert.h"
#include "vm/random.h"
#include "vm/thread_pool.h"
#include "vm/unit_test.h"

namespace dart {

class FuzzTask : public ThreadPool::Task {
 public:
  FuzzTask(intptr_t num_rounds, ThreadBarrier* barrier, uint64_t seed)
      : num_rounds_(num_rounds), barrier_(barrier), rng_(seed) {}

  virtual void Run() {
    for (intptr_t i = 0; i < num_rounds_; ++i) {
      RandomSleep();
      barrier_->Sync();
    }
    barrier_->Exit();
  }

 private:
  void RandomSleep() {
    int64_t ms = rng_.NextUInt32() % 4;
    if (ms > 0) {
      OS::Sleep(ms);
    }
  }

  const intptr_t num_rounds_;
  ThreadBarrier* barrier_;
  Random rng_;
};

VM_UNIT_TEST_CASE(ThreadBarrier) {
  static const intptr_t kNumTasks = 5;
  static const intptr_t kNumRounds = 500;

  Monitor* monitor = new Monitor();
  Monitor* monitor_done = new Monitor();
  {
    ThreadBarrier barrier(kNumTasks + 1, monitor, monitor_done);
    for (intptr_t i = 0; i < kNumTasks; ++i) {
      Dart::thread_pool()->Run(new FuzzTask(kNumRounds, &barrier, i + 1));
    }
    for (intptr_t i = 0; i < kNumRounds; ++i) {
      barrier.Sync();
    }
    barrier.Exit();
  }

  delete monitor_done;
  delete monitor;
}

}  // namespace dart
