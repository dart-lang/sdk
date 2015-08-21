// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/unit_test.h"
#include "vm/profiler.h"
#include "vm/thread_pool.h"
#include "vm/thread_registry.h"

namespace dart {

UNIT_TEST_CASE(Mutex) {
  // This unit test case needs a running isolate.
  Dart_CreateIsolate(
      NULL, NULL, bin::isolate_snapshot_buffer, NULL, NULL, NULL);

  Mutex* mutex = new Mutex();
  mutex->Lock();
  EXPECT_EQ(false, mutex->TryLock());
  mutex->Unlock();
  EXPECT_EQ(true, mutex->TryLock());
  mutex->Unlock();
  {
    MutexLocker ml(mutex);
    EXPECT_EQ(false, mutex->TryLock());
  }
  // The isolate shutdown and the destruction of the mutex are out-of-order on
  // purpose.
  Dart_ShutdownIsolate();
  delete mutex;
}


UNIT_TEST_CASE(Monitor) {
  // This unit test case needs a running isolate.
  Dart_CreateIsolate(
      NULL, NULL, bin::isolate_snapshot_buffer, NULL, NULL, NULL);
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  // Thread interrupter interferes with this test, disable interrupts.
  thread->SetThreadInterrupter(NULL, NULL);
  Profiler::EndExecution(isolate);
  Monitor* monitor = new Monitor();
  monitor->Enter();
  monitor->Exit();

  const int kNumAttempts = 5;
  int attempts = 0;
  while (attempts < kNumAttempts) {
    MonitorLocker ml(monitor);
    int64_t start = OS::GetCurrentTimeMillis();
    int64_t wait_time = 2017;
    Monitor::WaitResult wait_result = ml.Wait(wait_time);
    int64_t stop = OS::GetCurrentTimeMillis();

    // We expect to be timing out here.
    EXPECT_EQ(Monitor::kTimedOut, wait_result);

    // Check whether this attempt falls within the exptected time limits.
    int64_t wakeup_time = stop - start;
    OS::Print("wakeup_time: %" Pd64 "\n", wakeup_time);
    const int kAcceptableTimeJitter = 20;  // Measured in milliseconds.
    const int kAcceptableWakeupDelay = 150;  // Measured in milliseconds.
    if (((wait_time - kAcceptableTimeJitter) <= wakeup_time) &&
        (wakeup_time <= (wait_time + kAcceptableWakeupDelay))) {
      break;
    }

    // Record the attempt.
    attempts++;
  }
  EXPECT_LT(attempts, kNumAttempts);

  // The isolate shutdown and the destruction of the mutex are out-of-order on
  // purpose.
  Dart_ShutdownIsolate();
  delete monitor;
}


class ObjectCounter : public ObjectPointerVisitor {
 public:
  explicit ObjectCounter(Isolate* isolate, const Object* obj)
      : ObjectPointerVisitor(isolate), obj_(obj), count_(0) { }

  virtual void VisitPointers(RawObject** first, RawObject** last) {
    for (RawObject** current = first; current <= last; ++current) {
      if (*current == obj_->raw()) {
        ++count_;
      }
    }
  }

  intptr_t count() const { return count_; }

