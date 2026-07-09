// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <chrono>
#include <future>
#include <iostream>
#include <thread>
#include "helpers.h"
#include "include/dart_api.h"
#include "include/dart_engine.h"

void ScheduleDartMessage(Dart_Isolate isolate, void* context) {
  std::ignore = std::async(DartEngine_HandleMessage, isolate);
}

void FulfillIntPromise(void* context, int64_t value) {
  auto promise = reinterpret_cast<std::promise<int64_t>*>(context);
  promise->set_value(value);
  delete promise;
}

// Helper to call Dart function `returnRegularFutureC`.
std::future<int64_t> ReturnRegularFuture(Dart_Isolate isolate,
                                         int64_t delay_ms,
                                         bool use_microtask) {
  auto promise = new std::promise<int64_t>();
  auto result = promise->get_future();

  IsolateScope isolate_scope(isolate);
  DartScope dart_scope;

  // args
  Dart_Handle args[] = {
      Dart_NewInteger(delay_ms), Dart_NewBoolean(use_microtask),
      Dart_NewInteger(
          reinterpret_cast<intptr_t>(&FulfillIntPromise)),  // callback
      Dart_NewInteger(reinterpret_cast<intptr_t>(promise))  // context
  };

  // call
  CheckError(Dart_Invoke(Dart_RootLibrary(),
                         Dart_NewStringFromCString("returnRegularFutureC"), 4,
                         args));
  CheckError(DartEngine_DrainMicrotasksQueue(), "draining microtasks queue");

  return result;
}

// Helper to call Dart function `sumIntStreamC`.
std::future<int64_t> SumIntStream(Dart_Isolate isolate,
                                  int count,
                                  int64_t delay_ms,
                                  bool use_async_star) {
  auto promise = new std::promise<int64_t>();
  auto result = promise->get_future();

  IsolateScope isolate_scope(isolate);
  DartScope dart_scope;

  // args
  Dart_Handle args[] = {
      Dart_NewInteger(count), Dart_NewInteger(delay_ms),
      Dart_NewBoolean(use_async_star),
      Dart_NewInteger(
          reinterpret_cast<intptr_t>(&FulfillIntPromise)),  // callback
      Dart_NewInteger(reinterpret_cast<intptr_t>(promise))  // context
  };

  // call
  CheckError(Dart_Invoke(Dart_RootLibrary(),
                         Dart_NewStringFromCString("sumIntStreamC"), 5, args));
  CheckError(DartEngine_DrainMicrotasksQueue(), "draining microtasks queue");

  return result;
}

class AwaitAndMultiplyCall {
 public:
  AwaitAndMultiplyCall(Dart_Isolate isolate,
                       Dart_PersistentHandle handle,
                       std::future<int64_t>&& result)
      : result(std::move(result)), isolate_(isolate), handle_(handle) {}

  void CompleteA(int64_t value) {
    IsolateScope isolate_scope(isolate_);
    DartScope dart_scope;

    Dart_Handle args[] = {Dart_NewInteger(value)};
    CheckError(
        Dart_Invoke(handle_, Dart_NewStringFromCString("setA"), 1, args));
    CheckError(DartEngine_DrainMicrotasksQueue(), "draining microtasks queue");
  }

  void CompleteB(int64_t value) {
    IsolateScope isolate_scope(isolate_);
    DartScope dart_scope;

    Dart_Handle args[] = {Dart_NewInteger(value)};
    CheckError(
        Dart_Invoke(handle_, Dart_NewStringFromCString("setB"), 1, args));
    CheckError(DartEngine_DrainMicrotasksQueue(), "draining microtasks queue");
  }

  std::future<int64_t> result;

  void Release() {
    IsolateScope isolate_scope(isolate_);
    DartScope dart_scope;

    Dart_DeletePersistentHandle(handle_);
  }

 private:
  Dart_Isolate isolate_;
  Dart_PersistentHandle handle_;
};

AwaitAndMultiplyCall AwaitAndMultiply(Dart_Isolate isolate) {
  auto promise = new std::promise<int64_t>();
  auto future = promise->get_future();

  IsolateScope isolate_scope(isolate);
  DartScope dart_scope;

  Dart_Handle args[] = {
      Dart_NewInteger(reinterpret_cast<intptr_t>(&FulfillIntPromise)),
      Dart_NewInteger(reinterpret_cast<intptr_t>(promise)),
  };
  Dart_PersistentHandle call_handle = Dart_NewPersistentHandle(CheckError(
      Dart_Invoke(Dart_RootLibrary(),
                  Dart_NewStringFromCString("awaitAndMultiplyC"), 2, args)));
  CheckError(DartEngine_DrainMicrotasksQueue(), "draining microtasks queue");

  return AwaitAndMultiplyCall(isolate, call_handle, std::move(future));
}

int main(int argc, char** argv) {
  if (argc == 1) {
    std::cerr << "Must specify snapshot path" << std::endl;
    std::exit(1);
  }
  char* error = nullptr;

  //
  // Set up message handling and start isolate.
  //
  DartEngine_MessageScheduler scheduler{ScheduleDartMessage, nullptr};
  DartEngine_SetDefaultMessageScheduler(scheduler);

  DartEngine_SnapshotData snapshot_data = AutoSnapshotFromFile(argv[1], &error);
  CheckError(error, "reading snapshot");
  Dart_Isolate isolate = DartEngine_CreateIsolate(snapshot_data, &error);
  CheckError(error, "creating isolate");

  //
  // Call Dart functions.
  //

  auto result1 = ReturnRegularFuture(isolate, 5, false).get();
  std::cout << "returnRegularFutureC(useMicrotask = false) returns: " << result1
            << std::endl;

  auto result2 = ReturnRegularFuture(isolate, 5, true).get();
  std::cout << "returnRegularFutureC(useMicrotask = true) returns: " << result2
            << std::endl;

  auto result3 = SumIntStream(isolate, 5, 5, false).get();
  std::cout << "sumIntStream(useAsyncStar = false) returns: " << result3
            << std::endl;

  auto result4 = SumIntStream(isolate, 5, 5, true).get();
  std::cout << "sumIntStream(useAsyncStar = true) returns: " << result4
            << std::endl;

  auto call = AwaitAndMultiply(isolate);
  std::this_thread::sleep_for(std::chrono::milliseconds(1));
  call.CompleteB(5);
  std::this_thread::sleep_for(std::chrono::milliseconds(1));
  call.CompleteA(20);
  auto result5 = call.result.get();
  std::cout << "awaitAndMultiply(5, 20) = " << result5 << std::endl;
  call.Release();
  //
  // Shutdown
  //
  DartEngine_Shutdown();
}
