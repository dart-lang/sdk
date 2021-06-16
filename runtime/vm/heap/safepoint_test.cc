// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>
#include <utility>
#include <vector>

#include "platform/assert.h"

#include "vm/heap/safepoint.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/random.h"
#include "vm/thread_pool.h"
#include "vm/unit_test.h"

namespace dart {

class StateMachineTask : public ThreadPool::Task {
 public:
  enum State {
    kInitialized = 0,
    kEntered,
    kPleaseExit,
    kExited,
    kNext,
  };
  struct Data {
    explicit Data(IsolateGroup* isolate_group)
        : isolate_group_(isolate_group) {}

    void WaitUntil(intptr_t target_state) {
      MonitorLocker ml(&monitor_);
      while (state != target_state) {
        ml.Wait();
      }
    }
    void MarkAndNotify(intptr_t target_state) {
      MonitorLocker ml(&monitor_);
      state = target_state;
      ml.Notify();
    }
    void AssertIsIn(intptr_t expected_state) {
      MonitorLocker ml(&monitor_);
      EXPECT_EQ(expected_state, state);
    }
    void AssertIsNotIn(intptr_t expected_state) {
      MonitorLocker ml(&monitor_);
      EXPECT_NE(expected_state, state);
    }
    bool IsIn(intptr_t expected_state) {
      MonitorLocker ml(&monitor_);
      return expected_state == state;
    }

    intptr_t state = kInitialized;
    IsolateGroup* isolate_group_;

   private:
    Monitor monitor_;
  };

  explicit StateMachineTask(std::shared_ptr<Data> data)
      : data_(std::move(data)) {}

  virtual void Run() {
    const bool kBypassSafepoint = false;
    Thread::EnterIsolateGroupAsHelper(data_->isolate_group_,
                                      Thread::kUnknownTask, kBypassSafepoint);
    thread_ = Thread::Current();
    data_->MarkAndNotify(kEntered);
    RunInternal();
    data_->WaitUntil(kPleaseExit);
    Thread::ExitIsolateGroupAsHelper(kBypassSafepoint);
    thread_ = nullptr;
    data_->MarkAndNotify(kExited);
  }

 protected:
  virtual void RunInternal() = 0;

  std::shared_ptr<Data> data_;
  Thread* thread_ = nullptr;
};

class DeoptTask : public StateMachineTask {
 public:
  enum State {
    kStartDeoptOperation = StateMachineTask::kNext,
    kFinishedDeoptOperation,
  };

  explicit DeoptTask(std::shared_ptr<Data> data)
      : StateMachineTask(std::move(data)) {}

 protected:
  virtual void RunInternal() {
    data_->WaitUntil(kStartDeoptOperation);
    { DeoptSafepointOperationScope safepoint_operation(thread_); }
    data_->MarkAndNotify(kFinishedDeoptOperation);
  }
};

class GcWithoutDeoptTask : public StateMachineTask {
 public:
  enum State {
    kStartSafepointOperation = StateMachineTask::kNext,
    kEndSafepointOperation,
    kJoinDeoptOperation,
    kDeoptOperationDone,
  };

  explicit GcWithoutDeoptTask(std::shared_ptr<Data> data)
      : StateMachineTask(std::move(data)) {}

