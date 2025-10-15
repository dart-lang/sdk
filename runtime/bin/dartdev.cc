// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <memory>
#include <utility>

#include "bin/builtin.h"
#include "bin/console.h"
#include "bin/crashpad.h"
#include "bin/dartdev_options.h"
#include "bin/dartutils.h"
#include "bin/error_exit.h"
#include "bin/eventhandler.h"
#include "bin/exe_utils.h"
#include "bin/file.h"
#include "bin/gzip.h"
#include "bin/isolate_data.h"
#include "bin/loader.h"
#include "bin/lockers.h"
#include "bin/platform.h"
#include "bin/process.h"
#include "bin/snapshot_utils.h"
#include "bin/thread.h"
#include "bin/utils.h"
#if defined(DART_HOST_OS_WINDOWS)
#include "bin/utils_win.h"
#endif
#include "bin/vmservice_impl.h"
#include "include/bin/dart_io_api.h"
#include "include/dart_api.h"
#include "include/dart_embedder_api.h"
#include "include/dart_native_api.h"
#include "include/dart_tools_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/growable_array.h"
#include "platform/hashmap.h"
#include "platform/syslog.h"
#include "platform/text_buffer.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

#if defined(DART_PRECOMPILED_RUNTIME)
/**
 * Global state used to control and store generation of application snapshots.
 */
static const uint8_t* ignore_vm_snapshot_data = nullptr;
static const uint8_t* ignore_vm_snapshot_instructions = nullptr;
static const uint8_t* app_isolate_snapshot_data = nullptr;
static const uint8_t* app_isolate_snapshot_instructions = nullptr;

#define SAVE_ERROR_AND_RETURN(result)                                          \
  if (Dart_IsError(result)) {                                                  \
    *error = Utils::StrDup(Dart_GetError(result));                             \
    return false;                                                              \
  }

#define SAVE_ERROR_AND_EXIT(result)                                            \
  *error = Utils::StrDup(Dart_GetError(result));                               \
  if (Dart_IsCompilationError(result)) {                                       \
    *exit_code = kCompilationErrorExitCode;                                    \
  } else if (Dart_IsApiError(result)) {                                        \
    *exit_code = kApiErrorExitCode;                                            \
  } else {                                                                     \
    *exit_code = kErrorExitCode;                                               \
  }                                                                            \
  Dart_ExitScope();                                                            \
  Dart_ShutdownIsolate();                                                      \
  return nullptr;

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    SAVE_ERROR_AND_EXIT(result);                                               \
  }

#define CHECK_RESULT_CLEANUP(result, cleanup)                                  \
  if (Dart_IsError(result)) {                                                  \
    delete (cleanup);                                                          \
    SAVE_ERROR_AND_EXIT(result);                                               \
  }

#define DART_DEV_ISOLATE_NAME "dartdev"

// Helper class to ensure we enter a new Dart Scope and exit it.
class DartScope {
 public:
  DartScope() { Dart_EnterScope(); }
  ~DartScope() { Dart_ExitScope(); }
};

static Dart_Handle SetupCoreLibraries(Dart_Isolate isolate,
                                      IsolateData* isolate_data,
                                      bool is_isolate_group_start,
                                      const char** resolved_packages_config) {
  auto isolate_group_data = isolate_data->isolate_group_data();
  const auto packages_file = isolate_data->packages_file();
  const auto script_uri = isolate_group_data->script_url;

  Dart_Handle result;

  // Prepare builtin and other core libraries for use to resolve URIs.
  // Set up various closures, e.g: printing, timers etc.
  // Set up package configuration for URI resolution.
  result = DartUtils::SetupCoreLibraries(
      /*is_service_isolate=*/false, /*trace_loading=*/false,
      /*profile_microtasks=*/false,
      DartIoSettings{
          .namespace_root = Options::namespc() != nullptr
                                ? DartUtils::NewString(Options::namespc())
                                : nullptr,
          .script_uri = script_uri,
          .disable_exit = Options::exit_disabled()});
  if (Dart_IsError(result)) return result;

  // Setup packages config if specified.
  result = DartUtils::SetupPackageConfig(packages_file);
  if (Dart_IsError(result)) return result;
  if (!Dart_IsNull(result) && resolved_packages_config != nullptr) {
    result = Dart_StringToCString(result, resolved_packages_config);
    if (Dart_IsError(result)) return result;
    ASSERT(*resolved_packages_config != nullptr);
  }

  result = Dart_SetEnvironmentCallback(DartUtils::EnvironmentCallback);
  if (Dart_IsError(result)) return result;

  // Setup the native resolver as the snapshot does not carry it.
  VmService::SetNativeResolver();

  return Dart_Null();
}

static bool OnIsolateInitialize(void** child_callback_data, char** error) {
  Dart_Isolate isolate = Dart_CurrentIsolate();
  ASSERT(isolate != nullptr);

  auto isolate_group_data =
      reinterpret_cast<IsolateGroupData*>(Dart_CurrentIsolateGroupData());

  auto isolate_data = new IsolateData(isolate_group_data);
  *child_callback_data = isolate_data;

  DartScope scope;  // Enter a new scope.
  const auto script_uri = isolate_group_data->script_url;
  const bool isolate_run_app_snapshot =
      isolate_group_data->RunFromAppSnapshot();
  Dart_Handle result = SetupCoreLibraries(isolate, isolate_data,
                                          /*group_start=*/false,
                                          /*resolved_packages_config=*/nullptr);
  SAVE_ERROR_AND_RETURN(result);
  if (isolate_run_app_snapshot) {
    result = Loader::InitForSnapshot(script_uri, isolate_data);
    SAVE_ERROR_AND_RETURN(result);
  } else {
    result = DartUtils::ResolveScript(Dart_NewStringFromCString(script_uri));
    SAVE_ERROR_AND_RETURN(result);

    if (isolate_group_data->kernel_buffer() != nullptr) {
      // Various core-library parts will send requests to the Loader to resolve
      // relative URIs and perform other related tasks. We need Loader to be
      // initialized for this to work because loading from Kernel binary
      // bypasses normal source code loading paths that initialize it.
      const char* resolved_script_uri = nullptr;
      result = Dart_StringToCString(result, &resolved_script_uri);
      SAVE_ERROR_AND_RETURN(result);
      result = Loader::InitForSnapshot(resolved_script_uri, isolate_data);
      SAVE_ERROR_AND_RETURN(result);
    }
  }

  return true;
}

