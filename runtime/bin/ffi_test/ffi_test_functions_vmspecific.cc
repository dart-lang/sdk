// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains test functions for the dart:ffi test cases.

#include <stddef.h>
#include <stdlib.h>
#include <sys/types.h>
#include <csignal>

#include "platform/globals.h"
#include "platform/memory_sanitizer.h"
#if defined(HOST_OS_WINDOWS)
#include <psapi.h>
#include <windows.h>
#else
#include <unistd.h>
#endif

// Only OK to use here because this is test code.
#include <condition_variable>  // NOLINT(build/c++11)
#include <functional>          // NOLINT(build/c++11)
#include <mutex>               // NOLINT(build/c++11)
#include <queue>               // NOLINT(build/c++11)
#include <thread>              // NOLINT(build/c++11)

#include <setjmp.h>  // NOLINT
#include <signal.h>  // NOLINT
#include <iostream>
#include <limits>

// TODO(dartbug.com/40579): This requires static linking to either link
// dart.exe or dart_precompiled_runtime.exe on Windows.
// The sample currently fails on Windows in AOT mode.
#include "include/dart_api.h"
#include "include/dart_native_api.h"

#include "include/dart_api_dl.h"

namespace dart {

#define CHECK(X)                                                               \
  if (!(X)) {                                                                  \
    fprintf(stderr, "%s\n", "Check failed: " #X);                              \
    return 1;                                                                  \
  }

#define CHECK_EQ(X, Y) CHECK((X) == (Y))

#define ENSURE(X)                                                              \
  if (!(X)) {                                                                  \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, "Check failed: " #X);   \
    exit(1);                                                                   \
  }

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

DART_EXPORT void IGH_MsanUnpoison(void* start, intptr_t length) {
  MSAN_UNPOISON(start, length);
}

DART_EXPORT Dart_Isolate IGH_CreateIsolate(const char* name, void* peer) {
  struct Helper {
    static void ShutdownCallback(void* ig_data, void* isolate_data) {
      char* string = reinterpret_cast<char*>(isolate_data);
      ENSURE(string[0] == 'a');
      string[0] = 'x';
    }
    static void CleanupCallback(void* ig_data, void* isolate_data) {
      char* string = reinterpret_cast<char*>(isolate_data);
      ENSURE(string[2] == 'c');
      string[2] = 'z';
    }
  };

  Dart_Isolate parent = Dart_CurrentIsolate();
  Dart_ExitIsolate();

  char* error = nullptr;
  Dart_Isolate child =
      Dart_CreateIsolateInGroup(parent, name, &Helper::ShutdownCallback,
                                &Helper::CleanupCallback, peer, &error);
  if (child == nullptr) {
    Dart_EnterIsolate(parent);
    Dart_Handle error_obj = Dart_NewStringFromCString(error);
    free(error);
    Dart_ThrowException(error_obj);
    return nullptr;
  }
  Dart_ExitIsolate();
  Dart_EnterIsolate(parent);
  return child;
}

DART_EXPORT void IGH_StartIsolate(Dart_Isolate child_isolate,
                                  int64_t main_isolate_port,
                                  const char* library_uri,
                                  const char* function_name,
                                  bool errors_are_fatal,
                                  Dart_Port on_error_port,
                                  Dart_Port on_exit_port) {
  Dart_Isolate parent = Dart_CurrentIsolate();
  Dart_ExitIsolate();
  Dart_EnterIsolate(child_isolate);
  {
    Dart_EnterScope();

    Dart_Handle library_name = Dart_NewStringFromCString(library_uri);
    ENSURE(!Dart_IsError(library_name));

    Dart_Handle library = Dart_LookupLibrary(library_name);
    ENSURE(!Dart_IsError(library));

    Dart_Handle fun = Dart_NewStringFromCString(function_name);
    ENSURE(!Dart_IsError(fun));

    Dart_Handle port = Dart_NewInteger(main_isolate_port);
    ENSURE(!Dart_IsError(port));

    Dart_Handle args[] = {
        port,
    };

    Dart_Handle result = Dart_Invoke(library, fun, 1, args);
    if (Dart_IsError(result)) {
      fprintf(stderr, "Failed to invoke %s/%s in child isolate: %s\n",
              library_uri, function_name, Dart_GetError(result));
    }
    ENSURE(!Dart_IsError(result));

    Dart_ExitScope();
  }

  char* error = nullptr;
  ENSURE(
      Dart_RunLoopAsync(errors_are_fatal, on_error_port, on_exit_port, &error));

  Dart_EnterIsolate(parent);
}

////////////////////////////////////////////////////////////////////////////////
// Initialize `dart_api_dl.h`
DART_EXPORT intptr_t InitDartApiDL(void* data) {
  return Dart_InitializeApiDL(data);
}

////////////////////////////////////////////////////////////////////////////////
// Functions for async callbacks example.
//
// sample_async_callback.dart

void Fatal(char const* file, int line, char const* error) {
  printf("FATAL %s:%i\n", file, line);
  printf("%s\n", error);
  Dart_DumpNativeStackTrace(NULL);
  Dart_PrepareToAbort();
  abort();
}

#define FATAL(error) Fatal(__FILE__, __LINE__, error)

void SleepOnAnyOS(intptr_t seconds) {
#if defined(HOST_OS_WINDOWS)
  Sleep(1000 * seconds);
#else
  sleep(seconds);
#endif
}

intptr_t (*my_callback_blocking_fp_)(intptr_t);
Dart_Port my_callback_blocking_send_port_;

void (*my_callback_non_blocking_fp_)(intptr_t);
Dart_Port my_callback_non_blocking_send_port_;

typedef std::function<void()> Work;

// Notify Dart through a port that the C lib has pending async callbacks.
//
// Expects heap allocated `work` so delete can be called on it.
//
// The `send_port` should be from the isolate which registered the callback.
void NotifyDart(Dart_Port send_port, const Work* work) {
  const intptr_t work_addr = reinterpret_cast<intptr_t>(work);
  printf("C   :  Posting message (port: %" Px64 ", work: %" Px ").\n",
         send_port, work_addr);

  Dart_CObject dart_object;
  dart_object.type = Dart_CObject_kInt64;
  dart_object.value.as_int64 = work_addr;

  const bool result = Dart_PostCObject_DL(send_port, &dart_object);
  if (!result) {
    FATAL("C   :  Posting message to port failed.");
  }
}

// Do a callback to Dart in a blocking way, being interested in the result.
//
// Dart returns `a + 3`.
intptr_t MyCallbackBlocking(intptr_t a) {
  std::mutex mutex;
  std::unique_lock<std::mutex> lock(mutex);
  intptr_t result;
  auto callback = my_callback_blocking_fp_;  // Define storage duration.
  std::condition_variable cv;
  bool notified = false;
  const Work work = [a, &result, callback, &cv, &notified]() {
    result = callback(a);
    printf("C Da:     Notify result ready.\n");
    notified = true;
    cv.notify_one();
  };
  const Work* work_ptr = new Work(work);  // Copy to heap.
  NotifyDart(my_callback_blocking_send_port_, work_ptr);
  printf("C   :  Waiting for result.\n");
  while (!notified) {
    cv.wait(lock);
  }
  printf("C   :  Received result.\n");
  return result;
}

// Do a callback to Dart in a non-blocking way.
//
// Dart sums all numbers posted to it.
void MyCallbackNonBlocking(intptr_t a) {
  auto callback = my_callback_non_blocking_fp_;  // Define storage duration.
  const Work work = [a, callback]() { callback(a); };
  // Copy to heap to make it outlive the function scope.
  const Work* work_ptr = new Work(work);
  NotifyDart(my_callback_non_blocking_send_port_, work_ptr);
}

// Simulated work for Thread #1.
//
// Simulates heavy work with sleeps.
void Work1() {
  printf("C T1: Work1 Start.\n");
  SleepOnAnyOS(1);
  const intptr_t val1 = 3;
  printf("C T1: MyCallbackBlocking(%" Pd ").\n", val1);
  const intptr_t val2 = MyCallbackBlocking(val1);  // val2 = 6.
  printf("C T1: MyCallbackBlocking returned %" Pd ".\n", val2);
  SleepOnAnyOS(1);
  const intptr_t val3 = val2 - 1;  // val3 = 5.
  printf("C T1: MyCallbackNonBlocking(%" Pd ").\n", val3);
  MyCallbackNonBlocking(val3);  // Post 5 to Dart.
  printf("C T1: Work1 Done.\n");
}

// Simulated work for Thread #2.
//
// Simulates lighter work, no sleeps.
void Work2() {
  printf("C T2: Work2 Start.\n");
  const intptr_t val1 = 5;
  printf("C T2: MyCallbackNonBlocking(%" Pd ").\n", val1);
  MyCallbackNonBlocking(val1);  // Post 5 to Dart.
  const intptr_t val2 = 1;
  printf("C T2: MyCallbackBlocking(%" Pd ").\n", val2);
  const intptr_t val3 = MyCallbackBlocking(val2);  // val3 = 4.
  printf("C T2: MyCallbackBlocking returned %" Pd ".\n", val3);
  printf("C T2: MyCallbackNonBlocking(%" Pd ").\n", val3);
  MyCallbackNonBlocking(val3);  // Post 4 to Dart.
  printf("C T2: Work2 Done.\n");
}

// Simulator that simulates concurrent work with multiple threads.
class SimulateWork {
 public:
  static void StartWorkSimulator() {
    running_work_simulator_ = new SimulateWork();
    running_work_simulator_->Start();
  }

  static void StopWorkSimulator() {
    running_work_simulator_->Stop();
    delete running_work_simulator_;
    running_work_simulator_ = nullptr;
  }

 private:
  static SimulateWork* running_work_simulator_;

  void Start() {
    printf("C Da:  Starting SimulateWork.\n");
    printf("C Da:   Starting worker threads.\n");
    thread1 = new std::thread(Work1);
    thread2 = new std::thread(Work2);
    printf("C Da:  Started SimulateWork.\n");
  }

  void Stop() {
    printf("C Da:  Stopping SimulateWork.\n");
    printf("C Da:   Waiting for worker threads to finish.\n");
    thread1->join();
    thread2->join();
    delete thread1;
    delete thread2;
    printf("C Da:  Stopped SimulateWork.\n");
  }

  std::thread* thread1;
  std::thread* thread2;
};
SimulateWork* SimulateWork::running_work_simulator_ = 0;

DART_EXPORT void RegisterMyCallbackBlocking(Dart_Port send_port,
                                            intptr_t (*callback1)(intptr_t)) {
  my_callback_blocking_fp_ = callback1;
  my_callback_blocking_send_port_ = send_port;
}

DART_EXPORT void RegisterMyCallbackNonBlocking(Dart_Port send_port,
                                               void (*callback)(intptr_t)) {
  my_callback_non_blocking_fp_ = callback;
  my_callback_non_blocking_send_port_ = send_port;
}

DART_EXPORT void StartWorkSimulator() {
  SimulateWork::StartWorkSimulator();
}

DART_EXPORT void StopWorkSimulator() {
  SimulateWork::StopWorkSimulator();
}

DART_EXPORT void ExecuteCallback(Work* work_ptr) {
  printf("C Da:    ExecuteCallback(%" Pp ").\n",
         reinterpret_cast<intptr_t>(work_ptr));
  const Work work = *work_ptr;
  work();
  delete work_ptr;
  printf("C Da:    ExecuteCallback done.\n");
}

////////////////////////////////////////////////////////////////////////////////
// Functions for async callbacks example.
//
// sample_native_port_call.dart

Dart_Port send_port_;

static void FreeFinalizer(void*, void* value) {
  free(value);
}

class PendingCall {
 public:
  PendingCall(void** buffer, size_t* length)
      : response_buffer_(buffer), response_length_(length) {
    receive_port_ =
        Dart_NewNativePort_DL("cpp-response", &PendingCall::HandleResponse,
                              /*handle_concurrently=*/false);
  }
  ~PendingCall() { Dart_CloseNativePort_DL(receive_port_); }

  Dart_Port port() const { return receive_port_; }

  void PostAndWait(Dart_Port port, Dart_CObject* object) {
    std::unique_lock<std::mutex> lock(mutex);
    const bool success = Dart_PostCObject_DL(send_port_, object);
    if (!success) FATAL("Failed to send message, invalid port or isolate died");

    printf("C   :  Waiting for result.\n");
    while (!notified) {
      cv.wait(lock);
    }
  }

  static void HandleResponse(Dart_Port p, Dart_CObject* message) {
    if (message->type != Dart_CObject_kArray) {
      FATAL("C   :   Wrong Data: message->type != Dart_CObject_kArray.\n");
    }
    Dart_CObject** c_response_args = message->value.as_array.values;
    Dart_CObject* c_pending_call = c_response_args[0];
    Dart_CObject* c_message = c_response_args[1];
    printf("C   :   HandleResponse (call: %" Px ", message: %" Px ").\n",
           reinterpret_cast<intptr_t>(c_pending_call),
           reinterpret_cast<intptr_t>(c_message));

    auto pending_call = reinterpret_cast<PendingCall*>(
        c_pending_call->type == Dart_CObject_kInt64
            ? c_pending_call->value.as_int64
            : c_pending_call->value.as_int32);

    pending_call->ResolveCall(c_message);
  }

 private:
  static bool NonEmptyBuffer(void** value) { return *value != nullptr; }

  void ResolveCall(Dart_CObject* bytes) {
    assert(bytes->type == Dart_CObject_kTypedData);
    if (bytes->type != Dart_CObject_kTypedData) {
      FATAL("C   :   Wrong Data: bytes->type != Dart_CObject_kTypedData.\n");
    }
    const intptr_t response_length = bytes->value.as_typed_data.length;
    const uint8_t* response_buffer = bytes->value.as_typed_data.values;
    printf("C   :    ResolveCall(length: %" Pd ", buffer: %" Px ").\n",
           response_length, reinterpret_cast<intptr_t>(response_buffer));

    void* buffer = malloc(response_length);
    memmove(buffer, response_buffer, response_length);

    *response_buffer_ = buffer;
    *response_length_ = response_length;

    printf("C   :     Notify result ready.\n");
    notified = true;
    cv.notify_one();
  }

  std::mutex mutex;
  std::condition_variable cv;
  bool notified = false;

  Dart_Port receive_port_;
  void** response_buffer_;
  size_t* response_length_;
};

// Do a callback to Dart in a blocking way, being interested in the result.
//
// Dart returns `a + 3`.
uint8_t MyCallback1(uint8_t a) {
  const char* methodname = "myCallback1";
  size_t request_length = sizeof(uint8_t) * 1;
  void* request_buffer = malloc(request_length);      // FreeFinalizer.
  reinterpret_cast<uint8_t*>(request_buffer)[0] = a;  // Populate buffer.
  void* response_buffer = nullptr;
  size_t response_length = 0;

  PendingCall pending_call(&response_buffer, &response_length);

  Dart_CObject c_send_port;
  c_send_port.type = Dart_CObject_kSendPort;
  c_send_port.value.as_send_port.id = pending_call.port();
  c_send_port.value.as_send_port.origin_id = ILLEGAL_PORT;

  Dart_CObject c_pending_call;
  c_pending_call.type = Dart_CObject_kInt64;
  c_pending_call.value.as_int64 = reinterpret_cast<int64_t>(&pending_call);

  Dart_CObject c_method_name;
  c_method_name.type = Dart_CObject_kString;
  c_method_name.value.as_string = const_cast<char*>(methodname);

  Dart_CObject c_request_data;
  c_request_data.type = Dart_CObject_kExternalTypedData;
  c_request_data.value.as_external_typed_data.type = Dart_TypedData_kUint8;
  c_request_data.value.as_external_typed_data.length = request_length;
  c_request_data.value.as_external_typed_data.data =
      static_cast<uint8_t*>(request_buffer);
  c_request_data.value.as_external_typed_data.peer = request_buffer;
  c_request_data.value.as_external_typed_data.callback = FreeFinalizer;

  Dart_CObject* c_request_arr[] = {&c_send_port, &c_pending_call,
                                   &c_method_name, &c_request_data};
  Dart_CObject c_request;
  c_request.type = Dart_CObject_kArray;
  c_request.value.as_array.values = c_request_arr;
  c_request.value.as_array.length =
      sizeof(c_request_arr) / sizeof(c_request_arr[0]);

  printf("C   :  Dart_PostCObject_(request: %" Px ", call: %" Px ").\n",
         reinterpret_cast<intptr_t>(&c_request),
         reinterpret_cast<intptr_t>(&c_pending_call));
  pending_call.PostAndWait(send_port_, &c_request);
  printf("C   :  Received result.\n");

  const intptr_t result = reinterpret_cast<uint8_t*>(response_buffer)[0];
  free(response_buffer);

  return result;
}

// Do a callback to Dart in a non-blocking way.
//
// Dart sums all numbers posted to it.
void MyCallback2(uint8_t a) {
  const char* methodname = "myCallback2";
  void* request_buffer = malloc(sizeof(uint8_t) * 1);  // FreeFinalizer.
  reinterpret_cast<uint8_t*>(request_buffer)[0] = a;   // Populate buffer.
  const size_t request_length = sizeof(uint8_t) * 1;

  Dart_CObject c_send_port;
  c_send_port.type = Dart_CObject_kNull;

  Dart_CObject c_pending_call;
  c_pending_call.type = Dart_CObject_kNull;

  Dart_CObject c_method_name;
  c_method_name.type = Dart_CObject_kString;
  c_method_name.value.as_string = const_cast<char*>(methodname);

  Dart_CObject c_request_data;
  c_request_data.type = Dart_CObject_kExternalTypedData;
  c_request_data.value.as_external_typed_data.type = Dart_TypedData_kUint8;
  c_request_data.value.as_external_typed_data.length = request_length;
  c_request_data.value.as_external_typed_data.data =
      static_cast<uint8_t*>(request_buffer);
  c_request_data.value.as_external_typed_data.peer = request_buffer;
  c_request_data.value.as_external_typed_data.callback = FreeFinalizer;

  Dart_CObject* c_request_arr[] = {&c_send_port, &c_pending_call,
                                   &c_method_name, &c_request_data};
  Dart_CObject c_request;
  c_request.type = Dart_CObject_kArray;
  c_request.value.as_array.values = c_request_arr;
  c_request.value.as_array.length =
      sizeof(c_request_arr) / sizeof(c_request_arr[0]);

  printf("C   :  Dart_PostCObject_(request: %" Px ", call: %" Px ").\n",
         reinterpret_cast<intptr_t>(&c_request),
         reinterpret_cast<intptr_t>(&c_pending_call));
  Dart_PostCObject_DL(send_port_, &c_request);
}

// Simulated work for Thread #1.
//
// Simulates heavy work with sleeps.
void Work1_2() {
  printf("C T1: Work1 Start.\n");
  SleepOnAnyOS(1);
  const intptr_t val1 = 3;
  printf("C T1: MyCallback1(%" Pd ").\n", val1);
  const intptr_t val2 = MyCallback1(val1);  // val2 = 6.
  printf("C T1: MyCallback1 returned %" Pd ".\n", val2);
  SleepOnAnyOS(1);
  const intptr_t val3 = val2 - 1;  // val3 = 5.
  printf("C T1: MyCallback2(%" Pd ").\n", val3);
  MyCallback2(val3);  // Post 5 to Dart.
  printf("C T1: Work1 Done.\n");
}

// Simulated work for Thread #2.
//
// Simulates lighter work, no sleeps.
void Work2_2() {
  printf("C T2: Work2 Start.\n");
  const intptr_t val1 = 5;
  printf("C T2: MyCallback2(%" Pd ").\n", val1);
  MyCallback2(val1);  // Post 5 to Dart.
  const intptr_t val2 = 1;
  printf("C T2: MyCallback1(%" Pd ").\n", val2);
  const intptr_t val3 = MyCallback1(val2);  // val3 = 4.
  printf("C T2: MyCallback1 returned %" Pd ".\n", val3);
  printf("C T2: MyCallback2(%" Pd ").\n", val3);
  MyCallback2(val3);  // Post 4 to Dart.
  printf("C T2: Work2 Done.\n");
}

// Simulator that simulates concurrent work with multiple threads.
class SimulateWork2 {
 public:
  static void StartWorkSimulator() {
    running_work_simulator_ = new SimulateWork2();
    running_work_simulator_->Start();
  }

  static void StopWorkSimulator() {
    running_work_simulator_->Stop();
    delete running_work_simulator_;
    running_work_simulator_ = nullptr;
  }

 private:
  static SimulateWork2* running_work_simulator_;

  void Start() {
    printf("C Da:  Starting SimulateWork.\n");
    printf("C Da:   Starting worker threads.\n");
    thread1 = new std::thread(Work1_2);
    thread2 = new std::thread(Work2_2);
    printf("C Da:  Started SimulateWork.\n");
  }

  void Stop() {
    printf("C Da:  Stopping SimulateWork.\n");
    printf("C Da:   Waiting for worker threads to finish.\n");
    thread1->join();
    thread2->join();
    delete thread1;
    delete thread2;
    printf("C Da:  Stopped SimulateWork.\n");
  }

  std::thread* thread1;
  std::thread* thread2;
};
SimulateWork2* SimulateWork2::running_work_simulator_ = 0;

DART_EXPORT void RegisterSendPort(Dart_Port send_port) {
  send_port_ = send_port;
}

DART_EXPORT void StartWorkSimulator2() {
  SimulateWork2::StartWorkSimulator();
}

DART_EXPORT void StopWorkSimulator2() {
  SimulateWork2::StopWorkSimulator();
}

////////////////////////////////////////////////////////////////////////////////
// Helpers used for lightweight isolate tests.
////////////////////////////////////////////////////////////////////////////////

DART_EXPORT void ThreadPoolTest_BarrierSync(
    Dart_Isolate (*dart_current_isolate)(),
    void (*dart_enter_isolate)(Dart_Isolate),
    void (*dart_exit_isolate)(),
    intptr_t num_threads) {
  // Guaranteed to be initialized exactly once (no race between multiple
  // threads).
  static std::mutex mutex;
  static std::condition_variable cvar;
  static intptr_t thread_count = 0;

  const Dart_Isolate isolate = dart_current_isolate();
  dart_exit_isolate();
  {
    std::unique_lock<std::mutex> lock(mutex);

    ++thread_count;
    if (thread_count < num_threads) {
      while (thread_count < num_threads) {
        cvar.wait(lock);
      }
    } else {
      if (thread_count != num_threads) FATAL("bug");
      cvar.notify_all();
    }
  }
  dart_enter_isolate(isolate);
}

////////////////////////////////////////////////////////////////////////////////
// Functions for handle tests.
//
// vmspecific_handle_test.dart (statically linked).
// vmspecific_handle_dynamically_linked_test.dart (dynamically linked).

static void RunFinalizer(void* isolate_callback_data, void* peer) {
  printf("Running finalizer for weak handle.\n");
}

// Tests that passing handles through FFI calls works, and that the FFI call
// sets up the VM state etc. correctly so that the handle API calls work.
DART_EXPORT Dart_Handle PassObjectToC(Dart_Handle h) {
  // Can use "h" until this function returns.

  // A persistent handle which outlives this call. Lifetime managed in C.
  auto persistent_handle = Dart_NewPersistentHandle(h);

  Dart_Handle handle_2 = Dart_HandleFromPersistent(persistent_handle);
  Dart_DeletePersistentHandle(persistent_handle);
  if (Dart_IsError(handle_2)) {
    Dart_PropagateError(handle_2);
  }

  Dart_Handle return_value;
  if (!Dart_IsNull(h)) {
    // A weak handle which outlives this call. Lifetime managed in C.
    auto weak_handle = Dart_NewWeakPersistentHandle(
        h, reinterpret_cast<void*>(0x1234), 64, RunFinalizer);
    return_value = Dart_HandleFromWeakPersistent(weak_handle);

    // Deleting a weak handle is not required, it deletes itself on
    // finalization.
    // Deleting a weak handle cancels the finalizer.
    Dart_DeleteWeakPersistentHandle(weak_handle);
  } else {
    return_value = h;
  }

  return return_value;
}

DART_EXPORT void ClosureCallbackThroughHandle(void (*callback)(Dart_Handle),
                                              Dart_Handle closureHandle) {
  printf("ClosureCallbackThroughHandle %p %p\n", callback, closureHandle);
  callback(closureHandle);
}

DART_EXPORT Dart_Handle ReturnHandleInCallback(Dart_Handle (*callback)()) {
  printf("ReturnHandleInCallback %p\n", callback);
  Dart_Handle handle = callback();
  if (Dart_IsError(handle)) {
    printf("callback() returned an error, propagating error\n");
    // Do C/C++ resource cleanup if needed, before propagating error.
    Dart_PropagateError(handle);
  }
  return handle;
}

// Recurses til `i` reaches 0. Throws some Dart_Invoke in there as well.
DART_EXPORT Dart_Handle HandleRecursion(Dart_Handle object,
                                        Dart_Handle (*callback)(int64_t),
                                        int64_t i) {
  printf("HandleRecursion %" Pd64 "\n", i);
  const bool do_invoke = i % 3 == 0;
  const bool do_gc = i % 7 == 3;
  if (do_gc) {
    Dart_ExecuteInternalCommand("gc-now", nullptr);
  }
  Dart_Handle result;
  if (do_invoke) {
    Dart_Handle method_name = Dart_NewStringFromCString("a");
    if (Dart_IsError(method_name)) {
      Dart_PropagateError(method_name);
    }
    Dart_Handle arg = Dart_NewInteger(i - 1);
    if (Dart_IsError(arg)) {
      Dart_PropagateError(arg);
    }
    printf("Dart_Invoke\n");
    result = Dart_Invoke(object, method_name, 1, &arg);
  } else {
    printf("callback\n");
    result = callback(i - 1);
  }
  if (do_gc) {
    Dart_ExecuteInternalCommand("gc-now", nullptr);
  }
  if (Dart_IsError(result)) {
    // Do C/C++ resource cleanup if needed, before propagating error.
    printf("Dart_PropagateError %" Pd64 "\n", i);
    Dart_PropagateError(result);
  }
  printf("return %" Pd64 "\n", i);
  return result;
}

DART_EXPORT int64_t HandleReadFieldValue(Dart_Handle handle) {
  printf("HandleReadFieldValue\n");
  Dart_Handle field_name = Dart_NewStringFromCString("a");
  if (Dart_IsError(field_name)) {
    printf("Dart_PropagateError(field_name)\n");
    Dart_PropagateError(field_name);
  }
  Dart_Handle field_value = Dart_GetField(handle, field_name);
  if (Dart_IsError(field_value)) {
    printf("Dart_PropagateError(field_value)\n");
    Dart_PropagateError(field_value);
  }
  int64_t value;
  Dart_Handle err = Dart_IntegerToInt64(field_value, &value);
  if (Dart_IsError(err)) {
    Dart_PropagateError(err);
  }
  return value;
}

// Does not have a handle in it's own signature, so does not enter and exit
// scope in the trampoline.
DART_EXPORT int64_t PropagateErrorWithoutHandle(Dart_Handle (*callback)()) {
  Dart_EnterScope();
  Dart_Handle result = callback();
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }
  Dart_ExitScope();
  return 0;
}

DART_EXPORT Dart_Handle TrueHandle() {
  return Dart_True();
}

DART_EXPORT Dart_Handle PassObjectToCUseDynamicLinking(Dart_Handle h) {
  auto persistent_handle = Dart_NewPersistentHandle_DL(h);

  Dart_Handle handle_2 = Dart_HandleFromPersistent_DL(persistent_handle);
  Dart_SetPersistentHandle_DL(persistent_handle, h);
  Dart_DeletePersistentHandle_DL(persistent_handle);

  auto weak_handle = Dart_NewWeakPersistentHandle_DL(
      handle_2, reinterpret_cast<void*>(0x1234), 64, RunFinalizer);
  Dart_Handle return_value = Dart_HandleFromWeakPersistent_DL(weak_handle);

  Dart_DeleteWeakPersistentHandle_DL(weak_handle);

  return return_value;
}

////////////////////////////////////////////////////////////////////////////////
// Example for doing closure callbacks with help of `dart_api.h`.
//
// sample_ffi_functions_callbacks_closures.dart

void (*callback_)(Dart_Handle);
Dart_PersistentHandle closure_to_callback_;

DART_EXPORT void RegisterClosureCallbackFP(void (*callback)(Dart_Handle)) {
  callback_ = callback;
}

DART_EXPORT void RegisterClosureCallback(Dart_Handle h) {
  closure_to_callback_ = Dart_NewPersistentHandle_DL(h);
}

DART_EXPORT void InvokeClosureCallback() {
  Dart_Handle closure_handle =
      Dart_HandleFromPersistent_DL(closure_to_callback_);
  callback_(closure_handle);
}

DART_EXPORT void ReleaseClosureCallback() {
  Dart_DeletePersistentHandle_DL(closure_to_callback_);
}

}  // namespace dart
