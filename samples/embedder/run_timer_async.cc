// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Same as run_timer.cc, but uses std::async instead of a dedicated event loop
// thread. Used as a demonstration of a custom message scheduler.
#include <future>
#include <iostream>
#include <thread>
#include "helpers.h"
#include "include/dart_api.h"
#include "include/dart_engine.h"
#include "timer.h"

std::mutex shutdown_mutex;

void ScheduleDartMessage(Dart_Isolate isolate, void* context) {
  std::ignore = std::async(DartEngine_HandleMessage, isolate);
}

int main(int argc, char** argv) {
  if (argc == 1) {
    std::cerr << "Must specify snapshot path" << std::endl;
    std::exit(1);
  }
  char* error = nullptr;

  // Start an event loop on a separate thread and use it as a default
  // scheduler.
  DartEngine_MessageScheduler scheduler{ScheduleDartMessage, nullptr};
  DartEngine_SetDefaultMessageScheduler(scheduler);

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

  DartEngine_Shutdown();
}
