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
  Isolate::Flags vm_flags;
  Dart_IsolateFlags api_flags;
  vm_flags.CopyTo(&api_flags);
  Isolate* isolate = Isolate::Init(NULL, api_flags);

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
  isolate->Shutdown();
  delete isolate;
  delete mutex;
}


UNIT_TEST_CASE(Monitor) {
  // This unit test case needs a running isolate.
  Isolate::Flags vm_flags;
  Dart_IsolateFlags api_flags;
  vm_flags.CopyTo(&api_flags);
  Isolate* isolate = Isolate::Init(NULL, api_flags);
  // Thread interrupter interferes with this test, disable interrupts.
  isolate->set_thread_state(NULL);
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
  isolate->Shutdown();
  delete isolate;
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
                         const String& foo,
                         Monitor* monitor,
                         bool* done,
                         intptr_t id)
      : isolate_(isolate), foo_(foo), monitor_(monitor), done_(done), id_(id) {}
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
      // Check that we can create handles (but not yet allocate heap objects).
      String& str = String::Handle(zone, foo_.raw());
      EXPECT(str.Equals("foo"));
      const intptr_t unique_smi = id_ + 928327281;
      Smi& smi = Smi::Handle(zone, Smi::New(unique_smi));
      EXPECT(smi.Value() == unique_smi);
      ObjectCounter counter(isolate_, &smi);
      // Ensure that our particular zone is visited.
      // TODO(koda): Remove "->thread_registry()" after updating stack walker.
      isolate_->thread_registry()->VisitObjectPointers(&counter);
      EXPECT_EQ(1, counter.count());
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
  const String& foo_;
  Monitor* monitor_;
  bool* done_;
  intptr_t id_;
};


TEST_CASE(ManyTasksWithZones) {
  const int kTaskCount = 100;
  Monitor sync[kTaskCount];
  bool done[kTaskCount];
  Isolate* isolate = Thread::Current()->isolate();
  String& foo = String::Handle(String::New("foo"));

  for (int i = 0; i < kTaskCount; i++) {
    done[i] = false;
    Dart::thread_pool()->Run(
        new TaskWithZoneAllocation(isolate, foo, &sync[i], &done[i], i));
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
  Isolate::Flags vm_flags;
  Dart_IsolateFlags api_flags;
  vm_flags.CopyTo(&api_flags);
  Isolate* isos[2];
  // Create and enter a new isolate.
  isos[0] = Isolate::Init(NULL, api_flags);
  Zone* zone0 = Thread::Current()->zone();
  EXPECT(zone0 != orig_zone);
  isos[0]->Shutdown();
  Thread::ExitIsolate();
  // Create and enter yet another isolate.
  isos[1] = Isolate::Init(NULL, api_flags);
  {
    // Create a stack resource this time, and exercise it.
    StackZone stack_zone(Thread::Current());
    Zone* zone1 = Thread::Current()->zone();
    EXPECT(zone1 != zone0);
    EXPECT(zone1 != orig_zone);
  }
  isos[1]->Shutdown();
  Thread::ExitIsolate();
  Thread::EnterIsolate(orig);
  // Original zone should be preserved.
  EXPECT_EQ(orig_zone, Thread::Current()->zone());
  EXPECT_STREQ("foo", orig_str);
  delete isos[0];
  delete isos[1];
}

}  // namespace dart
