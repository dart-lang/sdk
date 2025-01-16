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
#include "bin/main_options.h"
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
    Dart_ShutdownIsolate();                                                    \
    return;                                                                    \
  }

namespace dart {
namespace bin {

DartDevIsolate::DartDevRunner DartDevIsolate::runner_ =
    DartDevIsolate::DartDevRunner();
bool DartDevIsolate::should_run_dart_dev_ = false;
bool DartDevIsolate::print_usage_error_ = false;
CommandLineOptions* DartDevIsolate::vm_options_ = nullptr;
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
  // If script_uri is a known DartDev command, we should not try to run it.
  //
  // Otherwise if script_uri is not a file path or of a known URI scheme, we
  // assume this is a mistyped DartDev command.
  //
  // This should be kept in sync with the commands in
  // `pkg/dartdev/lib/dartdev.dart`.
  return (
      (strcmp(script_uri, "analyze") == 0) ||
      (strcmp(script_uri, "compilation-server") == 0) ||
      (strcmp(script_uri, "build") == 0) ||
      (strcmp(script_uri, "compile") == 0) ||
      (strcmp(script_uri, "create") == 0) ||
      (strcmp(script_uri, "development-service") == 0) ||
      (strcmp(script_uri, "devtools") == 0) ||
      (strcmp(script_uri, "doc") == 0) || (strcmp(script_uri, "fix") == 0) ||
      (strcmp(script_uri, "format") == 0) ||
      (strcmp(script_uri, "info") == 0) || (strcmp(script_uri, "pub") == 0) ||
      (strcmp(script_uri, "run") == 0) || (strcmp(script_uri, "test") == 0) ||
      (strcmp(script_uri, "info") == 0) ||
      (strcmp(script_uri, "language-server") == 0) ||
      (strcmp(script_uri, "tooling-daemon") == 0) ||
      (!File::ExistsUri(nullptr, script_uri) &&
       (strncmp(script_uri, "http://", 7) != 0) &&
       (strncmp(script_uri, "https://", 8) != 0) &&
       (strncmp(script_uri, "file://", 7) != 0) &&
       (strncmp(script_uri, "package:", 8) != 0) &&
       (strncmp(script_uri, "google3://", 10) != 0)));
}

CStringUniquePtr DartDevIsolate::TryResolveArtifactPath(const char* filename) {
  auto try_resolve_path = [&](CStringUniquePtr dir_prefix) {
    // First assume we're in dart-sdk/bin.
    char* snapshot_path =
        Utils::SCreate("%ssnapshots/%s", dir_prefix.get(), filename);
    if (File::Exists(nullptr, snapshot_path)) {
      return CStringUniquePtr(snapshot_path);
    }
    free(snapshot_path);

    // If we're not in dart-sdk/bin, we might be in one of the $SDK/out/*
    // directories. Try to use a snapshot from a previously built SDK.
    snapshot_path = Utils::SCreate("%s%s", dir_prefix.get(), filename);
    if (File::Exists(nullptr, snapshot_path)) {
      return CStringUniquePtr(snapshot_path);
    }
    free(snapshot_path);
    return CStringUniquePtr(nullptr);
  };

  // Try to find the artifact using the resolved EXE path first. This can fail
  // if the Dart SDK file structure is faked using symlinks and the actual
  // artifacts are spread across directories on the file system (e.g., some
  // google3 execution environments).
  auto result =
      try_resolve_path(EXEUtils::GetDirectoryPrefixFromResolvedExeName());
  if (result == nullptr) {
    result =
        try_resolve_path(EXEUtils::GetDirectoryPrefixFromUnresolvedExeName());
  }

  return result;
}

CStringUniquePtr DartDevIsolate::TryResolveDartDevSnapshotPath() {
  return TryResolveArtifactPath("dartdev.dart.snapshot");
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

  // We've encountered an error during preliminary argument parsing so we'll
  // output the standard help message and exit with an error code.
  if (print_usage_error_) {
    dart_options_->Reset();
    dart_options_->AddArgument("--help");
  }

  MonitorLocker locker(monitor_);
  Thread::Start("DartDev Runner", RunCallback, reinterpret_cast<uword>(this));
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

      auto item3 = GetArrayItem(message, 3);

      ASSERT(item3->type == Dart_CObject_kBool);
      const bool mark_main_isolate_as_system_isolate = item3->value.as_bool;
      if (mark_main_isolate_as_system_isolate) {
        Options::set_mark_main_isolate_as_system_isolate(true);
      }

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

      ASSERT(GetArrayItem(message, 4)->type == Dart_CObject_kArray);
      Dart_CObject* args = GetArrayItem(message, 4);
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
    case DartDevIsolate::DartDev_Result_RunExec: {
      result_ = DartDevIsolate::DartDev_Result_RunExec;
      ASSERT(GetArrayItem(message, 1)->type == Dart_CObject_kString);
      auto item2 = GetArrayItem(message, 2);

      ASSERT(item2->type == Dart_CObject_kString ||
             item2->type == Dart_CObject_kNull);

      auto item3 = GetArrayItem(message, 3);

      ASSERT(item3->type == Dart_CObject_kBool);
      const bool mark_main_isolate_as_system_isolate = item3->value.as_bool;
      if (mark_main_isolate_as_system_isolate) {
        Options::set_mark_main_isolate_as_system_isolate(true);
      }

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

      intptr_t num_vm_options = 0;
      const char** vm_options = nullptr;
      ASSERT(GetArrayItem(message, 4)->type == Dart_CObject_kArray);
      Dart_CObject* args = GetArrayItem(message, 4);
      intptr_t argc = args->value.as_array.length;
      Dart_CObject** dart_args = args->value.as_array.values;

      if (vm_options_ != nullptr) {
        num_vm_options = vm_options_->count();
        vm_options = vm_options_->arguments();
      }
      auto deleter = [](char** args) {
        for (intptr_t i = 0; i < argc_; ++i) {
          free(args[i]);
        }
        delete[] args;
      };
      // Total count of arguments to be passed to the script being execed.
      argc_ = argc + num_vm_options + 1;

      // Array of arguments to be passed to the script being execed.
      argv_ = std::unique_ptr<char*[], void (*)(char**)>(new char*[argc_ + 1],
                                                         deleter);

      intptr_t idx = 0;
      // Copy in name of the script to run (dartaotruntime).
      argv_[0] = Utils::StrDup(GetArrayItem(message, 1)->value.as_string);
      idx += 1;
      // Copy in any vm options that need to be passed to the execed process.
      for (intptr_t i = 0; i < num_vm_options; ++i) {
        argv_[i + idx] = Utils::StrDup(vm_options[i]);
      }
      idx += num_vm_options;
      // Copy in the dart options that need to be passed to the command.
      for (intptr_t i = 0; i < argc; ++i) {
        argv_[i + idx] = Utils::StrDup(dart_args[i]->value.as_string);
      }
      // Null terminate the argv array.
      argv_[argc + idx] = nullptr;

      // Exec the script to be run and pass the arguments.
      char err_msg[256];
      err_msg[0] = '\0';
      int ret = Process::Exec(nullptr, *script_,
                              const_cast<const char**>(argv_.get()), argc_,
                              nullptr, err_msg, sizeof(err_msg));
      if (ret != 0) {
        ProcessError(err_msg, kErrorExitCode);
      }
      break;
    }
    case DartDevIsolate::DartDev_Result_Exit: {
      ASSERT(GetArrayItem(message, 1)->type == Dart_CObject_kInt32);
      int32_t dartdev_exit_code = GetArrayItem(message, 1)->value.as_int32;

      // If we're given a non-zero exit code, DartDev is signaling for us to
      // shutdown.
      int32_t exit_code =
          print_usage_error_ ? kErrorExitCode : dartdev_exit_code;
      Process::SetGlobalExitCode(exit_code);

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
  flags.use_field_guards = true;
  flags.use_osr = true;
  flags.is_system_isolate = true;
  flags.branch_coverage = false;
  flags.coverage = false;

  char* error = nullptr;
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
    Dart_ShutdownIsolate();
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
    CommandLineOptions* vm_options,
    CommandLineOptions* dart_options) {
  vm_options_ = vm_options;
  runner_.Run(create_isolate, packages_file, script, dart_options);
  return runner_.result();
}

}  // namespace bin
}  // namespace dart

#endif  // if !defined(DART_PRECOMPILED_RUNTIME)