static Dart_Isolate IsolateSetupHelper(Dart_Isolate isolate,
                                       bool is_dartdev_isolate,
                                       const char* script_uri,
                                       const char* packages_config,
                                       bool isolate_run_app_snapshot,
                                       Dart_IsolateFlags* flags,
                                       char** error,
                                       int* exit_code) {
  Dart_EnterScope();

  // Set up the library tag handler for the isolate group shared by all
  // isolates in the group.
  Dart_Handle result = Dart_SetLibraryTagHandler(Loader::LibraryTagHandler);
  CHECK_RESULT(result);
  result = Dart_SetDeferredLoadHandler(Loader::DeferredLoadHandler);
  CHECK_RESULT(result);

  auto isolate_data = reinterpret_cast<IsolateData*>(Dart_IsolateData(isolate));

  const char* resolved_packages_config = nullptr;
  result = SetupCoreLibraries(isolate, isolate_data,
                              /*is_isolate_group_start=*/true,
                              &resolved_packages_config);
  CHECK_RESULT(result);

  if (isolate_run_app_snapshot) {
    Dart_Handle result = Loader::InitForSnapshot(script_uri, isolate_data);
    CHECK_RESULT(result);
  } else {
    UNREACHABLE();
  }

  // Make the isolate runnable so that it is ready to handle messages.
  Dart_ExitScope();
  Dart_ExitIsolate();
  *error = Dart_IsolateMakeRunnable(isolate);
  if (*error != nullptr) {
    Dart_EnterIsolate(isolate);
    Dart_ShutdownIsolate();
    return nullptr;
  }

  return isolate;
}

// Returns newly created Isolate on success, nullptr on failure.
static Dart_Isolate CreateIsolateGroupAndSetupHelper(
    bool is_dartdev_isolate,
    const char* script_uri,
    const char* name,
    const char* packages_config,
    Dart_IsolateFlags* flags,
    void* callback_data,
    char** error,
    int* exit_code) {
  int64_t start = Dart_TimelineGetMicros();
  ASSERT(script_uri != nullptr);
  uint8_t* kernel_buffer = nullptr;
  intptr_t kernel_buffer_size = 0;
  AppSnapshot* app_snapshot = nullptr;

  const uint8_t* isolate_snapshot_data = nullptr;
  const uint8_t* isolate_snapshot_instructions = nullptr;
  if (is_dartdev_isolate) {
    isolate_snapshot_data = app_isolate_snapshot_data;
    isolate_snapshot_instructions = app_isolate_snapshot_instructions;
  } else {
    // AOT: All isolates need to be run from AOT compiled snapshots.
    app_snapshot = Snapshot::TryReadAppSnapshot(
        script_uri, /*force_load_from_memory*/ false, /*decode_uri*/ true);
    if (app_snapshot == nullptr || !app_snapshot->IsAOT()) {
      *error = Utils::SCreate(
          "The uri(%s) provided to `Isolate.spawnUri()` does not "
          "contain a valid AOT snapshot.",
          script_uri);
      return nullptr;
    }

    app_snapshot->SetBuffers(
        &ignore_vm_snapshot_data, &ignore_vm_snapshot_instructions,
        &isolate_snapshot_data, &isolate_snapshot_instructions);
  }

  bool isolate_run_app_snapshot = true;

  auto isolate_group_data = new IsolateGroupData(
      script_uri, /*asset_resolution_base=*/nullptr, packages_config,
      app_snapshot, isolate_run_app_snapshot);
  if (kernel_buffer != nullptr) {
    isolate_group_data->SetKernelBufferNewlyOwned(kernel_buffer,
                                                  kernel_buffer_size);
  }

  Dart_Isolate isolate = nullptr;

  IsolateData* isolate_data = nullptr;
  isolate_data = new IsolateData(isolate_group_data);
  isolate = Dart_CreateIsolateGroup(script_uri, name, isolate_snapshot_data,
                                    isolate_snapshot_instructions, flags,
                                    isolate_group_data, isolate_data, error);
  Dart_Isolate created_isolate = nullptr;
  if (isolate == nullptr) {
    delete isolate_data;
    delete isolate_group_data;
  } else {
    created_isolate = IsolateSetupHelper(
        isolate, is_dartdev_isolate, script_uri, packages_config,
        isolate_run_app_snapshot, flags, error, exit_code);
  }
  int64_t end = Dart_TimelineGetMicros();
  Dart_RecordTimelineEvent("CreateIsolateGroupAndSetupHelper", start, end,
                           /*flow_id_count=*/0, nullptr,
                           Dart_Timeline_Event_Duration,
                           /*argument_count=*/0, nullptr, nullptr);
  return created_isolate;
}

#undef CHECK_RESULT

