// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/thread_pool.h"
#include "vm/unit_test.h"

namespace dart {

UNIT_TEST_CASE(IsolateCurrent) {
  Dart_Isolate isolate = Dart_CreateIsolate(
      NULL, NULL, bin::isolate_snapshot_buffer, NULL, NULL, NULL);
  EXPECT_EQ(isolate, Dart_CurrentIsolate());
  Dart_ShutdownIsolate();
  EXPECT_EQ(reinterpret_cast<Dart_Isolate>(NULL), Dart_CurrentIsolate());
}


// Test to ensure that an exception is thrown if no isolate creation
// callback has been set by the embedder when an isolate is spawned.
TEST_CASE(IsolateSpawn) {
  const char* kScriptChars =
      "import 'dart:isolate';\n"
      // Ignores printed lines.
      "var _nullPrintClosure = (String line) {};\n"
      "void entry(message) {}\n"
      "int testMain() {\n"
      "  Isolate.spawn(entry, null);\n"
      // TODO(floitsch): the following code is only to bump the event loop
      // so it executes asynchronous microtasks.
      "  var rp = new RawReceivePort();\n"
      "  rp.sendPort.send(null);\n"
      "  rp.handler = (_) { rp.close(); };\n"
      "}\n";

  Dart_Handle test_lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Setup the internal library's 'internalPrint' function.
  // Necessary because asynchronous errors use "print" to print their
  // stack trace.
  Dart_Handle url = NewString("dart:_internal");
  DART_CHECK_VALID(url);
  Dart_Handle internal_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(internal_lib);
  Dart_Handle print = Dart_GetField(test_lib, NewString("_nullPrintClosure"));
  Dart_Handle result = Dart_SetField(internal_lib,
                                     NewString("_printClosure"),
                                     print);

  DART_CHECK_VALID(result);

  // Setup the 'scheduleImmediate' closure.
  url = NewString("dart:isolate");
  DART_CHECK_VALID(url);
  Dart_Handle isolate_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(isolate_lib);
  Dart_Handle schedule_immediate_closure =
      Dart_Invoke(isolate_lib, NewString("_getIsolateScheduleImmediateClosure"),
                  0, NULL);
  Dart_Handle args[1];
  args[0] = schedule_immediate_closure;
  url = NewString("dart:async");
  DART_CHECK_VALID(url);
  Dart_Handle async_lib = Dart_LookupLibrary(url);
  DART_CHECK_VALID(async_lib);
  DART_CHECK_VALID(Dart_Invoke(
      async_lib, NewString("_setScheduleImmediateClosure"), 1, args));


  result = Dart_Invoke(test_lib, NewString("testMain"), 0, NULL);
  EXPECT(!Dart_IsError(result));
  // Run until all ports to isolate are closed.
  result = Dart_RunLoop();
  EXPECT_ERROR(result, "Null callback specified for isolate creation");
  EXPECT(Dart_ErrorHasException(result));
  Dart_Handle exception_result = Dart_ErrorGetException(result);
  EXPECT_VALID(exception_result);
}


class InterruptChecker : public ThreadPool::Task {
 public:
  static const intptr_t kTaskCount;
  static const intptr_t kIterations;

  InterruptChecker(Isolate* isolate,
                   Monitor* awake_monitor,
                   bool* awake,
                   Monitor* round_monitor,
                   const intptr_t* round)
    : isolate_(isolate),
      awake_monitor_(awake_monitor),
      awake_(awake),
      round_monitor_(round_monitor),
      round_(round) {
  }

  virtual void Run() {
    Thread::EnterIsolateAsHelper(isolate_);
    // Tell main thread that we are ready.
    {
      MonitorLocker ml(awake_monitor_);
      ASSERT(!*awake_);
      *awake_ = true;
      ml.Notify();
    }
    for (intptr_t i = 0; i < kIterations; ++i) {
      // Busy wait for interrupts.
      while (!isolate_->HasInterruptsScheduled(Isolate::kVMInterrupt)) {
        // Do nothing.
      }
      // Tell main thread that we observed the interrupt.
      {
        MonitorLocker ml(awake_monitor_);
        ASSERT(!*awake_);
        *awake_ = true;
        ml.Notify();
      }
      // Wait for main thread to let us resume, i.e., until all tasks are here.
      {
        MonitorLocker ml(round_monitor_);
        EXPECT(*round_ == i || *round_ == (i + 1));
        while (*round_ == i) {
          ml.Wait();
        }
        EXPECT(*round_ == i + 1);
      }
    }
    Thread::ExitIsolateAsHelper();
    // Use awake also to signal exit.
    {
      MonitorLocker ml(awake_monitor_);
      *awake_ = true;
      ml.Notify();
    }
  }

 private:
  Isolate* isolate_;
  Monitor* awake_monitor_;
  bool* awake_;
  Monitor* round_monitor_;
  const intptr_t* round_;
};


const intptr_t InterruptChecker::kTaskCount = 5;
const intptr_t InterruptChecker::kIterations = 10;


// Waits for all tasks to set their individual flag, then clears them all.
static void WaitForAllTasks(bool* flags, Monitor* monitor) {
  MonitorLocker ml(monitor);
  while (true) {
    intptr_t count = 0;
    for (intptr_t task = 0; task < InterruptChecker::kTaskCount; ++task) {
      if (flags[task]) {
        ++count;
      }
    }
    if (count == InterruptChecker::kTaskCount) {
      memset(flags, 0, sizeof(*flags) * count);
      break;
    } else {
      ml.Wait();
    }
  }
}

// Test and document usage of Isolate::HasInterruptsScheduled.
//
// Go through a number of rounds of scheduling interrupts and waiting until all
// unsynchronized busy-waiting tasks observe it (in the current implementation,
// the exact latency depends on cache coherence). Synchronization is then used
// to ensure that the response to the interrupt, i.e., starting a new round,
// happens *after* the interrupt is observed. Without this synchronization, the
// compiler and/or CPU could reorder operations to make the tasks observe the
// round update *before* the interrupt is set.
TEST_CASE(StackLimitInterrupts) {
  Monitor awake_monitor;  // Synchronizes the 'awake' flags.
  bool awake[InterruptChecker::kTaskCount];
  memset(awake, 0, sizeof(awake));
  Monitor round_monitor;  // Synchronizes the 'round' counter.
  intptr_t round = 0;
  Isolate* isolate = Thread::Current()->isolate();
  // Start all tasks. They will busy-wait until interrupted in the first round.
  for (intptr_t task = 0; task < InterruptChecker::kTaskCount; task++) {
    Dart::thread_pool()->Run(new InterruptChecker(
        isolate, &awake_monitor, &awake[task], &round_monitor, &round));
  }
  // Wait for all tasks to get ready for the first round.
  WaitForAllTasks(awake, &awake_monitor);
  for (intptr_t i = 0; i < InterruptChecker::kIterations; ++i) {
    isolate->ScheduleInterrupts(Isolate::kVMInterrupt);
    // Wait for all tasks to observe the interrupt.
    WaitForAllTasks(awake, &awake_monitor);
    // Continue with next round.
    uword interrupts = isolate->GetAndClearInterrupts();
    EXPECT((interrupts & Isolate::kVMInterrupt) != 0);
    {
      MonitorLocker ml(&round_monitor);
      ++round;
      ml.NotifyAll();
    }
  }
  // Wait for tasks to exit cleanly.
  WaitForAllTasks(awake, &awake_monitor);
}

}  // namespace dart
