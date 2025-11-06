// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <atomic>
#include <condition_variable>
#include <iostream>
#include <mutex>
#include <queue>
#include <thread>
#include "helpers.h"
#include "include/dart_api.h"
#include "include/dart_engine.h"
#include "timer.h"

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
  Call_startTimer(isolate, 1);

  // Wait a bit.
  std::this_thread::sleep_for(std::chrono::milliseconds(100));

  // Stop the timer.
  Call_stopTimer(isolate);

  // Get timer value.
  std::cout << "Ticks: " << Get_ticks(isolate) << std::endl;

  // Stop event loop.
  message_handler.Stop();
  message_handler_thread.join();

  DartEngine_Shutdown();
}
