// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains test functions for the dart:ffi test cases.

#include <stddef.h>
#include <stdlib.h>
#include <sys/types.h>
#include <csignal>

#include "platform/globals.h"
#if defined(HOST_OS_WINDOWS)
#include <psapi.h>
#else
#include <unistd.h>

// Only OK to use here because this is test code.
#include <condition_variable>  // NOLINT(build/c++11)
#include <functional>          // NOLINT(build/c++11)
#include <mutex>               // NOLINT(build/c++11)
#include <thread>              // NOLINT(build/c++11)
#endif

#include <setjmp.h>
#include <signal.h>
#include <iostream>
#include <limits>

#include "include/dart_api.h"
#include "include/dart_native_api.h"

namespace dart {

#define CHECK(X)                                                               \
  if (!(X)) {                                                                  \
    fprintf(stderr, "%s\n", "Check failed: " #X);                              \
    return 1;                                                                  \
  }

#define CHECK_EQ(X, Y) CHECK((X) == (Y))

////////////////////////////////////////////////////////////////////////////////
// Functions for stress-testing.

DART_EXPORT int64_t MinInt64() {
  Dart_ExecuteInternalCommand("gc-on-nth-allocation",
                              reinterpret_cast<void*>(1));
  return 0x8000000000000000;
}

DART_EXPORT int64_t MinInt32() {
  Dart_ExecuteInternalCommand("gc-on-nth-allocation",
                              reinterpret_cast<void*>(1));
  return 0x80000000;
}

DART_EXPORT double SmallDouble() {
  Dart_ExecuteInternalCommand("gc-on-nth-allocation",
                              reinterpret_cast<void*>(1));
  return 0x80000000 * -1.0;
}

// Requires boxing on 32-bit and 64-bit systems, even if the top 32-bits are
// truncated.
DART_EXPORT void* LargePointer() {
  Dart_ExecuteInternalCommand("gc-on-nth-allocation",
                              reinterpret_cast<void*>(1));
  uint64_t origin = 0x8100000082000000;
  return reinterpret_cast<void*>(origin);
}

DART_EXPORT void TriggerGC(uint64_t count) {
  Dart_ExecuteInternalCommand("gc-now", nullptr);
}

DART_EXPORT void CollectOnNthAllocation(intptr_t num_allocations) {
  Dart_ExecuteInternalCommand("gc-on-nth-allocation",
                              reinterpret_cast<void*>(num_allocations));
}

// Triggers GC. Has 11 dummy arguments as unboxed odd integers which should be
// ignored by GC.
DART_EXPORT void Regress37069(uint64_t a,
                              uint64_t b,
                              uint64_t c,
                              uint64_t d,
                              uint64_t e,
                              uint64_t f,
                              uint64_t g,
                              uint64_t h,
                              uint64_t i,
                              uint64_t j,
                              uint64_t k) {
  Dart_ExecuteInternalCommand("gc-now", nullptr);
}

#if !defined(HOST_OS_WINDOWS)
DART_EXPORT void* UnprotectCodeOtherThread(void* isolate,
                                           std::condition_variable* var,
                                           std::mutex* mut) {
  std::function<void()> callback = [&]() {
    mut->lock();
    var->notify_all();
    mut->unlock();

    // Wait for mutator thread to continue (and block) before leaving the
    // safepoint.
    while (Dart_ExecuteInternalCommand("is-mutator-in-native", isolate) !=
           nullptr) {
      usleep(10 * 1000 /*10 ms*/);
    }
  };

  struct {
    void* isolate;
    std::function<void()>* callback;
  } args = {.isolate = isolate, .callback = &callback};

  Dart_ExecuteInternalCommand("run-in-safepoint-and-rw-code", &args);
  return nullptr;
}

struct HelperThreadState {
  std::mutex mutex;
  std::condition_variable cvar;
  std::unique_ptr<std::thread> helper;
};

DART_EXPORT void* TestUnprotectCode(void (*fn)(void*)) {
  HelperThreadState* state = new HelperThreadState;

  {
    std::unique_lock<std::mutex> lock(state->mutex);  // locks the mutex
    state->helper.reset(new std::thread(UnprotectCodeOtherThread,
                                        Dart_CurrentIsolate(), &state->cvar,
                                        &state->mutex));

    state->cvar.wait(lock);
  }

  if (fn != nullptr) {
    fn(state);
    return nullptr;
  } else {
    return state;
  }
}

DART_EXPORT void WaitForHelper(HelperThreadState* helper) {
  helper->helper->join();
  delete helper;
}
#else
// Our version of VSC++ doesn't support std::thread yet.
DART_EXPORT void WaitForHelper(void* helper) {}
DART_EXPORT void* TestUnprotectCode(void (*fn)(void)) {
  return nullptr;
}
#endif

// Defined in ffi_test_functions.S.
//
// Clobbers some registers with special meaning in Dart before re-entry, for
// stress-testing. Not used on 32-bit Windows due to complications with Windows
// "safeseh".
#if defined(TARGET_OS_WINDOWS) && defined(HOST_ARCH_IA32)
void ClobberAndCall(void (*fn)()) {
  fn();
}
#else
extern "C" void ClobberAndCall(void (*fn)());
#endif

DART_EXPORT intptr_t TestGC(void (*do_gc)()) {
  ClobberAndCall(do_gc);
  return 0;
}

struct CallbackTestData {
  intptr_t success;
  void (*callback)();
};

#if defined(TARGET_OS_LINUX)

thread_local sigjmp_buf buf;
void CallbackTestSignalHandler(int) {
  siglongjmp(buf, 1);
}

intptr_t ExpectAbort(void (*fn)()) {
  fprintf(stderr, "**** EXPECT STACKTRACE TO FOLLOW. THIS IS OK. ****\n");

  struct sigaction old_action = {};
  intptr_t result = __sigsetjmp(buf, /*savesigs=*/1);
  if (result == 0) {
    // Install signal handler.
    struct sigaction handler = {};
    handler.sa_handler = CallbackTestSignalHandler;
    sigemptyset(&handler.sa_mask);
    handler.sa_flags = 0;

    sigaction(SIGABRT, &handler, &old_action);

    fn();
  } else {
    // Caught the setjmp.
    sigaction(SIGABRT, &old_action, NULL);
    exit(0);
  }
  fprintf(stderr, "Expected abort!!!\n");
  exit(1);
}

void* TestCallbackOnThreadOutsideIsolate(void* parameter) {
  CallbackTestData* data = reinterpret_cast<CallbackTestData*>(parameter);
  data->success = ExpectAbort(data->callback);
  return NULL;
}

intptr_t TestCallbackOtherThreadHelper(void* (*tester)(void*), void (*fn)()) {
  CallbackTestData data = {1, fn};
  pthread_attr_t attr;
  intptr_t result = pthread_attr_init(&attr);
  CHECK_EQ(result, 0);

  pthread_t tid;
  result = pthread_create(&tid, &attr, tester, &data);
  CHECK_EQ(result, 0);

  result = pthread_attr_destroy(&attr);
  CHECK_EQ(result, 0);

  void* retval;
  result = pthread_join(tid, &retval);

  // Doesn't actually return because the other thread will exit when the test is
  // finished.
  return 1;
}

// Run a callback on another thread and verify that it triggers SIGABRT.
DART_EXPORT intptr_t TestCallbackWrongThread(void (*fn)()) {
  return TestCallbackOtherThreadHelper(&TestCallbackOnThreadOutsideIsolate, fn);
}

// Verify that we get SIGABRT when invoking a native callback outside an
// isolate.
DART_EXPORT intptr_t TestCallbackOutsideIsolate(void (*fn)()) {
  Dart_Isolate current = Dart_CurrentIsolate();

  Dart_ExitIsolate();
  CallbackTestData data = {1, fn};
  TestCallbackOnThreadOutsideIsolate(&data);
  Dart_EnterIsolate(current);

  return data.success;
}

DART_EXPORT intptr_t TestCallbackWrongIsolate(void (*fn)()) {
  return ExpectAbort(fn);
}

#endif  // defined(TARGET_OS_LINUX)

}  // namespace dart
