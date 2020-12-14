// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/dartdev_isolate.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

#include <functional>
#include <memory>

#include "bin/directory.h"
#include "bin/error_exit.h"
#include "bin/exe_utils.h"
#include "bin/file.h"
#include "bin/lockers.h"
#include "bin/platform.h"
#include "bin/process.h"
#include "include/dart_embedder_api.h"
#include "platform/utils.h"

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    ProcessError(Dart_GetError(result), kErrorExitCode);                       \
    if (send_port_id != ILLEGAL_PORT) {                                        \
      Dart_CloseNativePort(send_port_id);                                      \
    }                                                                          \
    Dart_ExitScope();                                                          \
    Dart_ExitIsolate();                                                        \
    return;                                                                    \
  }

namespace dart {
namespace bin {

DartDevIsolate::DartDevRunner DartDevIsolate::runner_ =
    DartDevIsolate::DartDevRunner();
bool DartDevIsolate::should_run_dart_dev_ = false;
Monitor* DartDevIsolate::DartDevRunner::monitor_ = new Monitor();
DartDevIsolate::DartDev_Result DartDevIsolate::DartDevRunner::result_ =
    DartDevIsolate::DartDev_Result_Unknown;
char** DartDevIsolate::DartDevRunner::script_ = nullptr;
char** DartDevIsolate::DartDevRunner::package_config_override_ = nullptr;
std::unique_ptr<char*[], void (*)(char*[])>
    DartDevIsolate::DartDevRunner::argv_ =
        std::unique_ptr<char*[], void (*)(char**)>(nullptr, [](char**) {});
intptr_t DartDevIsolate::DartDevRunner::argc_ = 0;

bool DartDevIsolate::ShouldParseCommand(const char* script_uri) {
  // If script_uri is not a file path or of a known URI scheme, we can assume
  // that this is a DartDev command.
  return (!File::ExistsUri(nullptr, script_uri) &&
          (strncmp(script_uri, "http://", 7) != 0) &&
          (strncmp(script_uri, "https://", 8) != 0) &&
          (strncmp(script_uri, "file://", 7) != 0) &&
          (strncmp(script_uri, "package:", 8) != 0) &&
          (strncmp(script_uri, "google3://", 10) != 0));
}

Utils::CStringUniquePtr DartDevIsolate::TryResolveDartDevSnapshotPath() {
  // |dir_prefix| includes the last path seperator.
  auto dir_prefix = EXEUtils::GetDirectoryPrefixFromExeName();

  // First assume we're in dart-sdk/bin.
  char* snapshot_path =
      Utils::SCreate("%ssnapshots/dartdev.dill", dir_prefix.get());
  if (File::Exists(nullptr, snapshot_path)) {
    return Utils::CreateCStringUniquePtr(snapshot_path);
  }
  free(snapshot_path);

  // If we're not in dart-sdk/bin, we might be in one of the $SDK/out/*
  // directories. Try to use a snapshot from a previously built SDK.
  snapshot_path = Utils::SCreate("%sdartdev.dill", dir_prefix.get());
  if (File::Exists(nullptr, snapshot_path)) {
    return Utils::CreateCStringUniquePtr(snapshot_path);
  }
  free(snapshot_path);
  return Utils::CreateCStringUniquePtr(nullptr);
}

void DartDevIsolate::DartDevRunner::Run(
    Dart_IsolateGroupCreateCallback create_isolate,
    char** packages_file,
    char** script,
    CommandLineOptions* dart_options) {
  create_isolate_ = create_isolate;
  dart_options_ = dart_options;
  package_config_override_ = packages_file;
  script_ = script;

  MonitorLocker locker(monitor_);
  int result = Thread::Start("DartDev Runner", RunCallback,
                             reinterpret_cast<uword>(this));
  if (result != 0) {
    FATAL1("Failed to start DartDev thread: %d", result);
  }
  monitor_->WaitMicros(Monitor::kNoTimeout);

  if (result_ == DartDevIsolate::DartDev_Result_Run) {
    // Clear the DartDev dart_options and replace them with the processed
    // options provided by DartDev.
    dart_options_->Reset();
    dart_options_->AddArguments(const_cast<const char**>(argv_.get()), argc_);
  }
}

static Dart_CObject* GetArrayItem(Dart_CObject* message, intptr_t index) {
  return message->value.as_array.values[index];
}

void DartDevIsolate::DartDevRunner::DartDevResultCallback(
    Dart_Port dest_port_id,
    Dart_CObject* message) {
  // These messages are produced in pkg/dartdev/lib/src/vm_interop_handler.dart.
  ASSERT(message->type == Dart_CObject_kArray);
  int32_t type = GetArrayItem(message, 0)->value.as_int32;
  switch (type) {
    case DartDevIsolate::DartDev_Result_Run: {
      result_ = DartDevIsolate::DartDev_Result_Run;
      ASSERT(GetArrayItem(message, 1)->type == Dart_CObject_kString);
      auto item2 = GetArrayItem(message, 2);

      ASSERT(item2->type == Dart_CObject_kString ||
             item2->type == Dart_CObject_kNull);

      if (*script_ != nullptr) {
        free(*script_);
      }
      if (*package_config_override_ != nullptr) {
        free(*package_config_override_);
        *package_config_override_ = nullptr;
      }
      *script_ = Utils::StrDup(GetArrayItem(message, 1)->value.as_string);

      if (item2->type == Dart_CObject_kString) {
        *package_config_override_ = Utils::StrDup(item2->value.as_string);
      }

      ASSERT(GetArrayItem(message, 3)->type == Dart_CObject_kArray);
      Dart_CObject* args = GetArrayItem(message, 3);
      argc_ = args->value.as_array.length;
      Dart_CObject** dart_args = args->value.as_array.values;

      auto deleter = [](char** args) {
        for (intptr_t i = 0; i < argc_; ++i) {
          free(args[i]);
        }
        delete[] args;
      };
      argv_ =
          std::unique_ptr<char*[], void (*)(char**)>(new char*[argc_], deleter);
      for (intptr_t i = 0; i < argc_; ++i) {
        argv_[i] = Utils::StrDup(dart_args[i]->value.as_string);
      }
      break;
    }
    case DartDevIsolate::DartDev_Result_Exit: {
      ASSERT(GetArrayItem(message, 1)->type == Dart_CObject_kInt32);
      int32_t dartdev_exit_code = GetArrayItem(message, 1)->value.as_int32;

      // If we're given a non-zero exit code, DartDev is signaling for us to
      // shutdown.
      Process::SetGlobalExitCode(dartdev_exit_code);

      // If DartDev hasn't signaled for us to do anything else, we can assume
      // there's nothing else for the VM to run and that we can exit.
      if (result_ == DartDevIsolate::DartDev_Result_Unknown) {
        result_ = DartDevIsolate::DartDev_Result_Exit;
      }

      // DartDev is done processing the command. Unblock the main thread and
      // continue the launch procedure.
      DartDevRunner::monitor_->Notify();
      break;
    }
    default:
      UNREACHABLE();
  }
}

void DartDevIsolate::DartDevRunner::RunCallback(uword args) {
  MonitorLocker locker_(DartDevRunner::monitor_);
  DartDevRunner* runner = reinterpret_cast<DartDevRunner*>(args);

  // Hardcode flags to match those used to generate the DartDev snapshot.
  Dart_IsolateFlags flags;
  Dart_IsolateFlagsInitialize(&flags);
  flags.enable_asserts = false;
  flags.null_safety = false;
  flags.use_field_guards = true;
  flags.use_osr = true;
  flags.is_system_isolate = true;

  char* error;
  Dart_Isolate dartdev_isolate = runner->create_isolate_(
      DART_DEV_ISOLATE_NAME, DART_DEV_ISOLATE_NAME, nullptr,
      runner->packages_file_, &flags, /* callback_data */ nullptr,
      const_cast<char**>(&error));

  if (dartdev_isolate == nullptr) {
    ProcessError(error, kErrorExitCode);
    free(error);
    return;
  }

  Dart_EnterIsolate(dartdev_isolate);
  Dart_EnterScope();

  // Retrieve the DartDev entrypoint.
  Dart_Port send_port_id = ILLEGAL_PORT;
  Dart_Handle root_lib = Dart_RootLibrary();
  Dart_Handle main_closure =
      Dart_GetField(root_lib, Dart_NewStringFromCString("main"));
  CHECK_RESULT(main_closure);

  if (!Dart_IsClosure(main_closure)) {
    ProcessError("Unable to find 'main' in root library 'dartdev'",
                 kErrorExitCode);
    Dart_ExitScope();
    Dart_ExitIsolate();
    return;
  }

  // Create a SendPort that DartDev can use to communicate its results over.
  send_port_id =
      Dart_NewNativePort(DART_DEV_ISOLATE_NAME, DartDevResultCallback, false);
  ASSERT(send_port_id != ILLEGAL_PORT);
  Dart_Handle send_port = Dart_NewSendPort(send_port_id);
  CHECK_RESULT(send_port);

  const intptr_t kNumIsolateArgs = 4;
  Dart_Handle isolate_args[kNumIsolateArgs];
  isolate_args[0] = main_closure;  // entryPoint
  isolate_args[1] = runner->dart_options_->CreateRuntimeOptions();  // args
  isolate_args[2] = send_port;                                      // message
  isolate_args[3] = Dart_True();  // isSpawnUri

  Dart_Handle isolate_lib =
      Dart_LookupLibrary(Dart_NewStringFromCString("dart:isolate"));
  Dart_Handle result =
      Dart_Invoke(isolate_lib, Dart_NewStringFromCString("_startIsolate"),
                  kNumIsolateArgs, isolate_args);
  CHECK_RESULT(result);
  CHECK_RESULT(Dart_RunLoop());

  Dart_CloseNativePort(send_port_id);

  Dart_ExitScope();
  Dart_ShutdownIsolate();
}

void DartDevIsolate::DartDevRunner::ProcessError(const char* msg,
                                                 int32_t exit_code) {
  Syslog::PrintErr("%s.\n", msg);
  Process::SetGlobalExitCode(exit_code);
  result_ = DartDevIsolate::DartDev_Result_Exit;
  DartDevRunner::monitor_->Notify();
}

DartDevIsolate::DartDev_Result DartDevIsolate::RunDartDev(
    Dart_IsolateGroupCreateCallback create_isolate,
    char** packages_file,
    char** script,
    CommandLineOptions* dart_options) {
  runner_.Run(create_isolate, packages_file, script, dart_options);
  return runner_.result();
}

#endif  // if !defined(DART_PRECOMPILED_RUNTIME)

}  // namespace bin
}  // namespace dart