 private:
  const Object* obj_;
  intptr_t count_;
};


class TaskWithZoneAllocation : public ThreadPool::Task {
 public:
  TaskWithZoneAllocation(Isolate* isolate,
                         Monitor* monitor,
                         bool* done,
                         intptr_t id)
      : isolate_(isolate), monitor_(monitor), done_(done), id_(id) {}
  virtual void Run() {
    Thread::EnterIsolateAsHelper(isolate_);
    {
      Thread* thread = Thread::Current();
      // Create a zone (which is also a stack resource) and exercise it a bit.
      StackZone stack_zone(thread);
      HANDLESCOPE(thread);
      Zone* zone = thread->zone();
      EXPECT_EQ(zone, stack_zone.GetZone());
      ZoneGrowableArray<bool>* a0 = new(zone) ZoneGrowableArray<bool>(zone, 1);
      GrowableArray<bool> a1(zone, 1);
      for (intptr_t i = 0; i < 100000; ++i) {
        a0->Add(true);
        a1.Add(true);
      }
      // Check that we can create handles and allocate in old space.
      String& str = String::Handle(zone, String::New("old", Heap::kOld));
      EXPECT(str.Equals("old"));

      const intptr_t unique_smi = id_ + 928327281;
      Smi& smi = Smi::Handle(zone, Smi::New(unique_smi));
      EXPECT(smi.Value() == unique_smi);
      {
        ObjectCounter counter(isolate_, &smi);
        // Ensure that our particular zone is visited.
        isolate_->IterateObjectPointers(
            &counter,
            /* visit_prologue_weak_handles = */ true,
            StackFrameIterator::kValidateFrames);
        EXPECT_EQ(1, counter.count());
      }
      char* unique_chars = zone->PrintToString("unique_str_%" Pd, id_);
      String& unique_str = String::Handle(zone);
      {
        // String::New may create additional handles in the topmost scope that
        // we don't want to count, so wrap this in its own scope.
        HANDLESCOPE(thread);
        unique_str = String::New(unique_chars, Heap::kOld);
      }
      EXPECT(unique_str.Equals(unique_chars));
      {
        ObjectCounter str_counter(isolate_, &unique_str);
        // Ensure that our particular zone is visited.
        isolate_->IterateObjectPointers(
            &str_counter,
            /* visit_prologue_weak_handles = */ true,
            StackFrameIterator::kValidateFrames);
        // We should visit the string object exactly once.
        EXPECT_EQ(1, str_counter.count());
      }
    }
    Thread::ExitIsolateAsHelper();
    {
      MonitorLocker ml(monitor_);
      *done_ = true;
      ml.Notify();
    }
  }

 private:
  Isolate* isolate_;
  Monitor* monitor_;
  bool* done_;
  intptr_t id_;
};


TEST_CASE(ManyTasksWithZones) {
  const int kTaskCount = 100;
  Monitor sync[kTaskCount];
  bool done[kTaskCount];
  Isolate* isolate = Thread::Current()->isolate();
  EXPECT(isolate->heap()->GrowthControlState());
  isolate->heap()->DisableGrowthControl();
  for (int i = 0; i < kTaskCount; i++) {
    done[i] = false;
    Dart::thread_pool()->Run(
        new TaskWithZoneAllocation(isolate, &sync[i], &done[i], i));
  }
  for (int i = 0; i < kTaskCount; i++) {
    // Check that main mutator thread can still freely use its own zone.
    String& bar = String::Handle(String::New("bar"));
    if (i % 10 == 0) {
      // Mutator thread is free to independently move in/out/between isolates.
      Thread::ExitIsolate();
    }
    MonitorLocker ml(&sync[i]);
    while (!done[i]) {
      ml.Wait();
    }
    EXPECT(done[i]);
    if (i % 10 == 0) {
      Thread::EnterIsolate(isolate);
    }
    EXPECT(bar.Equals("bar"));
  }
}


TEST_CASE(ThreadRegistry) {
  Isolate* orig = Thread::Current()->isolate();
  Zone* orig_zone = Thread::Current()->zone();
  char* orig_str = orig_zone->PrintToString("foo");
  Thread::ExitIsolate();
  // Create and enter a new isolate.
  Dart_CreateIsolate(
      NULL, NULL, bin::isolate_snapshot_buffer, NULL, NULL, NULL);
  Zone* zone0 = Thread::Current()->zone();
  EXPECT(zone0 != orig_zone);
  Dart_ShutdownIsolate();
  // Create and enter yet another isolate.
  Dart_CreateIsolate(
      NULL, NULL, bin::isolate_snapshot_buffer, NULL, NULL, NULL);
  {
    // Create a stack resource this time, and exercise it.
    StackZone stack_zone(Thread::Current());
    Zone* zone1 = Thread::Current()->zone();
    EXPECT(zone1 != zone0);
    EXPECT(zone1 != orig_zone);
  }
  Dart_ShutdownIsolate();
  Thread::EnterIsolate(orig);
  // Original zone should be preserved.
  EXPECT_EQ(orig_zone, Thread::Current()->zone());
  EXPECT_STREQ("foo", orig_str);
}


// A helper thread that alternatingly cooperates and organizes
// safepoint rendezvous. At rendezvous, it explicitly visits the
// stacks looking for a specific marker (Smi) to verify that the expected
// number threads are actually visited. The task is "done" when it has
// successfully made all other tasks and the main thread rendezvous (may
// not happen in the first rendezvous, since tasks are still starting up).
class SafepointTestTask : public ThreadPool::Task {
 public:
  static const intptr_t kTaskCount;