static Dart_Isolate CreateIsolateGroupAndSetup(const char* script_uri,
                                               const char* main,
                                               const char* package_root,
                                               const char* package_config,
                                               Dart_IsolateFlags* flags,
                                               void* callback_data,
                                               char** error) {
  // The VM should never call the isolate helper with a nullptr flags.
  ASSERT(flags != nullptr);
  ASSERT(flags->version == DART_FLAGS_CURRENT_VERSION);
  ASSERT(package_root == nullptr);

  if (error != nullptr) {
    *error = nullptr;
  }

#if defined(DART_HOST_OS_LINUX)
  // This would also be true in Linux, except that Google3 overrides the default
  // ELF interpreter to one that apparently doesn't create proper mappings.
  flags->snapshot_is_dontneed_safe = false;
#else
  flags->snapshot_is_dontneed_safe = true;
#endif

  int exit_code = 0;

  if (strcmp(script_uri, DART_VM_SERVICE_ISOLATE_NAME) == 0) {
    // We do not start the service isolate in the Dart CLI mode of execution.
    // If profiling or debugging of the individual tools is desired it is
    // possible to do that using the 'dartaotruntime' or 'dartvm' executables.
    return nullptr;
  }

  bool is_dartdev_isolate = false;
  return CreateIsolateGroupAndSetupHelper(is_dartdev_isolate, script_uri, main,
                                          package_config, flags, callback_data,
                                          error, &exit_code);
}

static void OnIsolateShutdown(void* isolate_group_data, void* isolate_data) {
  Dart_EnterScope();
  Dart_Handle sticky_error = Dart_GetStickyError();
  if (!Dart_IsNull(sticky_error) && !Dart_IsFatalError(sticky_error)) {
    Syslog::PrintErr("%s\n", Dart_GetError(sticky_error));
  }
  Dart_ExitScope();
}

static void DeleteIsolateData(void* isolate_group_data, void* callback_data) {
  auto isolate_data = reinterpret_cast<IsolateData*>(callback_data);
  delete isolate_data;
}

static void DeleteIsolateGroupData(void* callback_data) {
  auto isolate_group_data = reinterpret_cast<IsolateGroupData*>(callback_data);
  delete isolate_group_data;
}

static constexpr const char* kStdoutStreamId = "Stdout";
static constexpr const char* kStderrStreamId = "Stderr";

static bool ServiceStreamListenCallback(const char* stream_id) {
  if (strcmp(stream_id, kStdoutStreamId) == 0) {
    SetCaptureStdout(true);
    return true;
  } else if (strcmp(stream_id, kStderrStreamId) == 0) {
    SetCaptureStderr(true);
    return true;
  }
  return false;
}

static void ServiceStreamCancelCallback(const char* stream_id) {
  if (strcmp(stream_id, kStdoutStreamId) == 0) {
    SetCaptureStdout(false);
  } else if (strcmp(stream_id, kStderrStreamId) == 0) {
    SetCaptureStderr(false);
  } else {
    UNREACHABLE();
  }
}

static bool FileModifiedCallback(const char* url, int64_t since) {
  auto path = File::UriToPath(url);
  if (path == nullptr) {
    // If it isn't a file on local disk, we don't know if it has been
    // modified.
    return true;
  }
  int64_t data[File::kStatSize];
  File::Stat(nullptr, path.get(), data);
  if (data[File::kType] == File::kDoesNotExist) {
    return true;
  }
  return data[File::kModifiedTime] > since;
}

static void EmbedderInformationCallback(Dart_EmbedderInformation* info) {
  info->version = DART_EMBEDDER_INFORMATION_CURRENT_VERSION;
  info->name = "Dart VM";
  Process::GetRSSInformation(&(info->max_rss), &(info->current_rss));
}

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    const int exit_code = Dart_IsCompilationError(result)                      \
                              ? kCompilationErrorExitCode                      \
                              : kErrorExitCode;                                \
    ErrorExit(exit_code, "%s\n", Dart_GetError(result));                       \
  }

static bool CheckForInvalidPath(const char* path) {
  // TODO(zichangguo): "\\?\" is a prefix for paths on Windows.
  // Arguments passed are parsed as an URI. "\\?\" causes problems as a part
  // of URIs. This is a temporary workaround to prevent VM from crashing.
  // Issue: https://github.com/dart-lang/sdk/issues/42779
  if (strncmp(path, R"(\\?\)", 4) == 0) {
    Syslog::PrintErr(R"(\\?\ prefix is not supported)");
    return false;
  }
  return true;
}

class DartDev {
 public:
  // Return codes from dartdev.
  // Note: keep in sync with pkg/dartdev/lib/vm_interop_handler.dart
  typedef enum {
    DartDev_Result_Unknown = -1,
    DartDev_Result_Run = 1,
    DartDev_Result_RunExec = 2,
    DartDev_Result_Exit = 3,
  } DartDev_Result;

  static CStringUniquePtr ResolvedDartVmPath() {
#if defined(DART_HOST_OS_WINDOWS)
    const char* filename = "dartvm.exe";
#else
    const char* filename = "dartvm";
#endif  // defined(DART_HOST_OS_WINDOWS)
    auto try_resolve_path = [&](CStringUniquePtr dir_prefix) {
      // |dir_prefix| includes the last path separator.
      // Assume 'dartvm' and 'dart' executables are in the same directory.
      char* dartvm_path = Utils::SCreate("%s%s", dir_prefix.get(), filename);
      if (File::Exists(nullptr, dartvm_path)) {
        return CStringUniquePtr(dartvm_path);
      }
      free(dartvm_path);
      return CStringUniquePtr(nullptr);
    };

    auto result =
        try_resolve_path(EXEUtils::GetDirectoryPrefixFromResolvedExeName());
    if (result == nullptr) {
      result =
          try_resolve_path(EXEUtils::GetDirectoryPrefixFromUnresolvedExeName());
    }
    return result;
  }