 protected:
  virtual void RunInternal() {
    data_->WaitUntil(kStartSafepointOperation);
    {
      RuntimeCallDeoptScope no_deopt(thread_,
                                     RuntimeCallDeoptAbility::kCannotLazyDeopt);
      GcSafepointOperationScope safepoint_operation(thread_);
    }
    data_->MarkAndNotify(kEndSafepointOperation);

    data_->WaitUntil(kJoinDeoptOperation);
    EXPECT(thread_->IsSafepointRequested());
    thread_->BlockForSafepoint();
    data_->MarkAndNotify(kDeoptOperationDone);
  }
};

// This test ensures that while a "deopt safepoint operation" is about to start
// but is still waiting for some threads to hit a "deopt safepoint" another
// safepoint operation can sucessfully start and finish.
ISOLATE_UNIT_TEST_CASE(
    SafepointOperation_SafepointOpWhileDeoptSafepointOpBlocked) {
  auto isolate_group = thread->isolate_group();

  std::shared_ptr<DeoptTask::Data> deopt(new DeoptTask::Data(isolate_group));
  std::shared_ptr<GcWithoutDeoptTask::Data> gc(
      new GcWithoutDeoptTask::Data(isolate_group));

  thread->EnterSafepoint();
  {
    // Will join outstanding threads on destruction.
    ThreadPool pool;

    pool.Run<DeoptTask>(deopt);
    pool.Run<GcWithoutDeoptTask>(gc);

    // Wait until both threads entered the isolate group.
    deopt->WaitUntil(DeoptTask::kEntered);
    gc->WaitUntil(GcWithoutDeoptTask::kEntered);

    // Let deopt task start deopt operation scope (it will block in
    // [SafepointOperationScope] constructor until all threads have checked-in).
    deopt->MarkAndNotify(DeoptTask::kStartDeoptOperation);
    OS::Sleep(200);  // Give it time to actually start the deopt operation

    // Now let the other thread do a full safepoint operation and wait until
    // it's done: We want to ensure that we can do normal safepoint operations
    // while a deopt operation is being started and is waiting for all mutators
    // to reach an appropriate place where they can be deopted.
    gc->MarkAndNotify(GcWithoutDeoptTask::kStartSafepointOperation);
    gc->WaitUntil(GcWithoutDeoptTask::kEndSafepointOperation);

    // We were sucessfully doing a safepoint operation, now let's ensure the
    // first thread is still stuck in the starting of deopt operation.
    deopt->AssertIsIn(DeoptTask::kStartDeoptOperation);

    // Now we'll let the other thread check-in and ensure the deopt operation
    // proceeded and finished.
    gc->MarkAndNotify(GcWithoutDeoptTask::kJoinDeoptOperation);
    gc->WaitUntil(GcWithoutDeoptTask::kDeoptOperationDone);
    deopt->WaitUntil(DeoptTask::kFinishedDeoptOperation);

    // Make both threads exit the isolate group.
    deopt->MarkAndNotify(DeoptTask::kPleaseExit);
    gc->MarkAndNotify(GcWithoutDeoptTask::kPleaseExit);

    deopt->WaitUntil(DeoptTask::kExited);
    gc->WaitUntil(GcWithoutDeoptTask::kExited);
  }
  thread->ExitSafepoint();
}

class LongDeoptTask : public StateMachineTask {
 public:
  enum State {
    kStartDeoptOperation = StateMachineTask::kNext,
    kInsideDeoptOperation,
    kFinishDeoptOperation,
    kFinishedDeoptOperation,
  };

  explicit LongDeoptTask(std::shared_ptr<Data> data)
      : StateMachineTask(std::move(data)) {}

 protected:
  virtual void RunInternal() {
    data_->WaitUntil(kStartDeoptOperation);
    {
      DeoptSafepointOperationScope safepoint_operation(thread_);
      data_->MarkAndNotify(kInsideDeoptOperation);
      data_->WaitUntil(kFinishDeoptOperation);
    }
    data_->MarkAndNotify(kFinishedDeoptOperation);
  }
};

class WaiterTask : public StateMachineTask {
 public:
  enum State {
    kEnterSafepoint = StateMachineTask::kNext,
    kInsideSafepoint,
    kPleaseExitSafepoint,
    kExitedSafepoint,
  };

  explicit WaiterTask(std::shared_ptr<Data> data)
      : StateMachineTask(std::move(data)) {}