  SafepointTestTask(Isolate* isolate,
                    Mutex* mutex,
                    intptr_t* expected_count,
                    intptr_t* total_done,
                    intptr_t* exited)
    : isolate_(isolate),
      mutex_(mutex),
      expected_count_(expected_count),
      total_done_(total_done),
      exited_(exited),
      local_done_(false) {}

  virtual void Run() {
    Thread::EnterIsolateAsHelper(isolate_);
    {
      MutexLocker ml(mutex_);
      ++*expected_count_;
    }
    for (int i = 0; ; ++i) {
      Thread* thread = Thread::Current();
      StackZone stack_zone(thread);
      Zone* zone = thread->zone();
      HANDLESCOPE(thread);
      const intptr_t kUniqueSmi = 928327281;
      Smi& smi = Smi::Handle(zone, Smi::New(kUniqueSmi));
      if ((i % 100) != 0) {
        // Usually, we just cooperate.
        isolate_->thread_registry()->CheckSafepoint();
      } else {
        // But occasionally, organize a rendezvous.
        isolate_->thread_registry()->SafepointThreads();
        ObjectCounter counter(isolate_, &smi);
        isolate_->IterateObjectPointers(
            &counter,
            /* visit_prologue_weak_handles = */ true,
            StackFrameIterator::kValidateFrames);
        {
          MutexLocker ml(mutex_);
          EXPECT_EQ(*expected_count_, counter.count());
        }
        UserTag& tag = UserTag::Handle(zone, isolate_->current_tag());
        if (tag.raw() != isolate_->default_tag()) {
          String& label = String::Handle(zone, tag.label());
          EXPECT(label.Equals("foo"));
          MutexLocker ml(mutex_);
          if (*expected_count_ == kTaskCount && !local_done_) {
            // Success for the first time! Remember that we are done, and
            // update the total count.
            local_done_ = true;
            ++*total_done_;
          }
        }
        isolate_->thread_registry()->ResumeAllThreads();
      }
      // Check whether everyone is done.
      {
        MutexLocker ml(mutex_);
        if (*total_done_ == kTaskCount) {
          // Another task might be at SafepointThreads when resuming. Ensure its
          // expectation reflects reality, since we pop our handles here.
          --*expected_count_;
          break;
        }
      }
    }
    Thread::ExitIsolateAsHelper();
    {
      MutexLocker ml(mutex_);
      ++*exited_;
    }
  }

 private:
  Isolate* isolate_;
  Mutex* mutex_;
  intptr_t* expected_count_;  // # copies of kUniqueSmi we expect to visit.
  intptr_t* total_done_;      // # tasks that successfully safepointed once.
  intptr_t* exited_;          // # tasks that are no longer running.
  bool local_done_;           // this task has successfully safepointed >= once.
};


const intptr_t SafepointTestTask::kTaskCount = 5;


// Test rendezvous of:
// - helpers in VM code,
// - main thread in pure Dart,
// organized by
// - helpers.
TEST_CASE(SafepointTestDart) {
  Isolate* isolate = Thread::Current()->isolate();
  Mutex mutex;
  intptr_t expected_count = 0;
  intptr_t total_done = 0;
  intptr_t exited = 0;
  for (int i = 0; i < SafepointTestTask::kTaskCount; i++) {
    Dart::thread_pool()->Run(new SafepointTestTask(
        isolate, &mutex, &expected_count, &total_done, &exited));
  }
  // Run Dart code on the main thread long enough to allow all helpers
  // to get their verification done and exit. Use a specific UserTag
  // to enable the helpers to verify that the main thread is
  // successfully interrupted in the pure Dart loop.
#if defined(USING_SIMULATOR)
  const intptr_t kLoopCount = 12345678;
#else
  const intptr_t kLoopCount = 1234567890;
#endif  // USING_SIMULATOR
  char buffer[1024];
  OS::SNPrint(buffer, sizeof(buffer),
      "import 'dart:profiler';\n"
      "int dummy = 0;\n"
      "main() {\n"
      "  new UserTag('foo').makeCurrent();\n"
      "  for (dummy = 0; dummy < %" Pd "; ++dummy) {\n"
      "    dummy += (dummy & 1);\n"
      "  }\n"
      "}\n", kLoopCount);
  Dart_Handle lib = TestCase::LoadTestScript(buffer, NULL);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  // Ensure we looped long enough to allow all helpers to succeed and exit.
  {
    MutexLocker ml(&mutex);
    EXPECT_EQ(SafepointTestTask::kTaskCount, total_done);
    EXPECT_EQ(SafepointTestTask::kTaskCount, exited);
  }
}


// Test rendezvous of:
// - helpers in VM code, and
// - main thread in VM code,
// organized by
// - helpers.
TEST_CASE(SafepointTestVM) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Mutex mutex;
  intptr_t expected_count = 0;
  intptr_t total_done = 0;
  intptr_t exited = 0;
  for (int i = 0; i < SafepointTestTask::kTaskCount; i++) {
    Dart::thread_pool()->Run(new SafepointTestTask(
        isolate, &mutex, &expected_count, &total_done, &exited));
  }
  String& label = String::Handle(String::New("foo"));
  UserTag& tag = UserTag::Handle(UserTag::New(label));
  isolate->set_current_tag(tag);
  while (true) {
    isolate->thread_registry()->CheckSafepoint();
    MutexLocker ml(&mutex);
    if (exited == SafepointTestTask::kTaskCount) {
      break;
    }
  }
}


