// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "engine/engine.h"
#include <errno.h>
#include <memory>
#include "bin/dartutils.h"
#include "include/dart_api.h"
#include "include/dart_embedder_api.h"
#include "include/dart_engine.h"
#include "platform/lockers.h"
#include "platform/syslog.h"
#include "platform/utils.h"

namespace dart {
namespace engine {

constexpr char kRunPendingImmediateCallback[] = "_runPendingImmediateCallback";

using platform::MutexLocker;

Engine* Engine::instance() {
  static Engine* instance = new Engine();
  return instance;
}

DartEngine_SnapshotData Engine::KernelFromFile(const char* path, char** error) {
  DartEngine_SnapshotData result;
  result.kind = DartEngine_SnapshotKind_Kernel;
  result.script_uri = Utils::SCreate("file://%s", path);
  FILE* file = fopen(path, "rb");
  if (file == nullptr) {
    *error = Utils::SCreate("Error %d", errno);
    return result;
  }

  fseek(file, 0, SEEK_END);
  intptr_t size = ftell(file);
  rewind(file);

  char* buffer = reinterpret_cast<char*>(malloc(sizeof(char) * size));

  intptr_t bytes_read = fread(buffer, 1, size, file);
  fclose(file);
  if (bytes_read != size) {
    free(buffer);
    *error = Utils::SCreate("Error reading %s: read %zu bytes instead of %zu",
                            path, bytes_read, size);
    return result;
  }

  result.kernel_buffer_size = size;
  result.kernel_buffer = reinterpret_cast<uint8_t*>(buffer);

  {
    MutexLocker ml(&engine_state_);
    owned_snapshots_.emplace_back(result);
  }

  return result;
}

DartEngine_SnapshotData Engine::AotFromFile(const char* path, char** error) {
  DartEngine_SnapshotData result;
  result.kind = DartEngine_SnapshotKind_AOT;
  result.script_uri = Utils::SCreate("file://%s", path);

  void* library =
      Utils::LoadDynamicLibrary(path, /*search_dll_load_dir=*/false, error);

  result.vm_snapshot_data = reinterpret_cast<const uint8_t*>(
      Utils::ResolveSymbolInDynamicLibrary(library, kVmSnapshotDataCSymbol));
  result.vm_snapshot_instructions =
      reinterpret_cast<const uint8_t*>(Utils::ResolveSymbolInDynamicLibrary(
          library, kVmSnapshotInstructionsCSymbol));
  result.vm_isolate_data =
      reinterpret_cast<const uint8_t*>(Utils::ResolveSymbolInDynamicLibrary(
          library, kIsolateSnapshotDataCSymbol));
  result.vm_isolate_instructions =
      reinterpret_cast<const uint8_t*>(Utils::ResolveSymbolInDynamicLibrary(
          library, kIsolateSnapshotInstructionsCSymbol));

  if (*error != nullptr) {
    return result;
  }

  {
    MutexLocker ml(&engine_state_);
    loaded_libraries_.emplace_back(library);
    owned_snapshots_.emplace_back(result);
  }

  return result;
}

namespace {
Dart_InitializeParams CreateInitializeParams() {
  Dart_InitializeParams params;
  memset(&params, 0, sizeof(params));
  params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
  params.shutdown_isolate = nullptr;
  params.create_group = nullptr;
  return params;
}
}  // namespace

bool Engine::Initialize(char** error) {
  if (initialized_) {
    return true;
  }
  MutexLocker ml(&engine_lifecycle_);

  if (initialized_) {
    return true;
  }
  if (!dart::embedder::InitOnce(error)) {
    return false;
  }

  std::vector<const char*> flags{};
  if (Dart_IsPrecompiledRuntime()) {
    flags.push_back("--precompilation");
  }
  *error = Dart_SetVMFlags(flags.size(), flags.data());

  if (*error != nullptr) {
    return false;
  }

  initialized_ = true;

  return true;
}

Dart_Isolate Engine::StartIsolate(DartEngine_SnapshotData snapshot,
                                  char** error) {
  if (Dart_IsPrecompiledRuntime() &&
      snapshot.kind != DartEngine_SnapshotKind_AOT) {
    *error = Utils::StrDup("AOT Dart VM supports only AOT snapshots");
    return nullptr;
  }

  if (!Dart_IsPrecompiledRuntime() &&
      snapshot.kind != DartEngine_SnapshotKind_Kernel) {
    *error = Utils::StrDup("AOT Dart VM supports only AOT snapshots");
    return nullptr;
  }

  if (!first_isolate_started_) {
    // This is a part of an initialization, so using engine_lifecycle_ mutex
    // here.
    MutexLocker ml(&engine_lifecycle_);
    if (!first_isolate_started_) {
      Dart_InitializeParams initialize_params = CreateInitializeParams();

      if (Dart_IsPrecompiledRuntime()) {
        initialize_params.vm_snapshot_data = snapshot.vm_snapshot_data;
        initialize_params.vm_snapshot_instructions =
            snapshot.vm_snapshot_instructions;
      }
      *error = Dart_Initialize(&initialize_params);
      if (*error != nullptr) {
        return nullptr;
      }
      first_isolate_started_ = true;
    }
  }

  // Now we can start an isolate.
  Dart_IsolateFlags isolate_flags;
  Dart_IsolateFlagsInitialize(&isolate_flags);

  Dart_Isolate isolate;
  if (Dart_IsPrecompiledRuntime()) {
    // Automatically sets the root library for the isolate.
    isolate = Dart_CreateIsolateGroup(
        snapshot.script_uri, strrchr(snapshot.script_uri, '/'),
        snapshot.vm_isolate_data, snapshot.vm_isolate_instructions,
        &isolate_flags, nullptr, nullptr, error);
  } else {
    isolate = Dart_CreateIsolateGroupFromKernel(
        snapshot.script_uri, snapshot.script_uri, snapshot.kernel_buffer,
        snapshot.kernel_buffer_size, &isolate_flags, nullptr, nullptr, error);
  }

  if (*error != nullptr) {
    return nullptr;
  }

  Dart_SetMessageNotifyCallback(Engine::MessageNotifyCallback);

  Dart_EnterScope();

  // In fact, this call initializes core libraries, (e.g. `print` doesn't work
  // without it).
  Dart_Handle core_libs_result = bin::DartUtils::SetupCoreLibraries(
      /*is_service_isolate=*/false, /*trace_loading=*/false,
      /*flag_profile_microtasks=*/false, bin::DartIoSettings{});
  if (Dart_IsError(core_libs_result)) {
    *error = Utils::StrDup(Dart_GetError(core_libs_result));
    Dart_ShutdownIsolate();
    return nullptr;
  }

  if (!Dart_IsPrecompiledRuntime()) {
    // In kernel mode, also call LoadScriptFromKernel to set the root library.
    // Technically, the library is already loaded after
    // Dart_CreateIsolateGroupFromKernel, the problem is we don't know its URI
    // (it is not related to snapshot->uri and depends on where the kernel
    // snapshot was built, e.g. file:///Users/user/samples/hello.dart)
    Dart_Handle library = Dart_LoadScriptFromKernel(
        snapshot.kernel_buffer, snapshot.kernel_buffer_size);

    if (Dart_IsError(library)) {
      *error = Utils::StrDup(Dart_GetError(library));
      Dart_ShutdownIsolate();
      return nullptr;
    }
  }

  Dart_Handle isolate_library = Dart_LookupLibrary(
      Dart_NewStringFromCString(bin::DartUtils::kIsolateLibURL));
  if (Dart_IsError(isolate_library)) {
    *error = Utils::StrDup(Dart_GetError(isolate_library));
    Dart_ShutdownIsolate();
    return nullptr;
  }

  std::shared_ptr<Engine::IsolateData> isolate_data = DataForIsolate(isolate);
  isolate_data->isolate_library = Dart_NewPersistentHandle(isolate_library);
  isolate_data->drain_microtasks_function_name = Dart_NewPersistentHandle(
      Dart_NewStringFromCString(kRunPendingImmediateCallback));
  isolate_data->scheduler.context = nullptr;
  isolate_data->scheduler.schedule_callback = nullptr;

  Dart_ExitScope();
  Dart_ExitIsolate();
  is_running_ = true;
  isolates_.emplace_back(isolate);
  return isolate;
}

void Engine::MessageNotifyCallback(Dart_Isolate isolate) {
  Engine::instance()->NotifyMessage(isolate);
}

void Engine::Shutdown() {
  MutexLocker shutdown_locker(&engine_lifecycle_);

  is_running_ = false;
  for (auto isolate : isolates_) {
    std::shared_ptr<Engine::IsolateData> isolate_data = DataForIsolate(isolate);
    LockIsolate(isolate);
    Dart_EnterIsolate(isolate);
    Dart_SetMessageNotifyCallback(nullptr);
    Dart_DeletePersistentHandle(isolate_data->isolate_library);
    Dart_DeletePersistentHandle(isolate_data->drain_microtasks_function_name);
    Dart_ShutdownIsolate();
    UnlockIsolate(isolate);
  }

  MutexLocker state_locker(&engine_state_);
  for (auto& snapshot : owned_snapshots_) {
    switch (snapshot.kind) {
      case DartEngine_SnapshotKind_Kernel:
        free(const_cast<uint8_t*>(snapshot.kernel_buffer));
        break;
      case DartEngine_SnapshotKind_AOT:
        // No need to free AOT buffers loaded from dynamic library.
        break;
      default:
        Syslog::PrintErr("Unsupported SnapshotKind: %d\n", snapshot.kind);
        break;
    }
    free(const_cast<char*>(snapshot.script_uri));
  }
}

void Engine::HandleMessage(Dart_Isolate isolate) {
  LockIsolate(isolate);
  Dart_EnterIsolate(isolate);
  Dart_EnterScope();

  Dart_Handle handle_result = Dart_HandleMessage();

  if (Dart_IsError(handle_result)) {
    if (handle_message_error_callback_ != nullptr) {
      handle_message_error_callback_(handle_result, isolate);
    } else {
      Syslog::PrintErr("Error handling isolate message: %s",
                       Dart_GetError(handle_result));
    }
  }

  Dart_ExitScope();
  Dart_ExitIsolate();
  UnlockIsolate(isolate);
}

Dart_Handle Engine::DrainMicrotasksQueue() {
  std::shared_ptr<Engine::IsolateData> isolate_data =
      DataForIsolate(Dart_CurrentIsolate());
  return Dart_Invoke(isolate_data->isolate_library,
                     isolate_data->drain_microtasks_function_name, 0, nullptr);
}

std::shared_ptr<Engine::IsolateData> Engine::DataForIsolate(
    Dart_Isolate isolate) {
  MutexLocker ml(&engine_state_);
  auto it = isolate_data_.find(isolate);
  if (it == isolate_data_.end()) {
    it = isolate_data_.emplace(isolate, std::make_shared<Engine::IsolateData>())
             .first;
  }
  return it->second;
}

void Engine::LockIsolate(Dart_Isolate isolate) {
  DataForIsolate(isolate)->mutex.Lock();
}

void Engine::UnlockIsolate(Dart_Isolate isolate) {
  DataForIsolate(isolate)->mutex.Unlock();
}

void Engine::NotifyMessage(Dart_Isolate isolate) {
  if (!engine_lifecycle_.TryLock() || !is_running_) {
    // Shutdown is in progress or complete.
    //
    // Used to prevent a potential deadlock during shutdown.
    //
    // If Engine::MessageNotifyCallback is waiting for Engine::HandleMessage
    // completion (which happens in samples/embedder/run_timer_async), and
    // another thread calls Engine::Shutdown, the deadlock may occur:
    //
    // 1. MessageNotifyCallback thread owns PortMap::mutex_ (through
    // PortMap::PostMessage) and wants to lock an isolate (via
    // Engine::LockIsolate).
    // 2. Shutdown thread owns an isolate lock and wants to lock PortMap::mutex_
    // (inside Dart_ShutdownIsolate call).
    //
    // This mutex is used to prevent it:
    // - Engine::Shutdown locks it.
    // - Engine::NotifyMessage tries to lock it, and treats lock failure as
    //   shutdown in progress.
    return;
  }

  DartEngine_MessageScheduler scheduler = DataForIsolate(isolate)->scheduler;

  if (scheduler.schedule_callback == nullptr) {
    scheduler = default_scheduler_;
  }
  if (scheduler.schedule_callback == nullptr) {
    engine_lifecycle_.Unlock();
    return;
  }
  scheduler.schedule_callback(isolate, scheduler.context);
  engine_lifecycle_.Unlock();
}

void Engine::SetHandleMessageErrorCallback(
    DartEngine_HandleMessageErrorCallback callback) {
  handle_message_error_callback_ = callback;
}

void Engine::SetDefaultMessageScheduler(DartEngine_MessageScheduler scheduler) {
  default_scheduler_ = scheduler;
}

void Engine::SetMessageScheduler(DartEngine_MessageScheduler scheduler,
                                 Dart_Isolate isolate) {
  DataForIsolate(isolate)->scheduler = scheduler;
}

}  // namespace engine
}  // namespace dart
