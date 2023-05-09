// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>
#include <utility>
#include <vector>

#include "platform/assert.h"

#include "vm/heap/safepoint.h"
#include "vm/isolate.h"
#include "vm/isolate_reload.h"
#include "vm/lockers.h"
#include "vm/message_handler.h"
#include "vm/message_snapshot.h"
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
// safepoint operation can successfully start and finish.
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

    // We were successfully doing a safepoint operation, now let's ensure the
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
         std::atomic<intptr_t>* deopt_checkin,
         std::atomic<intptr_t>* reload_checkin,
         std::atomic<intptr_t>* timeout_checkin)
        : StateMachineTask::Data(isolate_group),
          level(level),
          gc_only_checkins(gc_only_checkins),
          deopt_checkin(deopt_checkin),
          reload_checkin(reload_checkin),
          timeout_checkin(timeout_checkin) {}

    SafepointLevel level;
    std::atomic<intptr_t>* gc_only_checkins;
    std::atomic<intptr_t>* deopt_checkin;
    std::atomic<intptr_t>* reload_checkin;
    std::atomic<intptr_t>* timeout_checkin;
  };

  explicit CheckinTask(std::shared_ptr<Data> data) : StateMachineTask(data) {}

 protected:
  Data* data() { return reinterpret_cast<Data*>(data_.get()); }

  virtual void RunInternal() {
    data_->WaitUntil(kStartLoop);

    uword last_sync = OS::GetCurrentTimeMillis();
    while (!data()->IsIn(kPleaseExit)) {
      OS::SleepMicros(100);  // Make test avoid consuming 100% CPU x kTaskCount.
      switch (data()->level) {
        case SafepointLevel::kGC: {
          // This thread should join only GC safepoint operations.
          RuntimeCallDeoptScope no_deopt(
              Thread::Current(), RuntimeCallDeoptAbility::kCannotLazyDeopt);
          if (SafepointIfRequested(thread_, data()->gc_only_checkins)) {
            last_sync = OS::GetCurrentTimeMillis();
          }
          break;
        }
        case SafepointLevel::kGCAndDeopt: {
          // This thread should join only GC and Deopt safepoint operations.
          if (SafepointIfRequested(thread_, data()->deopt_checkin)) {
            last_sync = OS::GetCurrentTimeMillis();
          }
          break;
        }
        case SafepointLevel::kGCAndDeoptAndReload: {
          // This thread should join any safepoint operations.
          ReloadParticipationScope allow_reload(thread_);
          if (SafepointIfRequested(thread_, data()->reload_checkin)) {
            last_sync = OS::GetCurrentTimeMillis();
          }
          break;
        }
        case SafepointLevel::kNumLevels:
        case SafepointLevel::kNoSafepoint:
          UNREACHABLE();
      }

      // If the main thread asks us to join a deopt safepoint but we are
      // instructed to only really collaborate with GC safepoints we won't
      // participate in the above cases (and therefore not register our
      // check-in by increasing the checkin counts).
      //
      // After being quite sure to not have joined deopt safepoint if we only
      // support GC safepoints, we will eventually comply here to make main
      // thread continue.
      const auto now = OS::GetCurrentTimeMillis();
      if ((now - last_sync) > 1000) {
        ReloadParticipationScope allow_reload(thread_);
        if (SafepointIfRequested(thread_, data()->timeout_checkin)) {
          last_sync = now;
        }
      }
    }
  }

  bool SafepointIfRequested(Thread* thread, std::atomic<intptr_t>* checkins) {
    if (thread->IsSafepointRequested()) {
      // Collaborates by checking into the safepoint.
      thread->BlockForSafepoint();
      (*checkins)++;
      return true;
    }
    return false;
  }
};