  static CStringUniquePtr ResolvedSnapshotPath() {
    const char* filename = "dartdev_aot.dart.snapshot";

    auto try_resolve_path = [&](CStringUniquePtr dir_prefix) {
      // |dir_prefix| includes the last path separator.
      // First assume we're in dart-sdk/bin.
      char* snapshot_path =
          Utils::SCreate("%ssnapshots/%s", dir_prefix.get(), filename);
      if (File::Exists(nullptr, snapshot_path)) {
        return CStringUniquePtr(snapshot_path);
      }
      free(snapshot_path);

      // If we're not in dart-sdk/bin, we might be in one of the $SDK/out*/
      // directories, Try to use a snapshot from that directory.
      snapshot_path = Utils::SCreate("%s%s", dir_prefix.get(), filename);
      if (File::Exists(nullptr, snapshot_path)) {
        return CStringUniquePtr(snapshot_path);
      }
      free(snapshot_path);
      return CStringUniquePtr(nullptr);
    };

    auto result =
        try_resolve_path(EXEUtils::GetDirectoryPrefixFromResolvedExeName());
    if (result == nullptr) {
      result =
          try_resolve_path(EXEUtils::GetDirectoryPrefixFromUnresolvedExeName());
    }
    return result;
  }

  // Invoke the Dart VM directly bypassing dartdev.
  static void InvokeDartVM(int argc, char** argv, bool argv_converted) {
    auto dartvm_path = DartDev::ResolvedDartVmPath();
    if (dartvm_path.get() == nullptr ||
        !CheckForInvalidPath(dartvm_path.get())) {
      // Free environment if any.
      Syslog::PrintErr("Unable to locate the Dart VM executable");
      Options::Cleanup();
      Platform::Exit(kErrorExitCode);
    }
    int idx = 0;
    char err_msg[256];
    err_msg[0] = '\0';
    intptr_t num_args = argc + 3;
    char** exec_argv = new char*[num_args];
#if defined(DART_HOST_OS_WINDOWS)
    char* exec_name = StringUtilsWin::ArgumentEscape(dartvm_path.get());
#else
    char* exec_name = Utils::StrDup(dartvm_path.get());
#endif
    exec_argv[idx] = exec_name;
    const size_t kPathBufSize = PATH_MAX + 1;
    char dart_path[kPathBufSize];
    Platform::ResolveExecutablePathInto(dart_path, kPathBufSize);
    idx += 1;
#if defined(DART_HOST_OS_WINDOWS)
    char* dart_name =
        Utils::SCreate("--resolved_executable_name=%s", dart_path);
    exec_argv[idx] = StringUtilsWin::ArgumentEscape(dart_name);
    free(dart_name);
    idx += 1;
    dart_name =
        Utils::SCreate("--executable_name=%s", Platform::GetExecutableName());
    exec_argv[idx] = StringUtilsWin::ArgumentEscape(dart_name);
    free(dart_name);
#else
    exec_argv[idx] = Utils::SCreate("--resolved_executable_name=%s", dart_path);
    idx += 1;
    exec_argv[idx] =
        Utils::SCreate("--executable_name=%s", Platform::GetExecutableName());
#endif
    for (intptr_t i = 1; i < argc; ++i) {
#if defined(DART_HOST_OS_WINDOWS)
      exec_argv[i + idx] = StringUtilsWin::ArgumentEscape(argv[i]);
#else
      exec_argv[i + idx] = Utils::StrDup(argv[i]);
#endif  // defined(DART_HOST_OS_WINDOWS)
    }
    // Null terminate the exec_argv array.
    exec_argv[num_args - 1] = nullptr;

    // Exec the script to be run and pass the arguments.
    int ret =
        Process::Exec(nullptr, exec_name, const_cast<const char**>(exec_argv),
                      (num_args - 1), nullptr, err_msg, sizeof(err_msg));
    // Exec process done.
    if (ret != 0) {
      Syslog::PrintErr("%s\n", err_msg);
    }
    // Free copied argument strings if converted.
    if (argv_converted) {
      for (int i = 0; i < argc; i++) {
        free(argv[i]);
      }
    }
    for (int i = 0; i < argc; i++) {
      free(exec_argv[i]);
    }
    delete[] exec_argv;

    // Free environment if any.
    Options::Cleanup();
    Platform::Exit(ret);
  }

  // Process the DartDev_Result_Run result message produced by
  // VmInteropHandler in pkg/dartdev/lib/src/vm_interop_handler.dart
  static void RunResultCallback(Dart_CObject* message) {
    result_ = DartDev_Result_Run;
    ASSERT(GetArrayItem(message, 1)->type == Dart_CObject_kString);
    auto item2 = GetArrayItem(message, 2);

    ASSERT(item2->type == Dart_CObject_kString ||
           item2->type == Dart_CObject_kNull);

    auto item3 = GetArrayItem(message, 3);

    // ignoring mark_main_isolate_as_system_isolate
    ASSERT(item3->type == Dart_CObject_kBool);

    script_name_ = Utils::StrDup(GetArrayItem(message, 1)->value.as_string);

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
  }

