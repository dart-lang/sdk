// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate.h"
#include "include/dart_api.h"
#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/lockers.h"
#include "vm/thread_barrier.h"
#include "vm/thread_pool.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(IsolateCurrent) {
  Dart_Isolate isolate = TestCase::CreateTestIsolate();
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
      "void testMain() {\n"
      "  Isolate.spawn(entry, null);\n"
      // TODO(floitsch): the following code is only to bump the event loop
      // so it executes asynchronous microtasks.
      "  var rp = RawReceivePort();\n"
      "  rp.sendPort.send(null);\n"
      "  rp.handler = (_) { rp.close(); };\n"
      "}\n";

  Dart_Handle test_lib = TestCase::LoadTestScript(kScriptChars, NULL);

  // Setup the internal library's 'internalPrint' function.
  // Necessary because asynchronous errors use "print" to print their
  // stack trace.
  Dart_Handle url = NewString("dart:_internal");
  EXPECT_VALID(url);
  Dart_Handle internal_lib = Dart_LookupLibrary(url);
  EXPECT_VALID(internal_lib);
  Dart_Handle print = Dart_GetField(test_lib, NewString("_nullPrintClosure"));
  Dart_Handle result =
      Dart_SetField(internal_lib, NewString("_printClosure"), print);

  EXPECT_VALID(result);

  // Setup the 'scheduleImmediate' closure.
  url = NewString("dart:isolate");
  EXPECT_VALID(url);
  Dart_Handle isolate_lib = Dart_LookupLibrary(url);
  EXPECT_VALID(isolate_lib);
  Dart_Handle schedule_immediate_closure = Dart_Invoke(
      isolate_lib, NewString("_getIsolateScheduleImmediateClosure"), 0, NULL);
  Dart_Handle args[1];
  args[0] = schedule_immediate_closure;
  url = NewString("dart:async");
  EXPECT_VALID(url);
  Dart_Handle async_lib = Dart_LookupLibrary(url);
  EXPECT_VALID(async_lib);
  EXPECT_VALID(Dart_Invoke(async_lib, NewString("_setScheduleImmediateClosure"),
                           1, args));

  result = Dart_Invoke(test_lib, NewString("testMain"), 0, NULL);
  EXPECT_VALID(result);
  // Run until all ports to isolate are closed.
  result = Dart_RunLoop();
  EXPECT_ERROR(result, "Unsupported operation: Isolate.spawn");
  EXPECT(Dart_ErrorHasException(result));
  Dart_Handle exception_result = Dart_ErrorGetException(result);
  EXPECT_VALID(exception_result);
}

class InterruptChecker : public ThreadPool::Task {
 public:
  static const intptr_t kTaskCount;
  static const intptr_t kIterations;

  InterruptChecker(Thread* thread, ThreadBarrier* barrier)
      : thread_(thread), barrier_(barrier) {}

  virtual void Run() {
    Thread::EnterIsolateAsHelper(thread_->isolate(), Thread::kUnknownTask);
    // Tell main thread that we are ready.
    barrier_->Sync();
    for (intptr_t i = 0; i < kIterations; ++i) {
      // Busy wait for interrupts.
      uword limit = 0;
      do {
        limit = reinterpret_cast<RelaxedAtomic<uword>*>(
                    thread_->stack_limit_address())
                    ->load();
      } while (
          (limit == thread_->saved_stack_limit_) ||
          (((limit & Thread::kInterruptsMask) & Thread::kVMInterrupt) == 0));
      // Tell main thread that we observed the interrupt.
      barrier_->Sync();
    }
    Thread::ExitIsolateAsHelper();
    barrier_->Sync();
    barrier_->Release();
  }

 private:
  Thread* thread_;
  ThreadBarrier* barrier_;
};

const intptr_t InterruptChecker::kTaskCount = 5;
const intptr_t InterruptChecker::kIterations = 10;

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
  ThreadBarrier* barrier = new ThreadBarrier(InterruptChecker::kTaskCount + 1,
                                             InterruptChecker::kTaskCount + 1);
  // Start all tasks. They will busy-wait until interrupted in the first round.
  for (intptr_t task = 0; task < InterruptChecker::kTaskCount; task++) {
    Dart::thread_pool()->Run<InterruptChecker>(thread, barrier);
  }
  // Wait for all tasks to get ready for the first round.
  barrier->Sync();
  for (intptr_t i = 0; i < InterruptChecker::kIterations; ++i) {
    thread->ScheduleInterrupts(Thread::kVMInterrupt);
    // Wait for all tasks to observe the interrupt.
    barrier->Sync();
    // Continue with next round.
    uword interrupts = thread->GetAndClearInterrupts();
    EXPECT((interrupts & Thread::kVMInterrupt) != 0);
  }
  barrier->Sync();
  barrier->Release();
}

}  // namespace dart