 protected:
  virtual void RunInternal() {
    data_->WaitUntil(kEnterSafepoint);
    thread_->EnterSafepoint();
    data_->MarkAndNotify(kInsideSafepoint);
    data_->WaitUntil(kPleaseExitSafepoint);
    thread_->ExitSafepoint();
    data_->MarkAndNotify(kExitedSafepoint);
  }
};

// This test ensures that while a "deopt safepoint operation" is in-progress
// other threads cannot perform a normal "safepoint operation".
ISOLATE_UNIT_TEST_CASE(
    SafepointOperation_SafepointOpBlockedWhileDeoptSafepointOp) {
  auto isolate_group = thread->isolate_group();

  std::shared_ptr<LongDeoptTask::Data> deopt(
      new LongDeoptTask::Data(isolate_group));
  std::shared_ptr<WaiterTask::Data> gc(new WaiterTask::Data(isolate_group));

  thread->EnterSafepoint();
  {
    // Will join outstanding threads on destruction.
    ThreadPool pool;

    pool.Run<LongDeoptTask>(deopt);
    pool.Run<WaiterTask>(gc);

    // Wait until both threads entered the isolate group.
    deopt->WaitUntil(LongDeoptTask::kEntered);
    gc->WaitUntil(WaiterTask::kEntered);

    // Let gc task enter safepoint.
    gc->MarkAndNotify(WaiterTask::kEnterSafepoint);
    gc->WaitUntil(WaiterTask::kInsideSafepoint);

    // Now let the "deopt operation" run and block.
    deopt->MarkAndNotify(LongDeoptTask::kStartDeoptOperation);
    deopt->WaitUntil(LongDeoptTask::kInsideDeoptOperation);

    // Now let the gc task try to exit safepoint and do it's own safepoint
    // operation: We expect it to block on exiting safepoint, since the deopt
    // operation is still ongoing.
    gc->MarkAndNotify(WaiterTask::kPleaseExitSafepoint);
    OS::Sleep(200);
    gc->AssertIsNotIn(WaiterTask::kExitedSafepoint);

    // Now let's finish the deopt operation & ensure the waiter thread made
    // progress.
    deopt->MarkAndNotify(LongDeoptTask::kFinishDeoptOperation);
    gc->WaitUntil(WaiterTask::kExitedSafepoint);

    // Make both threads exit the isolate group.
    deopt->MarkAndNotify(LongDeoptTask::kPleaseExit);
    gc->MarkAndNotify(WaiterTask::kPleaseExit);

    deopt->WaitUntil(LongDeoptTask::kExited);
    gc->WaitUntil(WaiterTask::kExited);
  }
  thread->ExitSafepoint();
}

class CheckinTask : public StateMachineTask {
 public:
  enum State {
    kStartLoop = StateMachineTask::kNext,
  };

  struct Data : public StateMachineTask::Data {
    Data(IsolateGroup* isolate_group,
         SafepointLevel level,
         std::atomic<intptr_t>* gc_only_checkins,
         std::atomic<intptr_t>* deopt_checkin)
        : StateMachineTask::Data(isolate_group),
          level(level),
          gc_only_checkins(gc_only_checkins),
          deopt_checkin(deopt_checkin) {}

    SafepointLevel level;
    std::atomic<intptr_t>* gc_only_checkins;
    std::atomic<intptr_t>* deopt_checkin;
  };

  explicit CheckinTask(std::shared_ptr<Data> data) : StateMachineTask(data) {}

 protected:
  Data* data() { return reinterpret_cast<Data*>(data_.get()); }

