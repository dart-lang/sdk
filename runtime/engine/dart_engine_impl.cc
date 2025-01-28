// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <cstdint>
#include <memory>
#include <vector>
#include "engine/engine.h"
#include "include/dart_api.h"
#include "include/dart_engine.h"
#include "platform/utils.h"

namespace dart {
namespace engine {

DART_EXPORT bool DartEngine_Init(char** error) {
  return Engine::instance()->Initialize(error);
}

DART_EXPORT void DartEngine_Shutdown() {
  Engine::instance()->Shutdown();
}

DART_EXPORT DartEngine_SnapshotData DartEngine_KernelFromFile(const char* path,
                                                              char** error) {
  return Engine::instance()->KernelFromFile(path, error);
}

DART_EXPORT DartEngine_SnapshotData
DartEngine_AotSnapshotFromFile(const char* path, char** error) {
  return Engine::instance()->AotFromFile(path, error);
}

DART_EXPORT Dart_Isolate
DartEngine_CreateIsolate(DartEngine_SnapshotData snapshot_data, char** error) {
  if (!Engine::instance()->Initialize(error)) {
    return nullptr;
  }
  return Engine::instance()->StartIsolate(snapshot_data, error);
}

DART_EXPORT void DartEngine_AcquireIsolate(Dart_Isolate isolate) {
  Engine::instance()->LockIsolate(isolate);
  Dart_EnterIsolate(isolate);
}

DART_EXPORT void DartEngine_ReleaseIsolate() {
  Dart_Isolate current = Dart_CurrentIsolate();
  ASSERT(current != nullptr);
  Dart_ExitIsolate();
  Engine::instance()->UnlockIsolate(current);
}

DART_EXPORT void DartEngine_SetHandleMessageErrorCallback(
    DartEngine_HandleMessageErrorCallback handle_message_error_callback) {
  Engine::instance()->SetHandleMessageErrorCallback(
      handle_message_error_callback);
}

DART_EXPORT void DartEngine_SetDefaultMessageScheduler(
    DartEngine_MessageScheduler scheduler) {
  Engine::instance()->SetDefaultMessageScheduler(scheduler);
}

DART_EXPORT void DartEngine_SetMessageScheduler(
    DartEngine_MessageScheduler scheduler,
    Dart_Isolate isolate) {
  Engine::instance()->SetMessageScheduler(scheduler, isolate);
}

DART_EXPORT void DartEngine_HandleMessage(Dart_Isolate isolate) {
  Engine::instance()->HandleMessage(isolate);
}

}  // namespace engine
}  // namespace dart