// Test that mutators will not check-in to "deopt safepoint operations" at
// at places where the mutator cannot depot (which is indicated by the
// Thread::runtime_call_kind_ value).
#if !defined(PRODUCT)
ISOLATE_UNIT_TEST_CASE(SafepointOperation_SafepointPointTest) {
  auto isolate_group = thread->isolate_group();

  const intptr_t kTaskCount = 6;
  std::atomic<intptr_t> gc_only_checkins[kTaskCount];
  std::atomic<intptr_t> deopt_checkins[kTaskCount];
  std::atomic<intptr_t> reload_checkins[kTaskCount];
  std::atomic<intptr_t> timeout_checkins[kTaskCount];
  for (intptr_t i = 0; i < kTaskCount; ++i) {
    gc_only_checkins[i] = 0;
    deopt_checkins[i] = 0;
    reload_checkins[i] = 0;
    timeout_checkins[i] = 0;
  }

  auto task_to_level = [](intptr_t task_id) -> SafepointLevel {
    switch (task_id) {
      case 0:
      case 1:
        return SafepointLevel::kGC;
      case 2:
      case 3:
        return SafepointLevel::kGCAndDeopt;
      case 4:
      case 5:
        return SafepointLevel::kGCAndDeoptAndReload;
      default:
        UNREACHABLE();
        return SafepointLevel::kGC;
    }
  };
  auto wait_for_sync = [&](intptr_t syncs) {
    while (true) {
      bool ready = true;
      for (intptr_t i = 0; i < kTaskCount; ++i) {
        const intptr_t all = gc_only_checkins[i] + deopt_checkins[i] +
                             reload_checkins[i] + timeout_checkins[i];
        if (all != syncs) {
          ready = false;
          break;
        }
      }
      if (ready) {
        return;
      }
      OS::SleepMicros(1000);
    }
  };

  std::vector<std::shared_ptr<CheckinTask::Data>> threads;
  for (intptr_t i = 0; i < kTaskCount; ++i) {
    const auto level = task_to_level(i);
    std::unique_ptr<CheckinTask::Data> data(new CheckinTask::Data(
        isolate_group, level, &gc_only_checkins[i], &deopt_checkins[i],
        &reload_checkins[i], &timeout_checkins[i]));
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
      wait_for_sync(1);  // Wait for threads to exit safepoint
      { DeoptSafepointOperationScope safepoint_operation(thread); }
      wait_for_sync(2);  // Wait for threads to exit safepoint
      { ReloadOperationScope reload(thread); }
      wait_for_sync(3);  // Wait for threads to exit safepoint
      { GcSafepointOperationScope safepoint_operation(thread); }
      wait_for_sync(4);  // Wait for threads to exit safepoint
      { DeoptSafepointOperationScope safepoint_operation(thread); }
      wait_for_sync(5);  // Wait for threads to exit safepoint
      { ReloadOperationScope reload(thread); }
    }
    for (intptr_t i = 0; i < kTaskCount; i++) {
      threads[i]->MarkAndNotify(CheckinTask::kPleaseExit);
    }
    for (intptr_t i = 0; i < kTaskCount; i++) {
      threads[i]->WaitUntil(CheckinTask::kExited);
    }
    for (intptr_t i = 0; i < kTaskCount; ++i) {
      switch (task_to_level(i)) {
        case SafepointLevel::kGC:
          EXPECT_EQ(2, gc_only_checkins[i]);
          EXPECT_EQ(0, deopt_checkins[i]);
          EXPECT_EQ(0, reload_checkins[i]);
          EXPECT_EQ(4, timeout_checkins[i]);
          break;
        case SafepointLevel::kGCAndDeopt:
          EXPECT_EQ(0, gc_only_checkins[i]);
          EXPECT_EQ(4, deopt_checkins[i]);
          EXPECT_EQ(0, reload_checkins[i]);
          EXPECT_EQ(2, timeout_checkins[i]);
          break;
        case SafepointLevel::kGCAndDeoptAndReload:
          EXPECT_EQ(0, gc_only_checkins[i]);
          EXPECT_EQ(0, deopt_checkins[i]);
          EXPECT_EQ(6, reload_checkins[i]);
          EXPECT_EQ(0, timeout_checkins[i]);
          break;
        case SafepointLevel::kNumLevels:
        case SafepointLevel::kNoSafepoint:
          UNREACHABLE();
      }
    }
  }
}
#endif  // !defined(PRODUCT)

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
  auto safepoint_handler = thread->isolate_group()->safepoint_handler();
  {
    DeoptSafepointOperationScope safepoint_scope(thread);
    EXPECT(safepoint_handler->InnermostSafepointOperation(thread) ==
           SafepointLevel::kGCAndDeopt);
    DeoptSafepointOperationScope safepoint_scope2(thread);
    EXPECT(safepoint_handler->InnermostSafepointOperation(thread) ==
           SafepointLevel::kGCAndDeopt);
    GcSafepointOperationScope safepoint_scope3(thread);
    EXPECT(safepoint_handler->InnermostSafepointOperation(thread) ==
           SafepointLevel::kGC);
    GcSafepointOperationScope safepoint_scope4(thread);
    EXPECT(safepoint_handler->InnermostSafepointOperation(thread) ==
           SafepointLevel::kGC);
  }
  {
    DeoptSafepointOperationScope safepoint_scope(thread);
    EXPECT(safepoint_handler->InnermostSafepointOperation(thread) ==
           SafepointLevel::kGCAndDeopt);
    GcSafepointOperationScope safepoint_scope2(thread);
    EXPECT(safepoint_handler->InnermostSafepointOperation(thread) ==
           SafepointLevel::kGC);
  }
  {
    GcSafepointOperationScope safepoint_scope1(thread);
    EXPECT(safepoint_handler->InnermostSafepointOperation(thread) ==
           SafepointLevel::kGC);
    GcSafepointOperationScope safepoint_scope2(thread);
    EXPECT(safepoint_handler->InnermostSafepointOperation(thread) ==
           SafepointLevel::kGC);
  }
}