// Test rendezvous of:
// - helpers in VM code, and
// - main thread in VM code,
// organized by
// - main thread, and
// - helpers.
TEST_CASE(SafepointTestVM2) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  Mutex mutex;
  intptr_t expected_count = 0;
  intptr_t total_done = 0;
  intptr_t exited = 0;
  for (int i = 0; i < SafepointTestTask::kTaskCount; i++) {
    Dart::thread_pool()->Run(new SafepointTestTask(
        isolate, &mutex, &expected_count, &total_done, &exited));
  }
  bool all_helpers = false;
  do {
    isolate->thread_registry()->SafepointThreads();
    {
      MutexLocker ml(&mutex);
      if (expected_count == SafepointTestTask::kTaskCount) {
        all_helpers = true;
      }
    }
    isolate->thread_registry()->ResumeAllThreads();
  } while (!all_helpers);
  String& label = String::Handle(String::New("foo"));
  UserTag& tag = UserTag::Handle(UserTag::New(label));
  isolate->set_current_tag(tag);
  while (true) {
    isolate->thread_registry()->CheckSafepoint();
    MutexLocker ml(&mutex);
    if (exited == SafepointTestTask::kTaskCount) {
      break;
    }
  }
}


class AllocAndGCTask : public ThreadPool::Task {
 public:
  AllocAndGCTask(Isolate* isolate,
                 Monitor* done_monitor,
                 bool* done)
    : isolate_(isolate),
      done_monitor_(done_monitor),
      done_(done) {
  }

  virtual void Run() {
    Thread::EnterIsolateAsHelper(isolate_);
    {
      Thread* thread = Thread::Current();
      StackZone stack_zone(thread);
      Zone* zone = stack_zone.GetZone();
      HANDLESCOPE(thread);
      String& old_str = String::Handle(zone, String::New("old", Heap::kOld));
      isolate_->heap()->CollectAllGarbage();
      EXPECT(old_str.Equals("old"));
    }
    Thread::ExitIsolateAsHelper();
    // Tell main thread that we are ready.
    {
      MonitorLocker ml(done_monitor_);
      ASSERT(!*done_);
      *done_ = true;
      ml.Notify();
    }
  }

 private:
  Isolate* isolate_;
  Monitor* done_monitor_;
  bool* done_;
};


TEST_CASE(HelperAllocAndGC) {
  Monitor done_monitor;
  bool done = false;
  Isolate* isolate = Thread::Current()->isolate();
  // Flush store buffers, etc.
  // TODO(koda): Currently, the GC only does this for the current thread, (i.e,
  // the helper, in this test), but it should be done for all *threads*
  // while reaching a safepoint.
  Thread::PrepareForGC();
  Dart::thread_pool()->Run(new AllocAndGCTask(isolate, &done_monitor, &done));
  {
    // Manually wait.
    // TODO(koda): Replace with execution of Dart and/or VM code when GC
    // actually safepoints everything.
    MonitorLocker ml(&done_monitor);
    while (!done) {
      ml.Wait();
    }
  }
}

}  // namespace dart