  // Process the DartDev_Result_RunExec result message produced by
  // VmInteropHandler in pkg/dartdev/lib/src/vm_interop_handler.dart
  static void RunExecResultCallback(Dart_CObject* message) {
    result_ = DartDev_Result_RunExec;
    auto dartvm_path = DartDev::ResolvedDartVmPath();
    if (dartvm_path.get() == nullptr ||
        !CheckForInvalidPath(dartvm_path.get())) {
      Syslog::PrintErr("Unable to locate the Dart VM executable");
      Platform::Exit(kErrorExitCode);
    }
    ASSERT(GetArrayItem(message, 1)->type == Dart_CObject_kString);
    auto item2 = GetArrayItem(message, 2);

    ASSERT(item2->type == Dart_CObject_kString ||
           item2->type == Dart_CObject_kNull);

    package_config_override_ = nullptr;

    if (item2->type == Dart_CObject_kString) {
      package_config_override_ = Utils::StrDup(item2->value.as_string);
    }

    intptr_t num_vm_options = dart_vm_options_->count();
    const char** vm_options = dart_vm_options_->arguments();
    ASSERT(GetArrayItem(message, 4)->type == Dart_CObject_kArray);
    Dart_CObject* args = GetArrayItem(message, 4);
    intptr_t argc = args->value.as_array.length;
    Dart_CObject** dart_args = args->value.as_array.values;
    auto item3 = GetArrayItem(message, 3);
    ASSERT(item3->type == Dart_CObject_kBool);
    const bool mark_main_isolate_as_system_isolate = item3->value.as_bool;
    auto deleter = [](char** args) {
      for (intptr_t i = 0; i < argc_; ++i) {
        free(args[i]);
      }
      delete[] args;
    };
    // Total count of arguments to be passed to the script being execed.
    if (mark_main_isolate_as_system_isolate) {
      argc_ = argc + num_vm_options + 5;
    } else {
      argc_ = argc + num_vm_options + 4;
    }

    // Array of arguments to be passed to the script being execed.
    argv_ = std::unique_ptr<char*[], void (*)(char**)>(new char*[argc_ + 1],
                                                       deleter);

    intptr_t idx = 0;
    // Copy in name of the executable to run (should be the dart vm).
#if defined(DART_HOST_OS_WINDOWS)
    script_name_ = StringUtilsWin::ArgumentEscape(dartvm_path.get());
#else
    script_name_ = Utils::StrDup(dartvm_path.get());
#endif
    argv_[idx++] = script_name_;
    // Copy in VM options if any.
    // Copy in any vm options that need to be passed to the execed process.
    for (intptr_t i = 0; i < num_vm_options; ++i) {
#if defined(DART_HOST_OS_WINDOWS)
      argv_[i + idx] = StringUtilsWin::ArgumentEscape(vm_options[i]);
#else
      argv_[i + idx] = Utils::StrDup(vm_options[i]);
#endif
    }
    idx += num_vm_options;
    {
      const size_t kPathBufSize = PATH_MAX + 1;
      char dart_path[kPathBufSize];
      Platform::ResolveExecutablePathInto(dart_path, kPathBufSize);
#if defined(DART_HOST_OS_WINDOWS)
      char* dart_name =
          Utils::SCreate("--resolved_executable_name=%s", dart_path);
      argv_[idx++] = StringUtilsWin::ArgumentEscape(dart_name);
      free(dart_name);
      dart_name =
          Utils::SCreate("--executable_name=%s", Platform::GetExecutableName());
      argv_[idx++] = StringUtilsWin::ArgumentEscape(dart_name);
      free(dart_name);
#else
      argv_[idx++] = Utils::SCreate("--resolved_executable_name=%s", dart_path);
      argv_[idx++] =
          Utils::SCreate("--executable_name=%s", Platform::GetExecutableName());
#endif
    }
    if (mark_main_isolate_as_system_isolate) {
      argv_[idx++] = Utils::StrDup("--mark_main_isolate_as_system_isolate");
    }
    // Copy in name of the script to run.
    argv_[idx++] = Utils::StrDup(GetArrayItem(message, 1)->value.as_string);
    // Copy in the dart options that need to be passed to the script.
    for (intptr_t i = 0; i < argc; ++i) {
      argv_[i + idx] = Utils::StrDup(dart_args[i]->value.as_string);
    }
    // Null terminate the argv array.
    argv_[argc + idx] = nullptr;
  }

  // Process the DartDev_Result_Exit result message produced by
  // VmInteropHandler in pkg/dartdev/lib/src/vm_interop_handler.dart
  static void ExitResultCallback(Dart_CObject* message) {
    ASSERT(GetArrayItem(message, 1)->type == Dart_CObject_kInt32);
    int32_t dartdev_exit_code = GetArrayItem(message, 1)->value.as_int32;

    // If we're given a non-zero exit code, DartDev is signaling for us to
    // shutdown.
    Process::SetGlobalExitCode(dartdev_exit_code);

    // If DartDev hasn't signaled for us to do anything else, we can assume
    // there's nothing else for the VM to run and that we can exit.
    if (result_ == DartDev_Result_Unknown || dartdev_exit_code != 0) {
      result_ = DartDev_Result_Exit;
    }
    // Notify the dartdev runner that it can proceed with processing
    // the result from execution of dartdev.
    {
      MonitorLocker locker(monitor_);
      exited_ = true;
      locker.Notify();
    }
  }

  // Callback that processes the result from execution of dartdev
  //
  static void ResultCallback(Dart_Port dest_port_id, Dart_CObject* message) {
    // These messages are produced in
    // pkg/dartdev/lib/src/vm_interop_handler.dart.
    ASSERT(message->type == Dart_CObject_kArray);
    int32_t type = GetArrayItem(message, 0)->value.as_int32;
    switch (type) {
      case DartDev_Result_Run: {
        RunResultCallback(message);
        break;
      }
      case DartDev_Result_RunExec: {
        RunExecResultCallback(message);
        break;
      }
      case DartDev_Result_Exit: {
        ExitResultCallback(message);
        break;
      }
      default:
        UNREACHABLE();
    }
  }

