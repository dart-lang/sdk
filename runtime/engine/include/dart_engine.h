// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_ENGINE_INCLUDE_DART_ENGINE_H_
#define RUNTIME_ENGINE_INCLUDE_DART_ENGINE_H_
#include "include/dart_api.h"

/**
 * Initializes the Dart engine.
 *
 * \param[out] error Set to NULL if initialization was successful.
 *    Otherwise is set to a description of error which occurred during
 *    initialization. The caller is responsible for freeing the error string.
 *
 * \return true if initialization is successful and false otherwise.
 */
DART_EXPORT bool DartEngine_Init(char** error);

/**
 * Shuts down the Dart engine.
 *
 * Stops all isolates and frees all resources.
 */
DART_EXPORT void DartEngine_Shutdown();

/**
 * Kind of a snapshot represented by DartEngine_SnapshotData.
 */
typedef enum {
  DartEngine_SnapshotKind_Kernel,
  DartEngine_SnapshotKind_AOT,
} DartEngine_SnapshotKind;

/**
 * Dart snapshot data, sufficient to create an isolate.
 */
typedef struct DartEngine_SnapshotData {
  /**
   * Uniquely identifies a snapshot.
   *
   * It is passed to \ref Dart_CreateIsolateGroup or
   * \ref Dart_CreateIsolateGroupFromKernel.
   */
  const char* script_uri;
  /**
   * Whether this snapshot data reprents Kernel or AOT snapshot.
   */
  DartEngine_SnapshotKind kind;
  union {
    struct {
      const uint8_t* kernel_buffer;
      intptr_t kernel_buffer_size;
    };
    struct {
      const uint8_t* vm_snapshot_data;
      const uint8_t* vm_snapshot_instructions;
      const uint8_t* vm_isolate_data;
      const uint8_t* vm_isolate_instructions;
    };
  };
} DartEngine_SnapshotData;

/**
 * Creates a new isolate for a given snapshot.
 *
 * \param snapshot_data Snapshot to start an isolate from.
 * \param[out] error Set to NULL if an isolate is created successfully.
 *    Otherwise is set to a description of error which occurred during
 *    isolate creation. The caller is responsible for freeing the error string.
 *
 * \return The new isolate on success, or NULL if isolate creation failed.
 */
DART_EXPORT Dart_Isolate
DartEngine_CreateIsolate(DartEngine_SnapshotData snapshot_data, char** error);

/**
 * Blocks until the isolate is available for entering and enters an isolate.
 *
 * This is an alternative to \ref Dart_EnterIsolate, which can be used when
 * multiple threads may try to enter the same isolate at the same time.
 *
 * Use \ref DartEngine_ReleaseIsolate instead of `Dart_ExitIsolate` if you
 * use this function.
 */
DART_EXPORT void DartEngine_AcquireIsolate(Dart_Isolate isolate);

/**
 * Exits an isolate and makes it available for entering by other threads.
 *
 * This is an alternative to \ref Dart_ExitIsolate, which should be used
 * if you use \ref DartEngine_AcquireIsolate.
 */
DART_EXPORT void DartEngine_ReleaseIsolate();

/**
 * A callback invoked when there's an error handling isolate message.
 *
 * \param error Dart error happened during handling a message.
 * \param destination_isolate The isolate where the error occurred.
 */
typedef void (*DartEngine_HandleMessageErrorCallback)(
    Dart_Handle error,
    Dart_Isolate destination_isolate);

/**
 * Sets the callback for errors during handling isolate messages.
 */
DART_EXPORT void DartEngine_SetHandleMessageErrorCallback(
    DartEngine_HandleMessageErrorCallback handle_message_error_callback);

/**
 * Handles a single message for an isolate.
 */
DART_EXPORT void DartEngine_HandleMessage(Dart_Isolate isolate);

/**
 * Message scheduling callback.
 *
 * Dart Engine calls this callback whenever there's a new message for an
 * isolate, and the callback should schedule an execution of
 * DartEngine_HandleMessage with given isolate.
 *
 * \param isolate Destination isolate for a mesage.
 * \param context Context from \ref DartEngine_MessageScheduler.
 */
typedef void (*DartEngine_ScheduleMessageCallback)(Dart_Isolate isolate,
                                                   void* context);

/**
 * Scheduler for isolate messages.
 *
 * Whenever Dart isolate has a new message, the Dart engine will
 * call schedule_callback and pass context into it.
 */
typedef struct DartEngine_MessageScheduler {
  DartEngine_ScheduleMessageCallback schedule_callback;
  void* context;
} DartEngine_MessageScheduler;

/**
 * Sets default message scheduler for all isolates.
 */
DART_EXPORT void DartEngine_SetDefaultMessageScheduler(
    DartEngine_MessageScheduler scheduler);

/**
 * Sets message scheduler for isolate.
 */
DART_EXPORT void DartEngine_SetMessageScheduler(
    DartEngine_MessageScheduler scheduler,
    Dart_Isolate isolate);

/**
 * Loads \ref DartEngine_SnapshotData from file
 *
 * User should not free uri and buffer.
 *
 * \param[out] error Set to NULL if snapshot could be loaded successfully.
 *    Otherwise is set to a description of error which occurred during
 *    snapshot loading. The caller is responsible for freeing the error string.
 *
 * \return Snapshot data with kind set to \ref DartEngine_SnapshotKind_Kernel.
 */
DART_EXPORT DartEngine_SnapshotData DartEngine_KernelFromFile(const char* path,
                                                              char** error);
/**
 * Loads \ref DartEngine_SnapshotData from file
 *
 * User should not free uri and buffers.
 *
 * \param[out] error Set to NULL if snapshot could be loaded successfully.
 *    Otherwise is set to a description of error which occurred during
 *    snapshot loading. The caller is responsible for freeing the error string.
 *
 * \return Snapshot data with kind set to \ref DartEngine_SnapshotKind_AOT.
 */
DART_EXPORT DartEngine_SnapshotData
DartEngine_AotSnapshotFromFile(const char* path, char** error);

#endif  // RUNTIME_ENGINE_INCLUDE_DART_ENGINE_H_
