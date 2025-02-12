// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <condition_variable>
#include <iostream>
#include <mutex>
#include <queue>
#include <thread>
#include "helpers.h"
#include "include/dart_api.h"
#include "include/dart_engine.h"

// Calls `startTimer` from timer.dart
void StartTimer(Dart_Isolate isolate, uint32_t millis) {
  WithIsolate<void>(isolate, [&]() {
    std::initializer_list<Dart_Handle> args{Dart_NewInteger(millis)};
    CheckError(
        Dart_Invoke(Dart_RootLibrary(), Dart_NewStringFromCString("startTimer"),
                    1, const_cast<Dart_Handle*>(args.begin())),
        "calling startTimer");
  });
}

// Calls `stopTimer` from timer.dart
void StopTimer(Dart_Isolate isolate) {
  WithIsolate<void>(isolate, [&]() {
    CheckError(Dart_Invoke(Dart_RootLibrary(),
                           Dart_NewStringFromCString("stopTimer"), 0, nullptr),
               "calling stopTimer");
  });
}

// Gets `ticks` from timer.dart
int64_t GetTicks(Dart_Isolate isolate) {
  return WithIsolate<int64_t>(isolate, []() {
    return IntFromHandle(
        Dart_GetField(Dart_RootLibrary(), Dart_NewStringFromCString("ticks")));
  });
}

// Queue-based message handler, running on a separate thread.
class ThreadedMessageHandler {
 public:
  void Run() {
    is_running = true;
    while (is_running) {
      Dart_Isolate isolate;
      {
        std::unique_lock notifications_lock(notifications_mutex_);
        can_pop_.wait(notifications_lock);
        if (notifications_.empty()) {
          continue;
        }
        isolate = notifications_.front();
        notifications_.pop();
      }
      DartEngine_HandleMessage(isolate);
    }
  }

  void Notify(Dart_Isolate isolate) {
    std::unique_lock notifications_lock(notifications_mutex_);
    notifications_.push(isolate);
    can_pop_.notify_one();
  }

  void Stop() {
    is_running = false;
    can_pop_.notify_one();
  }

  static void ScheduleDartMessage(Dart_Isolate isolate, void* context) {
    reinterpret_cast<ThreadedMessageHandler*>(context)->Notify(isolate);
  }

 private:
  std::queue<Dart_Isolate> notifications_;
  std::condition_variable can_pop_;
  std::atomic<bool> is_running;
  std::mutex notifications_mutex_;
};

int main(int argc, char** argv) {
  if (argc == 1) {
    std::cerr << "Must specify snapshot path" << std::endl;
    std::exit(1);
  }
  char* error = nullptr;

  // Start an event loop on a separate thread and use it as a default
  // scheduler.
  ThreadedMessageHandler message_handler;
  std::thread message_handler_thread(&ThreadedMessageHandler::Run,
                                     &message_handler);
  DartEngine_SetDefaultMessageScheduler(
      {ThreadedMessageHandler::ScheduleDartMessage, &message_handler});

  // Load snapshot and create an isolate
  DartEngine_SnapshotData snapshot_data = AutoSnapshotFromFile(argv[1], &error);
  CheckError(error, "reading snapshot");
  Dart_Isolate isolate = DartEngine_CreateIsolate(snapshot_data, &error);
  CheckError(error, "creating isolate");

  // Call Dart function to start a timer.
  StartTimer(isolate, 1);

  // Wait a bit.
  std::this_thread::sleep_for(std::chrono::milliseconds(100));

  // Stop the timer.
  StopTimer(isolate);

  // Get timer value.
  std::cout << "Ticks: " << GetTicks(isolate) << std::endl;

  // Stop event loop.
  message_handler.Stop();
  message_handler_thread.join();

  DartEngine_Shutdown();
}
