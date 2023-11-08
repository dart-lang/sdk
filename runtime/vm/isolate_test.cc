// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"

#include "platform/assert.h"

#include "vm/globals.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/port.h"
#include "vm/thread_barrier.h"
#include "vm/thread_pool.h"
#include "vm/unit_test.h"

namespace dart {

VM_UNIT_TEST_CASE(IsolateCurrent) {
  Dart_Isolate isolate = TestCase::CreateTestIsolate();
  EXPECT_EQ(isolate, Dart_CurrentIsolate());
  Dart_ShutdownIsolate();
  EXPECT_EQ(static_cast<Dart_Isolate>(nullptr), Dart_CurrentIsolate());
}

// Test to ensure that an exception is thrown if no isolate creation
// callback has been set by the embedder when an isolate is spawned.
void IsolateSpawn(const char* platform_script_value) {
  char* scriptChars = OS::SCreate(
      nullptr,
      "import 'dart:isolate';\n"
      // Ignores printed lines.
      "var _nullPrintClosure = (String line) {};\n"
      "var _platformScript = () => Uri.parse(\"%s\");\n"
      "void entry(message) {}\n"
      "void testMain() {\n"
      "  Isolate.spawn(entry, null);\n"
      // TODO(floitsch): the following code is only to bump the event loop
      // so it executes asynchronous microtasks.
      "  var rp = RawReceivePort();\n"
      "  rp.sendPort.send(null);\n"
      "  rp.handler = (_) { rp.close(); };\n"
      "}\n",
      platform_script_value);

  Dart_Handle test_lib = TestCase::LoadTestScript(scriptChars, nullptr);

  free(scriptChars);

  // Setup the internal library's 'internalPrint' function.
  // Necessary because asynchronous errors use "print" to print their
  // stack trace.
  Dart_Handle url = NewString("dart:_internal");
  EXPECT_VALID(url);
  Dart_Handle internal_lib = Dart_LookupLibrary(url);
  EXPECT_VALID(internal_lib);
  Dart_Handle print = Dart_GetField(test_lib, NewString("_nullPrintClosure"));
  EXPECT_VALID(print);
  Dart_Handle result =
      Dart_SetField(internal_lib, NewString("_printClosure"), print);
  EXPECT_VALID(result);

  Dart_Handle platform_script =
      Dart_GetField(test_lib, NewString("_platformScript"));
  EXPECT_VALID(platform_script);
  Dart_Handle vmlibraryhooks_class =
      Dart_GetClass(internal_lib, NewString("VMLibraryHooks"));
  EXPECT_VALID(vmlibraryhooks_class);
  result = Dart_SetField(vmlibraryhooks_class, NewString("platformScript"),
                         platform_script);
  EXPECT_VALID(result);

  // Setup the 'scheduleImmediate' closure.
  url = NewString("dart:isolate");
  EXPECT_VALID(url);
  Dart_Handle isolate_lib = Dart_LookupLibrary(url);
  EXPECT_VALID(isolate_lib);
  Dart_Handle schedule_immediate_closure =
      Dart_Invoke(isolate_lib, NewString("_getIsolateScheduleImmediateClosure"),
                  0, nullptr);
  Dart_Handle args[1];
  args[0] = schedule_immediate_closure;
  url = NewString("dart:async");
  EXPECT_VALID(url);
  Dart_Handle async_lib = Dart_LookupLibrary(url);
  EXPECT_VALID(async_lib);
  EXPECT_VALID(Dart_Invoke(async_lib, NewString("_setScheduleImmediateClosure"),
                           1, args));

  result = Dart_Invoke(test_lib, NewString("testMain"), 0, nullptr);
  EXPECT_VALID(result);
  // Run until all ports to isolate are closed.
  result = Dart_RunLoop();
  EXPECT_ERROR(
      result,
      "Lightweight isolate spawn is not supported by this Dart embedder");
  EXPECT(Dart_ErrorHasException(result));
  Dart_Handle exception_result = Dart_ErrorGetException(result);
  EXPECT_VALID(exception_result);
}

TEST_CASE(IsolateSpawn_FileUri) {
  IsolateSpawn("file:/a.dart");
}

TEST_CASE(IsolateSpawn_PackageUri) {
  IsolateSpawn("package:/a.dart");
}

class InterruptChecker : public ThreadPool::Task {
 public:
  static constexpr intptr_t kTaskCount = 5;
  static constexpr intptr_t kIterations = 10;

  InterruptChecker(Thread* thread, ThreadBarrier* barrier)
      : thread_(thread), barrier_(barrier) {}

  virtual void Run() {
    const bool kBypassSafepoint = false;
    Thread::EnterIsolateGroupAsHelper(thread_->isolate_group(),
                                      Thread::kUnknownTask, kBypassSafepoint);
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
    Thread::ExitIsolateGroupAsHelper(kBypassSafepoint);
    barrier_->Sync();
    barrier_->Release();
  }

 private:
  Thread* thread_;
  ThreadBarrier* barrier_;
};

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

ISOLATE_UNIT_TEST_CASE(Isolate_Ports) {
  auto isolate = thread->isolate();
  auto& port = ReceivePort::Handle();

  EXPECT(!isolate->HasLivePorts());

  {
    // Make port.
    port = isolate->CreateReceivePort(String::null_string());
    EXPECT(port.is_open());
    EXPECT(port.keep_isolate_alive());
    EXPECT(port.Id() != ILLEGAL_PORT);
    EXPECT(PortMap::PortExists(port.Id()));
    EXPECT(isolate->HasLivePorts());

    // Make port not keep isolate alive.
    isolate->SetReceivePortKeepAliveState(port, false);
    EXPECT(port.is_open());
    EXPECT(!port.keep_isolate_alive());
    EXPECT(!isolate->HasLivePorts());

    // Mark it alive again.
    isolate->SetReceivePortKeepAliveState(port, true);
    EXPECT(port.is_open());
    EXPECT(port.keep_isolate_alive());
    EXPECT(isolate->HasLivePorts());

    // Close the port.
    isolate->CloseReceivePort(port);
    EXPECT(!port.is_open());
    EXPECT(!port.keep_isolate_alive());
    EXPECT(!isolate->HasLivePorts());

    // Closing again should be a NOP.
    isolate->CloseReceivePort(port);
    EXPECT(!port.is_open());
    EXPECT(!port.keep_isolate_alive());
    EXPECT(!isolate->HasLivePorts());
  }

  {
    // Make port.
    port = isolate->CreateReceivePort(String::null_string());
    EXPECT_NE(0, port.Id());
    EXPECT(PortMap::PortExists(port.Id()));
    EXPECT(isolate->HasLivePorts());

    // Make port not keep isolate alive.
    isolate->SetReceivePortKeepAliveState(port, false);
    EXPECT(port.is_open());
    EXPECT(!port.keep_isolate_alive());
    EXPECT(!isolate->HasLivePorts());

    // Close the port while it's not keep alive port.
    isolate->CloseReceivePort(port);
    EXPECT(!port.is_open());
    EXPECT(!port.keep_isolate_alive());
    EXPECT(!isolate->HasLivePorts());
  }

  EXPECT(!isolate->HasLivePorts());
}

}  // namespace dart