  virtual void RunInternal() {
    data_->WaitUntil(kStartLoop);

    uword last_sync = OS::GetCurrentTimeMillis();
    while (!data()->IsIn(kPleaseExit)) {
      switch (data()->level) {
        case SafepointLevel::kGC: {
          // This thread should join only GC safepoint operations.
          RuntimeCallDeoptScope no_deopt(
              Thread::Current(), RuntimeCallDeoptAbility::kCannotLazyDeopt);
          SafepointIfRequested(thread_, data()->gc_only_checkins);
          break;
        }
        case SafepointLevel::kGCAndDeopt: {
          // This thread should join any safepoint operations.
          SafepointIfRequested(thread_, data()->deopt_checkin);
          break;
        }
        case SafepointLevel::kNumLevels:
          UNREACHABLE();
      }

      // If we are asked to join a deopt safepoint operation we will comply with
      // that but only every second.
      const auto now = OS::GetCurrentTimeMillis();
      if ((now - last_sync) > 200) {
        thread_->EnterSafepoint();
        thread_->ExitSafepoint();
        last_sync = now;
      }
    }
  }

  void SafepointIfRequested(Thread* thread, std::atomic<intptr_t>* checkins) {
    OS::SleepMicros(10);
    if (thread->IsSafepointRequested()) {
      // Collaborates by checking into the safepoint.
      thread->BlockForSafepoint();
      (*checkins)++;
    }
  }
};

// Test that mutators will not check-in to "deopt safepoint operations" at
// at places where the mutator cannot depot (which is indicated by the
// Thread::runtime_call_kind_ value).
ISOLATE_UNIT_TEST_CASE(SafepointOperation_SafepointPointTest) {
  auto isolate_group = thread->isolate_group();

  const intptr_t kTaskCount = 5;
  std::atomic<intptr_t> gc_only_checkins[kTaskCount];
  std::atomic<intptr_t> deopt_checkin[kTaskCount];
  for (intptr_t i = 0; i < kTaskCount; ++i) {
    gc_only_checkins[i] = 0;
    deopt_checkin[i] = 0;
  }

  std::vector<std::shared_ptr<CheckinTask::Data>> threads;
  for (intptr_t i = 0; i < kTaskCount; ++i) {
    const auto level =
        (i % 2) == 0 ? SafepointLevel::kGC : SafepointLevel::kGCAndDeopt;
    std::unique_ptr<CheckinTask::Data> data(new CheckinTask::Data(
        isolate_group, level, &gc_only_checkins[i], &deopt_checkin[i]));
    threads.push_back(std::move(data));
  }

  {
    // Will join outstanding threads on destruction.
    ThreadPool pool;

    for (intptr_t i = 0; i < kTaskCount; i++) {
      pool.Run<CheckinTask>(threads[i]);
    }
    for (intptr_t i = 0; i < kTaskCount; i++) {
      threads[i]->WaitUntil(CheckinTask::kEntered);
    }
    for (intptr_t i = 0; i < kTaskCount; i++) {
      threads[i]->MarkAndNotify(CheckinTask::kStartLoop);
    }
    {
      { GcSafepointOperationScope safepoint_operation(thread); }
      OS::SleepMicros(500);
      { DeoptSafepointOperationScope safepoint_operation(thread); }
      OS::SleepMicros(500);
      { GcSafepointOperationScope safepoint_operation(thread); }
      OS::SleepMicros(500);
      { DeoptSafepointOperationScope safepoint_operation(thread); }
    }
    for (intptr_t i = 0; i < kTaskCount; i++) {
      threads[i]->MarkAndNotify(CheckinTask::kPleaseExit);
    }
    for (intptr_t i = 0; i < kTaskCount; i++) {
      threads[i]->WaitUntil(CheckinTask::kExited);
    }
    for (intptr_t i = 0; i < kTaskCount; ++i) {
      const auto level =
          (i % 2) == 0 ? SafepointLevel::kGC : SafepointLevel::kGCAndDeopt;
      switch (level) {
        case SafepointLevel::kGC:
          EXPECT_EQ(0, deopt_checkin[i]);
          EXPECT_EQ(2, gc_only_checkins[i]);
          break;
        case SafepointLevel::kGCAndDeopt:
          EXPECT_EQ(4, deopt_checkin[i]);
          EXPECT_EQ(0, gc_only_checkins[i]);
          break;
        case SafepointLevel::kNumLevels:
          UNREACHABLE();
      }
    }
  }
}

class StressTask : public StateMachineTask {
 public:
  enum State {
    kStart = StateMachineTask::kNext,
  };