ISOLATE_UNIT_TEST_CASE_WITH_EXPECTATION(
    SafepointOperation_NonDeoptAndDeoptNesting,
    "Crash") {
  GcSafepointOperationScope safepoint_scope(thread);
  DeoptSafepointOperationScope safepoint_scope2(thread);
}

class IsolateExitScope {
 public:
  IsolateExitScope() : saved_isolate_(Dart_CurrentIsolate()) {
    Dart_ExitIsolate();
  }
  ~IsolateExitScope() { Dart_EnterIsolate(saved_isolate_); }

 private:
  Dart_Isolate saved_isolate_;
};

ISOLATE_UNIT_TEST_CASE(ReloadScopes_Test) {
  // Unscheduling an isolate will enter a safepoint that is reloadable.
  {
    TransitionVMToNative transition(thread);
    IsolateExitScope isolate_leave_scope;
    EXPECT(thread->IsAtSafepoint(SafepointLevel::kGCAndDeoptAndReload));
  }

  // Unscheduling an isolate with active [NoReloadScope] will enter a safepoint
  // that is not reloadable.
  {
    // [NoReloadScope] only works if reload is supported.
#if !defined(PRODUCT)
    NoReloadScope no_reload_scope(thread);
    TransitionVMToNative transition(thread);
    IsolateExitScope isolate_leave_scope;
    EXPECT(!thread->IsAtSafepoint(SafepointLevel::kGCAndDeoptAndReload));
    EXPECT(thread->IsAtSafepoint(SafepointLevel::kGCAndDeopt));
#endif  // !defined(PRODUCT)
  }

  // Transitioning to native doesn't mean we enter a safepoint that is
  // reloadable.
  // => We may want to allow this in the future (so e.g. isolates that perform
  // blocking FFI call can be reloaded while being blocked).
  {
    TransitionVMToNative transition(thread);
    EXPECT(!thread->IsAtSafepoint(SafepointLevel::kGCAndDeoptAndReload));
    EXPECT(thread->IsAtSafepoint(SafepointLevel::kGCAndDeopt));
  }

  // Transitioning to native with explicit [ReloadParticipationScope] will
  // enter a safepoint that is reloadable.
  {
    ReloadParticipationScope enable_reload(thread);
    TransitionVMToNative transition(thread);
    EXPECT(thread->IsAtSafepoint(SafepointLevel::kGCAndDeoptAndReload));
  }
}

#if !defined(PRODUCT)
class ReloadTask : public StateMachineTask {
 public:
  using Data = StateMachineTask::Data;

  explicit ReloadTask(std::shared_ptr<Data> data) : StateMachineTask(data) {}

 protected:
  virtual void RunInternal() {
    ReloadOperationScope reload_operation_scope(thread_);
  }
};

ISOLATE_UNIT_TEST_CASE(Reload_AtReloadSafepoint) {
  auto isolate = thread->isolate();
  auto messages = isolate->message_handler();

  ThreadPool pool;

  {
    ReloadParticipationScope allow_reload(thread);

    // We are not at a safepoint.
    ASSERT(!thread->IsAtSafepoint());

    // Enter a reload safepoint.
    thread->EnterSafepoint();
    {
      // The [ReloadTask] will trigger a reload safepoint operation, sees that
      // we are at reload safepoint & finishes without sending OOB message.
      std::shared_ptr<ReloadTask::Data> task(
          new ReloadTask::Data(isolate->group()));
      pool.Run<ReloadTask>(task);
      task->WaitUntil(ReloadTask::kEntered);
      task->MarkAndNotify(ReloadTask::kPleaseExit);
      task->WaitUntil(ReloadTask::kExited);
    }
    thread->ExitSafepoint();

    EXPECT(!messages->HasOOBMessages());
  }
}

