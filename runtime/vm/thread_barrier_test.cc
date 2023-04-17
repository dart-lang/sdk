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
    barrier_->Release();
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
  const intptr_t kNumTasks = 5;
  const intptr_t kNumRounds = 500;

  ThreadBarrier* barrier = new ThreadBarrier(kNumTasks + 1, kNumTasks + 1);
  for (intptr_t i = 0; i < kNumTasks; ++i) {
    Dart::thread_pool()->Run<FuzzTask>(kNumRounds, barrier, i + 1);
  }
  for (intptr_t i = 0; i < kNumRounds; ++i) {
    barrier->Sync();
  }
  barrier->Release();
}

}  // namespace dart