  static void RunDartDev(const char* script_name,
                         CommandLineOptions* dart_vm_options,
                         CommandLineOptions* dart_options) {
    ASSERT(script_name != nullptr);
    const char* base_name = strrchr(script_name, '/');
    if (base_name == nullptr) {
      base_name = script_name;
    } else {
      base_name++;  // Skip '/'.
    }
    const intptr_t kMaxNameLength = 64;
    char name[kMaxNameLength];
    Utils::SNPrint(name, kMaxNameLength, "dart:%s", base_name);
    Platform::SetProcessName(name);

    dart_vm_options_ = dart_vm_options;

    // Call CreateIsolateGroupAndSetup which creates an isolate and loads up
    // the specified application script.
    Dart_IsolateFlags flags;
    Dart_IsolateFlagsInitialize(&flags);
#if defined(DART_HOST_OS_LINUX)
    // This would also be true in Linux, except that Google3 overrides the
    // default ELF interpreter to one that apparently doesn't create proper
    // mappings.
    flags.snapshot_is_dontneed_safe = false;
#else
    flags.snapshot_is_dontneed_safe = true;
#endif
    flags.is_system_isolate = true;
    SpawnIsolate(script_name, "_startIsolate",
                 /*is_dartdev_isolate*/ true,
                 /*package_config_override*/ nullptr, &flags, dart_options);

    // Wait for the callbacks on the native port to be done before we
    // proceed.
    {
      MonitorLocker locker(monitor_);
      while (!exited_) {
        locker.Wait();
      }
    }

    /* Process the result returned by the dartdev isolate. */
    switch (result_) {
      case DartDev_Result_Run: {
        flags.is_system_isolate = false;
        SpawnIsolate(script_name_, "_startMainIsolate",
                     /*is_dartdev_isolate*/ false, package_config_override_,
                     &flags, dart_options);
        free(script_name_);
        free(package_config_override_);
        break;
      }
      case DartDev_Result_RunExec: {
        RunExec(script_name_);
        break;
      }
      case DartDev_Result_Exit: {
        // Nothing to do here, the process will terminate with the exit code
        // set earlier.
        break;
      }
      default:
        UNREACHABLE();
    }
  }

 private:
  static void SpawnIsolate(const char* script_name,
                           const char* entry_point,
                           bool is_dartdev_isolate,
                           const char* package_config_override,
                           Dart_IsolateFlags* flags,
                           CommandLineOptions* dart_options) {
    // Start a new Isolate with the specified AOT snapshot.
    int exit_code = 0;
    char* error = nullptr;

    Dart_Isolate isolate = CreateIsolateGroupAndSetupHelper(
        is_dartdev_isolate, script_name, "main",
        Options::packages_file() == nullptr ? package_config_override
                                            : Options::packages_file(),
        flags, nullptr /* callback_data */, &error, &exit_code);

    if (isolate == nullptr) {
      if (error != nullptr) {
        Syslog::PrintErr("Isolate spawning failed: %s\n", error);
        free(error);
      }
      error = nullptr;
      Process::TerminateExitCodeHandler();
      error = Dart_Cleanup();
      if (error != nullptr) {
        Syslog::PrintErr("Dart_Cleanup failed: %s\n", error);
        free(error);
      }
      dart::embedder::Cleanup();
      Platform::Exit((exit_code != 0) ? exit_code : kErrorExitCode);
    }

    Dart_EnterIsolate(isolate);
    ASSERT(isolate == Dart_CurrentIsolate());
    ASSERT(isolate != nullptr);
    Dart_Handle result;

    Dart_EnterScope();

    Dart_Handle send_port = Dart_Null();
    Dart_Port send_port_id = ILLEGAL_PORT;
    if (is_dartdev_isolate) {
      // Create a SendPort that DartDev can use to communicate its results over.
      send_port_id =
          Dart_NewNativePort(DART_DEV_ISOLATE_NAME, ResultCallback, false);
      ASSERT(send_port_id != ILLEGAL_PORT);
      send_port = Dart_NewSendPort(send_port_id);
      CHECK_RESULT(send_port);
    }

    // Lookup the library of the root script.
    Dart_Handle root_lib = Dart_RootLibrary();

    if (Dart_IsNull(root_lib)) {
      ErrorExit(kErrorExitCode, "Unable to find root library for '%s'\n",
                script_name);
    }

    // Create a closure for the main entry point which is in the exported
    // namespace of the root library or invoke a getter of the same name
    // in the exported namespace and return the resulting closure.
    Dart_Handle main_closure =
        Dart_GetField(root_lib, Dart_NewStringFromCString("main"));
    CHECK_RESULT(main_closure);
    if (!Dart_IsClosure(main_closure)) {
      ErrorExit(kErrorExitCode, "Unable to find 'main' in root library '%s'\n",
                script_name);
    }

    Dart_Handle isolate_lib =
        Dart_LookupLibrary(Dart_NewStringFromCString("dart:isolate"));
    if (is_dartdev_isolate) {
      const intptr_t kNumIsolateArgs = 4;
      Dart_Handle isolate_args[kNumIsolateArgs];
      isolate_args[0] = main_closure;                          // entryPoint
      isolate_args[1] = dart_options->CreateRuntimeOptions();  // args
      isolate_args[2] = send_port;
      isolate_args[3] = Dart_True();  // isSpawnUri
      result = Dart_Invoke(isolate_lib, Dart_NewStringFromCString(entry_point),
                           kNumIsolateArgs, isolate_args);
    } else {
      // Call _startIsolate in the isolate library to enable dispatching the
      // initial startup message.
      dart_options->Reset();
      dart_options->AddArguments(const_cast<const char**>(argv_.get()), argc_);
      const intptr_t kNumIsolateArgs = 2;
      Dart_Handle isolate_args[kNumIsolateArgs];
      isolate_args[0] = main_closure;                          // entryPoint
      isolate_args[1] = dart_options->CreateRuntimeOptions();  // args
      result = Dart_Invoke(isolate_lib, Dart_NewStringFromCString(entry_point),
                           kNumIsolateArgs, isolate_args);
    }
    CHECK_RESULT(result);

    // Keep handling messages until the last active receive port is closed.
    result = Dart_RunLoop();
    CHECK_RESULT(result);

    if (is_dartdev_isolate) {
      // DartDev is done processing the command. Close the native port, this
      // will ensure we exit from the event handler loop and exit dartdev
      // isolate.
      Dart_CloseNativePort(send_port_id);
    }
    Dart_ExitScope();

    // Shutdown the isolate.
    Dart_ShutdownIsolate();
  }