static void EnsureValidOOBMessage(Thread* thread,
                                  Isolate* isolate,
                                  std::unique_ptr<Message> message) {
  EXPECT(message->IsOOB());
  EXPECT(message->dest_port() == isolate->main_port());

  const auto& msg = Object::Handle(ReadMessage(thread, message.get()));
  EXPECT(msg.IsArray());

  const auto& array = Array::Cast(msg);
  EXPECT(array.Length() == 3);
  EXPECT(Smi::Value(Smi::RawCast(array.At(0))) == Message::kIsolateLibOOBMsg);
  EXPECT(Smi::Value(Smi::RawCast(array.At(1))) == Isolate::kCheckForReload);
  // 3rd value is ignored.
}

ISOLATE_UNIT_TEST_CASE(Reload_NotAtSafepoint) {
  auto isolate = thread->isolate();
  auto messages = isolate->message_handler();

  ThreadPool pool;

  std::shared_ptr<ReloadTask::Data> task(
      new ReloadTask::Data(isolate->group()));

  {
    // Even if we are not running with an active isolate (e.g. due to being in
    // GC / Compiler) the reload safepoint operation should still send us an OOB
    // message (it should know this thread belongs to an isolate).
    NoActiveIsolateScope no_active_isolate(thread);

    pool.Run<ReloadTask>(task);
    task->WaitUntil(ReloadTask::kEntered);

    // We are not at a safepoint. The [ReloadTask] will trigger a reload
    // safepoint operation, sees that we are not at reload safepoint and instead
    // sends us an OOB.
    ASSERT(!thread->IsAtSafepoint());
    while (!messages->HasOOBMessages()) {
      OS::Sleep(1000);
    }
  }

  // Examine the OOB message for it's content.
  std::unique_ptr<Message> message = messages->StealOOBMessage();
  EnsureValidOOBMessage(thread, isolate, std::move(message));

  // Finally participate in the reload safepoint and finish.
  {
    ReloadParticipationScope allow_reload(thread);
    thread->BlockForSafepoint();
  }

  task->MarkAndNotify(ReloadTask::kPleaseExit);
  task->WaitUntil(ReloadTask::kExited);
}

ISOLATE_UNIT_TEST_CASE(Reload_AtNonReloadSafepoint) {
  auto isolate = thread->isolate();
  auto messages = isolate->message_handler();

  ThreadPool pool;

  // The [ReloadTask] will trigger a reload safepoint operation, sees that
  // we are at not at reload safepoint & sends us an OOB and waits for us to
  // check-in.
  std::shared_ptr<ReloadTask::Data> task(
      new ReloadTask::Data(isolate->group()));
  pool.Run<ReloadTask>(task);
  task->WaitUntil(ReloadTask::kEntered);

  {
    NoReloadScope no_reload(thread);

    // We are not at a safepoint.
    ASSERT(!thread->IsAtSafepoint());

    // Enter a non-reload safepoint.
    thread->EnterSafepoint();
    {
      // We are at a safepoint but not a reload safepoint. So we'll get an OOM.
      ASSERT(thread->IsAtSafepoint());
      while (!messages->HasOOBMessages()) {
        OS::Sleep(1000);
      }
      // Ensure we got a valid OOM
      std::unique_ptr<Message> message = messages->StealOOBMessage();
      EnsureValidOOBMessage(thread, isolate, std::move(message));
    }
    thread->ExitSafepoint();

    EXPECT(!messages->HasOOBMessages());
  }

  // We left the [NoReloadScope] which in it's destructor should detect
  // that a reload safepoint operation is requested and re-send OOM message to
  // current isolate.
  EXPECT(messages->HasOOBMessages());
  std::unique_ptr<Message> message = messages->StealOOBMessage();
  EnsureValidOOBMessage(thread, isolate, std::move(message));

  // Finally participate in the reload safepoint and finish.
  {
    ReloadParticipationScope allow_reload(thread);
    thread->BlockForSafepoint();
  }

  task->MarkAndNotify(ReloadTask::kPleaseExit);
  task->WaitUntil(ReloadTask::kExited);
}
#endif  // !defined(PRODUCT)

}  // namespace dart