  explicit StressTask(std::shared_ptr<Data> data) : StateMachineTask(data) {}

 protected:
  Data* data() { return reinterpret_cast<Data*>(data_.get()); }

  virtual void RunInternal() {
    data_->WaitUntil(kStart);

    Random random(thread_->isolate_group()->random()->NextUInt64());
    while (!data()->IsIn(kPleaseExit)) {
      const auto us = random.NextUInt32() % 3;
      switch (random.NextUInt32() % 5) {
        case 0: {
          DeoptSafepointOperationScope safepoint_op(thread_);
          OS::SleepMicros(us);
          break;
        }
        case 1: {
          GcSafepointOperationScope safepoint_op(thread_);
          OS::SleepMicros(us);
          break;
        }
        case 2: {
          const bool kBypassSafepoint = false;
          Thread::ExitIsolateGroupAsHelper(kBypassSafepoint);
          OS::SleepMicros(us);
          Thread::EnterIsolateGroupAsHelper(
              data_->isolate_group_, Thread::kUnknownTask, kBypassSafepoint);
          thread_ = Thread::Current();
          break;
        }
        case 3: {
          thread_->EnterSafepoint();
          OS::SleepMicros(us);
          thread_->ExitSafepoint();
          break;
        }
        case 4: {
          if (thread_->IsSafepointRequested()) {
            thread_->BlockForSafepoint();
          }
          break;
        }
      }
    }
  }
};

ISOLATE_UNIT_TEST_CASE(SafepointOperation_StressTest) {
  auto isolate_group = thread->isolate_group();

  const intptr_t kTaskCount = 5;

  std::vector<std::shared_ptr<StressTask::Data>> threads;
  for (intptr_t i = 0; i < kTaskCount; ++i) {
    std::unique_ptr<StressTask::Data> data(new StressTask::Data(isolate_group));
    threads.push_back(std::move(data));
  }

  thread->EnterSafepoint();
  {
    // Will join outstanding threads on destruction.
    ThreadPool pool;

    for (intptr_t i = 0; i < kTaskCount; i++) {
      pool.Run<StressTask>(threads[i]);
    }
    for (intptr_t i = 0; i < kTaskCount; i++) {
      threads[i]->WaitUntil(StressTask::kEntered);
    }
    for (intptr_t i = 0; i < kTaskCount; i++) {
      threads[i]->MarkAndNotify(StressTask::kStart);
    }
    OS::Sleep(3 * 1000);
    for (intptr_t i = 0; i < kTaskCount; i++) {
      threads[i]->MarkAndNotify(StressTask::kPleaseExit);
    }
    for (intptr_t i = 0; i < kTaskCount; i++) {
      threads[i]->WaitUntil(StressTask::kExited);
    }
  }
  thread->ExitSafepoint();
}

ISOLATE_UNIT_TEST_CASE(SafepointOperation_DeoptAndNonDeoptNesting) {
  {
    DeoptSafepointOperationScope safepoint_scope(thread);
    DeoptSafepointOperationScope safepoint_scope2(thread);
    GcSafepointOperationScope safepoint_scope3(thread);
    GcSafepointOperationScope safepoint_scope4(thread);
  }
  {
    DeoptSafepointOperationScope safepoint_scope(thread);
    GcSafepointOperationScope safepoint_scope2(thread);
  }
}

ISOLATE_UNIT_TEST_CASE_WITH_EXPECTATION(
    SafepointOperation_NonDeoptAndDeoptNesting,
    "Crash") {
  GcSafepointOperationScope safepoint_scope(thread);
  DeoptSafepointOperationScope safepoint_scope2(thread);
}

}  // namespace dart