  static void RunExec(const char* script_name) {
    // Exec the JIT Dart VM with the specified script file.
    char err_msg[256];
    err_msg[0] = '\0';
    int ret = Process::Exec(nullptr, script_name,
                            const_cast<const char**>(argv_.get()), argc_,
                            nullptr, err_msg, sizeof(err_msg));
    if (ret != 0) {
      Syslog::PrintErr("%s.\n", err_msg);
      Process::SetGlobalExitCode(ret);
    } else {
      Process::SetGlobalExitCode(ret);
    }
  }

  static Dart_CObject* GetArrayItem(Dart_CObject* message, intptr_t index) {
    return message->value.as_array.values[index];
  }

  static Monitor* monitor_;
  static bool exited_;
  static DartDev_Result result_;
  static char* script_name_;
  static char* package_config_override_;
  static CommandLineOptions* dart_vm_options_;
  static std::unique_ptr<char*[], void (*)(char**)> argv_;
  static intptr_t argc_;
};

Monitor* DartDev::monitor_ = new Monitor();
bool DartDev::exited_ = false;
DartDev::DartDev_Result DartDev::result_ = DartDev::DartDev_Result_Unknown;
char* DartDev::script_name_ = nullptr;
char* DartDev::package_config_override_ = nullptr;
CommandLineOptions* DartDev::dart_vm_options_ = nullptr;
std::unique_ptr<char*[], void (*)(char**)> DartDev::argv_ =
    std::unique_ptr<char*[], void (*)(char**)>(nullptr, [](char**) {});
intptr_t DartDev::argc_ = 0;

#undef CHECK_RESULT

static void FreeConvertedArgs(int argc, char** argv, bool argv_converted) {
  // Free copied argument strings if converted.
  if (argv_converted) {
    for (int i = 0; i < argc; i++) {
      free(argv[i]);
    }
  }
}

