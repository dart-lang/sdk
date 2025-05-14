// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_ENGINE_ENGINE_H_
#define RUNTIME_ENGINE_ENGINE_H_

#include <memory>
#include <unordered_map>
#include <vector>
#include "include/dart_engine.h"
#include "platform/synchronization.h"

namespace dart {
namespace engine {

// Manages Dart VM initialization/shutdown, isolates, and all state that needs
// to be disposed (e.g. buffers of loaded snapshots).
//
// Since Dart VM has a global state, there should be only one instance of this
// class (accessible through Engine::instance()).
class Engine {
 public:
  // Loads Kernel snapshot from given file path.
  //
  // Just reads all bytes into a single buffer, owned by this class.
  DartEngine_SnapshotData KernelFromFile(const char* path, char** error);

  // Loads AOT snapshot from given file path.
  //
  // Opens given AOT snapshot as a shared library and loads buffer symbols from
  // it.
  DartEngine_SnapshotData AotFromFile(const char* path, char** error);

  // Starts an isolate from a snapshot.
  //
  // Starting an isolate also routes message notify callback to NotifyMessage.
  Dart_Isolate StartIsolate(const DartEngine_SnapshotData snapshot,
                            char** error);

  // Acquires a lock for an isolate, so that the thread can enter it.
  void LockIsolate(Dart_Isolate isolate);

  // Releases the lock obtained by LockIsolate.
  void UnlockIsolate(Dart_Isolate isolate);

  // Called by Dart VM via Engine::MessageNotifyCallback.
  //
  // Calls isolate-specific message scheduler (if any), default message
  // scheduler, or ignores the message.
  void NotifyMessage(Dart_Isolate isolate);

  // Calls Dart_HandleMessage, managing an isolate lock and Dart scope.
  void HandleMessage(Dart_Isolate isolate);

  // Drains the microtasks queue, requires an active isolate.
  Dart_Handle DrainMicrotasksQueue();

  // Sets a callback to be called when Dart_HandleMessage returns an error.
  void SetHandleMessageErrorCallback(
      DartEngine_HandleMessageErrorCallback callback);

  // Sets a message scheduler for a given isolate.
  void SetDefaultMessageScheduler(DartEngine_MessageScheduler scheduler);

  // Sets default message scheduler for isolates without dedicated
  // message scheduler.
  void SetMessageScheduler(DartEngine_MessageScheduler scheduler,
                           Dart_Isolate isolate);

  // Initializes embedder and partially initializes Dart VM.
  //
  // Full initialization happens only when the user starts the first isolate, as
  // in case of AOT snapshots we don't have vm snapshot data and vm snapshot
  // instuructions before the user makes the first call to StartIsolate.
  bool Initialize(char** error);

  // Shuts down the engine.
  //
  // Once shut down, it is not supposed to be re-initialized.
  void Shutdown();

  static Engine* instance();
  // Passed to Dart_SetMessageNotifyCallback.
  static void MessageNotifyCallback(Dart_Isolate isolate);
  // Passed to user-previded message scheduler callback.
  static void HandleMessageCallback(Dart_Isolate isolate);

 private:
  // Engine's internal data for isolate.
  struct IsolateData {
    DartEngine_MessageScheduler scheduler;
    Mutex mutex;
    Dart_PersistentHandle isolate_library;
    Dart_PersistentHandle drain_microtasks_function_name;
  };

  // Set to false once shutdown starts.
  bool is_running_ = false;

  // Controls initalization and shutdown, and prevents deadlocks when delivering
  // messages during shutdown.
  Mutex engine_lifecycle_;

  // Guards access to engine state.
  Mutex engine_state_;

  // Whether Engine::Initialize is called.
  bool initialized_ = false;

  // Added because of AOT mode, because in AOT mode Dart VM cannot be fully
  // initialized until we get vm snapshot data, which we typically get when the
  // user starts the first isolate.
  bool first_isolate_started_ = false;

  // Snapshots, whose buffers are owned by the engine.
  // and are freed on Shutdown.
  std::vector<DartEngine_SnapshotData> owned_snapshots_;

  // Loaded dynamic libraries. Dynamic libraries are loaded
  // when reading AOT snapshots.
  std::vector<void*> loaded_libraries_;

  // All isolates, started via Engine::StartIsolate.
  std::vector<Dart_Isolate> isolates_;

  // Stores per-isolate engine state.
  std::unordered_map<Dart_Isolate, std::shared_ptr<IsolateData>> isolate_data_;

  // Default scheduler.
  DartEngine_MessageScheduler default_scheduler_;

  // Callback to notify about Dart_HandleMessage errors.
  DartEngine_HandleMessageErrorCallback handle_message_error_callback_;

  // Helper function to get an element from isolate_data_.
  std::shared_ptr<IsolateData> DataForIsolate(Dart_Isolate isolate);
};

}  // namespace engine
}  // namespace dart
#endif  // RUNTIME_ENGINE_ENGINE_H_