void main(int argc, char** argv) {
#if !defined(DART_HOST_OS_WINDOWS)
  // Very early so any crashes during startup can also be symbolized.
  EXEUtils::LoadDartProfilerSymbols(argv[0]);
#endif

  const int EXTRA_VM_ARGUMENTS = 10;
  // An invocation line is as follows
  // dart <vm_opts> <cmd-name> <vm-opts-to-cmd> <script_name> <dart-options>

  // vm-opts : Set of VM options that need to be passed to the AOT runtime
  // running in this dartdev process.
  CommandLineOptions vm_options(argc + EXTRA_VM_ARGUMENTS);

  // vm-opts-to-cmd : Set of VM options that need to be passed to the runtime
  // that executes the dartdev command.
  CommandLineOptions dart_vm_options(argc + EXTRA_VM_ARGUMENTS);

  // dart-options : Set of options to be passed to the Dart program
  CommandLineOptions dart_options(argc + EXTRA_VM_ARGUMENTS);

  // Perform platform specific initialization.
  if (!Platform::Initialize()) {
    Syslog::PrintErr("Initialization failed\n");
    Platform::Exit(kErrorExitCode);
  }

  // Save the console state so we can restore it at shutdown.
  Console::SaveConfig();

  // On Windows, the argv strings are code page encoded and not
  // utf8. We need to convert them to utf8.
  bool argv_converted = ShellUtils::GetUtf8Argv(argc, argv);

  // When running from the command line we assume that we are optimizing for
  // throughput, and therefore use a larger new gen semi space size and a faster
  // new gen growth factor unless others have been specified.
  if (kWordSize <= 4) {
    vm_options.AddArgument("--new_gen_semi_max_size=16");
  } else {
    vm_options.AddArgument("--new_gen_semi_max_size=32");
  }
  vm_options.AddArgument("--new_gen_growth_factor=4");

  // Parse command line arguments.
  bool skip_dartdev;
  bool success = Options::ParseDartDevArguments(
      argc, argv, &vm_options, &dart_vm_options, &dart_options, &skip_dartdev);
  if (!success) {
    FreeConvertedArgs(argc, argv, argv_converted);
    if (Options::help_option()) {
      Options::PrintUsage();
      Platform::Exit(0);
    } else if (Options::version_option()) {
      Options::PrintVersion();
      Platform::Exit(0);
    } else {
      Options::PrintUsage();
      Platform::Exit(kErrorExitCode);
    }
  }
  if (skip_dartdev) {
    // We are skipping execution of dartdev as no Dart command line has
    // been specified, in this case we directly exec the Dart JIT VM to
    // run the specified script and pass in the original command line
    // arguments.
    DartDev::InvokeDartVM(argc, argv, argv_converted);
  }

  DartUtils::SetEnvironment(Options::environment());

  if (Options::suppress_core_dump()) {
    Platform::SetCoreDumpResourceLimit(0);
  }

  Loader::InitOnce();

  // Setup script_name to point to the dartdev AOT snapshot.
  auto dartdev_path = DartDev::ResolvedSnapshotPath();
  char* script_name = dartdev_path.get();
  if (script_name == nullptr || !CheckForInvalidPath(script_name)) {
    Syslog::PrintErr("Unable to find AOT snapshot for dartdev\n");
    FreeConvertedArgs(argc, argv, argv_converted);
    Platform::Exit(kErrorExitCode);
  }
  AppSnapshot* app_snapshot = Snapshot::TryReadAppSnapshot(
      script_name, /*force_load_from_memory*/ false, /*decode_uri*/ false);
  if (app_snapshot == nullptr || !app_snapshot->IsAOT()) {
    Syslog::PrintErr("%s is not an AOT snapshot\n", script_name);
    FreeConvertedArgs(argc, argv, argv_converted);
    if (app_snapshot != nullptr) {
      delete app_snapshot;
    }
    Platform::Exit(kErrorExitCode);
  }
  app_snapshot->SetBuffers(
      &ignore_vm_snapshot_data, &ignore_vm_snapshot_instructions,
      &app_isolate_snapshot_data, &app_isolate_snapshot_instructions);

  vm_options.AddArgument("--precompilation");

  char* error = nullptr;
  if (!dart::embedder::InitOnce(&error)) {
    Syslog::PrintErr("dartdev embedder initialization failed: %s\n", error);
    free(error);
    FreeConvertedArgs(argc, argv, argv_converted);
    delete app_snapshot;
    Platform::Exit(kErrorExitCode);
  }

  error = Dart_SetVMFlags(vm_options.count(), vm_options.arguments());
  if (error != nullptr) {
    for (int i = 0; i < argc; i++) {
      Syslog::PrintErr("argv[%d]: %s\n", i, argv[i]);
    }
    Syslog::PrintErr("Setting VM flags failed: %s\n", error);
    free(error);
    FreeConvertedArgs(argc, argv, argv_converted);
    delete app_snapshot;
    Platform::Exit(kErrorExitCode);
  }

  // Initialize the Dart VM.
  Dart_InitializeParams init_params;
  memset(&init_params, 0, sizeof(init_params));
  init_params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
  init_params.vm_snapshot_data = ignore_vm_snapshot_data;
  init_params.vm_snapshot_instructions = ignore_vm_snapshot_instructions;
  init_params.create_group = CreateIsolateGroupAndSetup;
  init_params.initialize_isolate = OnIsolateInitialize;
  init_params.shutdown_isolate = OnIsolateShutdown;
  init_params.cleanup_isolate = DeleteIsolateData;
  init_params.cleanup_group = DeleteIsolateGroupData;
  init_params.file_open = DartUtils::OpenFile;
  init_params.file_read = DartUtils::ReadFile;
  init_params.file_write = DartUtils::WriteFile;
  init_params.file_close = DartUtils::CloseFile;
  init_params.entropy_source = DartUtils::EntropySource;
  init_params.start_kernel_isolate = false;
#if defined(DART_HOST_OS_FUCHSIA)
  init_params.vmex_resource = ZX_HANDLE_INVALID;
#endif

  error = Dart_Initialize(&init_params);
  if (error != nullptr) {
    dart::embedder::Cleanup();
    Syslog::PrintErr("VM initialization failed: %s\n", error);
    free(error);
    FreeConvertedArgs(argc, argv, argv_converted);
    delete app_snapshot;
    Platform::Exit(kErrorExitCode);
  }

  Dart_SetServiceStreamCallbacks(&ServiceStreamListenCallback,
                                 &ServiceStreamCancelCallback);
  Dart_SetFileModifiedCallback(&FileModifiedCallback);
  Dart_SetEmbedderInformationCallback(&EmbedderInformationCallback);

  // Run dartdev as the main isolate.
  // The result from the running the dartdev isolate could result in one of
  // these options
  // - Exit the process due to some command parsing errors
  // - Run the Dart script in a JIT mode by execing the JIT runtime
  // - Run the Dart AOT snapshot by creating a new Isolate
  DartDev::RunDartDev(script_name, &dart_vm_options, &dart_options);

  // Terminate process exit-code handler.
  Process::TerminateExitCodeHandler();

  error = Dart_Cleanup();
  if (error != nullptr) {
    Syslog::PrintErr("VM cleanup failed: %s\n", error);
    free(error);
  }
  const intptr_t global_exit_code = Process::GlobalExitCode();
  dart::embedder::Cleanup();

  delete app_snapshot;

  // Free copied argument strings if converted.
  if (argv_converted) {
    for (int i = 0; i < argc; i++) {
      free(argv[i]);
    }
  }

  // Free environment if any.
  Options::Cleanup();

  Platform::Exit(global_exit_code);
}
#else
void main(int argc, char** argv) {
  Platform::Exit(kErrorExitCode);
}
#endif  // defined(DART_PRECOMPILED_RUNTIME)

}  // namespace bin
}  // namespace dart

int main(int argc, char** argv) {
  dart::bin::main(argc, argv);
  UNREACHABLE();
}
