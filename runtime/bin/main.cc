// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "include/dart_api.h"
#include "include/dart_tools_api.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/dfe.h"
#include "bin/directory.h"
#include "bin/embedded_dart_io.h"
#include "bin/error_exit.h"
#include "bin/eventhandler.h"
#include "bin/extensions.h"
#include "bin/file.h"
#include "bin/isolate_data.h"
#include "bin/loader.h"
#include "bin/log.h"
#include "bin/main_options.h"
#include "bin/platform.h"
#include "bin/process.h"
#include "bin/snapshot_utils.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/vmservice_impl.h"
#include "platform/globals.h"
#include "platform/growable_array.h"
#include "platform/hashmap.h"
#include "platform/text_buffer.h"
#if !defined(DART_PRECOMPILER)
#include "bin/gzip.h"
#endif

#include "vm/kernel.h"

extern "C" {
extern const uint8_t kDartVmSnapshotData[];
extern const uint8_t kDartVmSnapshotInstructions[];
extern const uint8_t kDartCoreIsolateSnapshotData[];
extern const uint8_t kDartCoreIsolateSnapshotInstructions[];
}

namespace dart {
namespace bin {

// Snapshot pieces if we link in a snapshot, otherwise initialized to NULL.
#if defined(DART_NO_SNAPSHOT)
const uint8_t* vm_snapshot_data = NULL;
const uint8_t* vm_snapshot_instructions = NULL;
const uint8_t* core_isolate_snapshot_data = NULL;
const uint8_t* core_isolate_snapshot_instructions = NULL;
#else
const uint8_t* vm_snapshot_data = kDartVmSnapshotData;
const uint8_t* vm_snapshot_instructions = kDartVmSnapshotInstructions;
const uint8_t* core_isolate_snapshot_data = kDartCoreIsolateSnapshotData;
const uint8_t* core_isolate_snapshot_instructions =
    kDartCoreIsolateSnapshotInstructions;
#endif

/**
 * Global state used to control and store generation of application snapshots.
 * An application snapshot can be generated and run using the following
 * command
 *   dart --snapshot-kind=app-jit --snapshot=<app_snapshot_filename>
 *       <script_uri> [<script_options>]
 * To Run the application snapshot generated above, use :
 *   dart <app_snapshot_filename> [<script_options>]
 */
static bool vm_run_app_snapshot = false;
#if !defined(DART_PRECOMPILED_RUNTIME)
DFE dfe;
#endif

static char* app_script_uri = NULL;
static const uint8_t* app_isolate_snapshot_data = NULL;
static const uint8_t* app_isolate_snapshot_instructions = NULL;

static Dart_Isolate main_isolate = NULL;

static Dart_Handle CreateRuntimeOptions(CommandLineOptions* options) {
  int options_count = options->count();
  Dart_Handle dart_arguments = Dart_NewList(options_count);
  if (Dart_IsError(dart_arguments)) {
    return dart_arguments;
  }
  for (int i = 0; i < options_count; i++) {
    Dart_Handle argument_value = DartUtils::NewString(options->GetArgument(i));
    if (Dart_IsError(argument_value)) {
      return argument_value;
    }
    Dart_Handle result = Dart_ListSetAt(dart_arguments, i, argument_value);
    if (Dart_IsError(result)) {
      return result;
    }
  }
  return dart_arguments;
}

static void* GetHashmapKeyFromString(char* key) {
  return reinterpret_cast<void*>(key);
}

static Dart_Handle EnvironmentCallback(Dart_Handle name) {
  uint8_t* utf8_array;
  intptr_t utf8_len;
  Dart_Handle result = Dart_Null();
  Dart_Handle handle = Dart_StringToUTF8(name, &utf8_array, &utf8_len);
  if (Dart_IsError(handle)) {
    handle = Dart_ThrowException(
        DartUtils::NewDartArgumentError(Dart_GetError(handle)));
  } else {
    char* name_chars = reinterpret_cast<char*>(malloc(utf8_len + 1));
    memmove(name_chars, utf8_array, utf8_len);
    name_chars[utf8_len] = '\0';
    const char* value = NULL;
    if (Options::environment() != NULL) {
      HashMap::Entry* entry = Options::environment()->Lookup(
          GetHashmapKeyFromString(name_chars), HashMap::StringHash(name_chars),
          false);
      if (entry != NULL) {
        value = reinterpret_cast<char*>(entry->value);
      }
    }
    if (value != NULL) {
      result = Dart_NewStringFromUTF8(reinterpret_cast<const uint8_t*>(value),
                                      strlen(value));
    }
    free(name_chars);
  }
  return result;
}

#define SAVE_ERROR_AND_EXIT(result)                                            \
  *error = strdup(Dart_GetError(result));                                      \
  if (Dart_IsCompilationError(result)) {                                       \
    *exit_code = kCompilationErrorExitCode;                                    \
  } else if (Dart_IsApiError(result)) {                                        \
    *exit_code = kApiErrorExitCode;                                            \
  } else {                                                                     \
    *exit_code = kErrorExitCode;                                               \
  }                                                                            \
  Dart_ExitScope();                                                            \
  Dart_ShutdownIsolate();                                                      \
  return NULL;

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    SAVE_ERROR_AND_EXIT(result);                                               \
  }

#define CHECK_RESULT_CLEANUP(result, cleanup)                                  \
  if (Dart_IsError(result)) {                                                  \
    delete (cleanup);                                                          \
    SAVE_ERROR_AND_EXIT(result);                                               \
  }

static void SnapshotOnExitHook(int64_t exit_code) {
  if (Dart_CurrentIsolate() != main_isolate) {
    Log::PrintErr(
        "A snapshot was requested, but a secondary isolate "
        "performed a hard exit (%" Pd64 ").\n",
        exit_code);
    Platform::Exit(kErrorExitCode);
  }
  if (exit_code == 0) {
    Snapshot::GenerateAppJIT(Options::snapshot_filename());
  }
}

static Dart_Isolate IsolateSetupHelper(Dart_Isolate isolate,
                                       bool is_main_isolate,
                                       const char* script_uri,
                                       const char* package_root,
                                       const char* packages_config,
                                       bool set_native_resolvers,
                                       bool isolate_run_app_snapshot,
                                       char** error,
                                       int* exit_code) {
  Dart_EnterScope();
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_IsolateData(isolate));
  void* kernel_program = isolate_data->kernel_program;

  // Set up the library tag handler for this isolate.
  Dart_Handle result = Dart_SetLibraryTagHandler(Loader::LibraryTagHandler);
  CHECK_RESULT(result);

  // Prepare builtin and other core libraries for use to resolve URIs.
  // Set up various closures, e.g: printing, timers etc.
  // Set up 'package root' for URI resolution.
  result = DartUtils::PrepareForScriptLoading(false, Options::trace_loading());
  CHECK_RESULT(result);

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (dfe.kernel_file_specified()) {
    ASSERT(kernel_program != NULL);
    result = Dart_LoadKernel(kernel_program);
    isolate_data->kernel_program = NULL;  // Dart_LoadKernel takes ownership.
  } else {
    if (kernel_program != NULL) {
      Dart_Handle uri = Dart_NewStringFromCString(script_uri);
      CHECK_RESULT(uri);
      Dart_Handle resolved_script_uri = DartUtils::ResolveScript(uri);
      CHECK_RESULT(resolved_script_uri);
      result =
          Dart_LoadScript(uri, resolved_script_uri,
                          reinterpret_cast<Dart_Handle>(kernel_program), 0, 0);
      isolate_data->kernel_program = NULL;  // Dart_LoadScript takes ownership.
      CHECK_RESULT(result);
    }
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  if (set_native_resolvers) {
    // Setup the native resolver as the snapshot does not carry it.
    Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
    Builtin::SetNativeResolver(Builtin::kIOLibrary);
  }
  if (isolate_run_app_snapshot) {
    Dart_Handle result = Loader::ReloadNativeExtensions();
    CHECK_RESULT(result);
  }

  // Set up the load port provided by the service isolate so that we can
  // load scripts.
  result = DartUtils::SetupServiceLoadPort();
  CHECK_RESULT(result);

  // Setup package root if specified.
  result = DartUtils::SetupPackageRoot(package_root, packages_config);
  CHECK_RESULT(result);

  result = Dart_SetEnvironmentCallback(EnvironmentCallback);
  CHECK_RESULT(result);

  if (isolate_run_app_snapshot) {
    result = DartUtils::SetupIOLibrary(Options::namespc(), script_uri,
                                       Options::exit_disabled());
    CHECK_RESULT(result);
    Loader::InitForSnapshot(script_uri);
#if !defined(DART_PRECOMPILED_RUNTIME)
    if (is_main_isolate) {
      // Find the canonical uri of the app snapshot. We'll use this to decide if
      // other isolates should use the app snapshot or the core snapshot.
      const char* resolved_script_uri = NULL;
      result = Dart_StringToCString(
          DartUtils::ResolveScript(Dart_NewStringFromCString(script_uri)),
          &resolved_script_uri);
      CHECK_RESULT(result);
      ASSERT(app_script_uri == NULL);
      app_script_uri = strdup(resolved_script_uri);
    }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  } else {
    // Load the specified application script into the newly created isolate.
    Dart_Handle uri =
        DartUtils::ResolveScript(Dart_NewStringFromCString(script_uri));
    CHECK_RESULT(uri);
    if (kernel_program == NULL) {
      result = Loader::LibraryTagHandler(Dart_kScriptTag, Dart_Null(), uri);
      CHECK_RESULT(result);
    } else {
      // Various core-library parts will send requests to the Loader to resolve
      // relative URIs and perform other related tasks. We need Loader to be
      // initialized for this to work because loading from Kernel binary
      // bypasses normal source code loading paths that initialize it.
      Loader::InitForSnapshot(script_uri);
    }

    Dart_TimelineEvent("LoadScript", Dart_TimelineGetMicros(),
                       Dart_GetMainPortId(), Dart_Timeline_Event_Async_End, 0,
                       NULL, NULL);

    result = DartUtils::SetupIOLibrary(Options::namespc(), script_uri,
                                       Options::exit_disabled());
    CHECK_RESULT(result);
  }

  // Make the isolate runnable so that it is ready to handle messages.
  Dart_ExitScope();
  Dart_ExitIsolate();
  bool retval = Dart_IsolateMakeRunnable(isolate);
  if (!retval) {
    *error = strdup("Invalid isolate state - Unable to make it runnable");
    Dart_EnterIsolate(isolate);
    Dart_ShutdownIsolate();
    return NULL;
  }

  return isolate;
}

#if !defined(DART_PRECOMPILED_RUNTIME)
// Returns newly created Kernel Isolate on success, NULL on failure.
// For now we only support the kernel isolate coming up from an
// application snapshot or from sources which are compiled by the
// VM parser.
static Dart_Isolate CreateAndSetupKernelIsolate(const char* main,
                                                const char* package_root,
                                                const char* packages_config,
                                                Dart_IsolateFlags* flags,
                                                char** error,
                                                int* exit_code) {
  if (!dfe.UseDartFrontend()) {
    *error = strdup("Kernel isolate not supported.");
    return NULL;
  }
  const char* script_uri = dfe.frontend_filename();
  if (packages_config == NULL) {
    packages_config = Options::packages_file();
  }

  // Kernel isolate uses an app snapshot or the core libraries snapshot.
  bool isolate_run_app_snapshot = false;
  const uint8_t* isolate_snapshot_data = core_isolate_snapshot_data;
  const uint8_t* isolate_snapshot_instructions =
      core_isolate_snapshot_instructions;
  AppSnapshot* app_snapshot = Snapshot::TryReadAppSnapshot(script_uri);
  if (app_snapshot != NULL) {
    isolate_run_app_snapshot = true;
    const uint8_t* ignore_vm_snapshot_data;
    const uint8_t* ignore_vm_snapshot_instructions;
    app_snapshot->SetBuffers(
        &ignore_vm_snapshot_data, &ignore_vm_snapshot_instructions,
        &isolate_snapshot_data, &isolate_snapshot_instructions);
  }

  IsolateData* isolate_data =
      new IsolateData(script_uri, package_root, packages_config, app_snapshot);
  Dart_Isolate isolate = Dart_CreateIsolate(
      script_uri, main, isolate_snapshot_data, isolate_snapshot_instructions,
      flags, isolate_data, error);
  if (isolate == NULL) {
    delete isolate_data;
    return NULL;
  }

  return IsolateSetupHelper(isolate, false, script_uri, package_root,
                            packages_config, isolate_snapshot_data,
                            isolate_run_app_snapshot, error, exit_code);
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

// Returns newly created Service Isolate on success, NULL on failure.
// For now we only support the service isolate coming up from sources
// which are compiled by the VM parser.
static Dart_Isolate CreateAndSetupServiceIsolate(const char* script_uri,
                                                 const char* main,
                                                 const char* package_root,
                                                 const char* packages_config,
                                                 Dart_IsolateFlags* flags,
                                                 char** error,
                                                 int* exit_code) {
  ASSERT(script_uri != NULL);

#if defined(DART_PRECOMPILED_RUNTIME)
  // AOT: All isolates start from the app snapshot.
  bool skip_library_load = true;
  const uint8_t* isolate_snapshot_data = app_isolate_snapshot_data;
  const uint8_t* isolate_snapshot_instructions =
      app_isolate_snapshot_instructions;
#else
  // JIT: Service isolate uses the core libraries snapshot.
  bool skip_library_load = false;
  const uint8_t* isolate_snapshot_data = core_isolate_snapshot_data;
  const uint8_t* isolate_snapshot_instructions =
      core_isolate_snapshot_instructions;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  Dart_Isolate isolate = NULL;
  IsolateData* isolate_data =
      new IsolateData(script_uri, package_root, packages_config, NULL);
#if defined(DART_PRECOMPILED_RUNTIME)
  isolate = Dart_CreateIsolate(script_uri, main, isolate_snapshot_data,
                               isolate_snapshot_instructions, flags,
                               isolate_data, error);
#else
  if (dfe.UsePlatformBinary()) {
    isolate = Dart_CreateIsolateFromKernel(
        script_uri, NULL, dfe.kernel_platform(), flags, isolate_data, error);
  } else {
    isolate = Dart_CreateIsolate(script_uri, main, isolate_snapshot_data,
                                 isolate_snapshot_instructions, flags,
                                 isolate_data, error);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  if (isolate == NULL) {
    delete isolate_data;
    return NULL;
  }

  Dart_EnterScope();

  Dart_Handle result = Dart_SetLibraryTagHandler(Loader::LibraryTagHandler);
  CHECK_RESULT(result);

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (dfe.UsePlatformBinary()) {
    // Read vmservice_io kernel file independently of main thread
    // as Dart_LoadKernel takes ownership.
    void* kernel_vmservice_io = dfe.ReadVMServiceIO();
    if (kernel_vmservice_io == NULL) {
      Log::PrintErr("Could not read dart:vmservice_io binary file.");
      Platform::Exit(kErrorExitCode);
    }
    // Dart_LoadKernel takes ownership.
    Dart_Handle library = Dart_LoadKernel(kernel_vmservice_io);
    CHECK_RESULT_CLEANUP(library, isolate_data);
    skip_library_load = true;
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Load embedder specific bits and return.
  if (!VmService::Setup(Options::vm_service_server_ip(),
                        Options::vm_service_server_port(), skip_library_load,
                        Options::vm_service_dev_mode(),
                        Options::trace_loading())) {
    *error = strdup(VmService::GetErrorMessage());
    return NULL;
  }
  if (Options::compile_all()) {
    result = Dart_CompileAll();
    CHECK_RESULT(result);
  }
  result = Dart_SetEnvironmentCallback(EnvironmentCallback);
  CHECK_RESULT(result);
  Dart_ExitScope();
  Dart_ExitIsolate();
  return isolate;
}

// Returns newly created Isolate on success, NULL on failure.
static Dart_Isolate CreateIsolateAndSetupHelper(bool is_main_isolate,
                                                const char* script_uri,
                                                const char* main,
                                                const char* package_root,
                                                const char* packages_config,
                                                Dart_IsolateFlags* flags,
                                                char** error,
                                                int* exit_code) {
  ASSERT(script_uri != NULL);
  void* kernel_platform = NULL;
  void* kernel_program = NULL;
  AppSnapshot* app_snapshot = NULL;

  IsolateData* isolate_data =
      new IsolateData(script_uri, package_root, packages_config, app_snapshot);
  if (is_main_isolate && (Options::snapshot_deps_filename() != NULL)) {
    isolate_data->set_dependencies(new MallocGrowableArray<char*>());
  }

#if defined(DART_PRECOMPILED_RUNTIME)
  // AOT: All isolates start from the app snapshot.
  bool isolate_run_app_snapshot = true;
  const uint8_t* isolate_snapshot_data = app_isolate_snapshot_data;
  const uint8_t* isolate_snapshot_instructions =
      app_isolate_snapshot_instructions;
#else
  // JIT: Main isolate starts from the app snapshot, if any. Other isolates
  // use the core libraries snapshot.
  bool isolate_run_app_snapshot = false;
  const uint8_t* isolate_snapshot_data = core_isolate_snapshot_data;
  const uint8_t* isolate_snapshot_instructions =
      core_isolate_snapshot_instructions;
  if ((app_isolate_snapshot_data != NULL) &&
      (is_main_isolate || ((app_script_uri != NULL) &&
                           (strcmp(script_uri, app_script_uri) == 0)))) {
    isolate_run_app_snapshot = true;
    isolate_snapshot_data = app_isolate_snapshot_data;
    isolate_snapshot_instructions = app_isolate_snapshot_instructions;
  } else if (!is_main_isolate) {
    app_snapshot = Snapshot::TryReadAppSnapshot(script_uri);
    if (app_snapshot != NULL) {
      isolate_run_app_snapshot = true;
      const uint8_t* ignore_vm_snapshot_data;
      const uint8_t* ignore_vm_snapshot_instructions;
      app_snapshot->SetBuffers(
          &ignore_vm_snapshot_data, &ignore_vm_snapshot_instructions,
          &isolate_snapshot_data, &isolate_snapshot_instructions);
    }
  }
  if (!isolate_run_app_snapshot) {
    kernel_platform = dfe.kernel_platform();
    kernel_program = dfe.ReadScript(script_uri);
    if (kernel_program != NULL) {
      // A kernel file was specified on the command line instead of a source
      // file. Load that kernel file directly.
      dfe.set_kernel_file_specified(true);
    } else if (dfe.UseDartFrontend()) {
      kernel_program = dfe.CompileAndReadScript(script_uri, error, exit_code);
      if (kernel_program == NULL) {
        return NULL;
      }
    }
    isolate_data->kernel_program = kernel_program;
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  Dart_Isolate isolate = NULL;
  if (kernel_platform != NULL) {
    isolate = Dart_CreateIsolateFromKernel(script_uri, main, kernel_platform,
                                           flags, isolate_data, error);
  } else if (kernel_program != NULL) {
    isolate = Dart_CreateIsolateFromKernel(script_uri, main, kernel_program,
                                           flags, isolate_data, error);
  } else {
    isolate = Dart_CreateIsolate(script_uri, main, isolate_snapshot_data,
                                 isolate_snapshot_instructions, flags,
                                 isolate_data, error);
  }
  if (isolate == NULL) {
    delete isolate_data;
    return NULL;
  }

  bool set_native_resolvers = (kernel_program || isolate_snapshot_data);
  return IsolateSetupHelper(isolate, is_main_isolate, script_uri, package_root,
                            packages_config, set_native_resolvers,
                            isolate_run_app_snapshot, error, exit_code);
}

#undef CHECK_RESULT

static Dart_Isolate CreateIsolateAndSetup(const char* script_uri,
                                          const char* main,
                                          const char* package_root,
                                          const char* package_config,
                                          Dart_IsolateFlags* flags,
                                          void* data,
                                          char** error) {
  // The VM should never call the isolate helper with a NULL flags.
  ASSERT(flags != NULL);
  ASSERT(flags->version == DART_FLAGS_CURRENT_VERSION);
  if ((package_root != NULL) && (package_config != NULL)) {
    *error = strdup(
        "Invalid arguments - Cannot simultaneously specify "
        "package root and package map.");
    return NULL;
  }

  int exit_code = 0;
#if !defined(DART_PRECOMPILED_RUNTIME)
  if (strcmp(script_uri, DART_KERNEL_ISOLATE_NAME) == 0) {
    return CreateAndSetupKernelIsolate(main, package_root, package_config,
                                       flags, error, &exit_code);
  }
#endif
  if (strcmp(script_uri, DART_VM_SERVICE_ISOLATE_NAME) == 0) {
    return CreateAndSetupServiceIsolate(script_uri, main, package_root,
                                        package_config, flags, error,
                                        &exit_code);
  }
  bool is_main_isolate = false;
  return CreateIsolateAndSetupHelper(is_main_isolate, script_uri, main,
                                     package_root, package_config, flags, error,
                                     &exit_code);
}

char* BuildIsolateName(const char* script_name, const char* func_name) {
  // Skip past any slashes in the script name.
  const char* last_slash = strrchr(script_name, '/');
  if (last_slash != NULL) {
    script_name = last_slash + 1;
  }

  const char* kFormat = "%s/%s";
  intptr_t len = strlen(script_name) + strlen(func_name) + 2;
  char* buffer = new char[len];
  ASSERT(buffer != NULL);
  snprintf(buffer, len, kFormat, script_name, func_name);
  return buffer;
}

static void OnIsolateShutdown(void* callback_data) {
  IsolateData* isolate_data = reinterpret_cast<IsolateData*>(callback_data);
  isolate_data->OnIsolateShutdown();
}

static void DeleteIsolateData(void* callback_data) {
  IsolateData* isolate_data = reinterpret_cast<IsolateData*>(callback_data);
  delete isolate_data;
}

static const char* kStdoutStreamId = "Stdout";
static const char* kStderrStreamId = "Stderr";

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
  }
}

static bool FileModifiedCallback(const char* url, int64_t since) {
  if (strncmp(url, "file:///", 8) == 0) {
    // If it isn't a file on local disk, we don't know if it has been
    // modified.
    return true;
  }
  int64_t data[File::kStatSize];
  File::Stat(NULL, url + 7, data);
  if (data[File::kType] == File::kDoesNotExist) {
    return true;
  }
  bool modified = data[File::kModifiedTime] > since;
  return modified;
}

static void EmbedderInformationCallback(Dart_EmbedderInformation* info) {
  info->version = DART_EMBEDDER_INFORMATION_CURRENT_VERSION;
  info->name = "Dart VM";
  Process::GetRSSInformation(&(info->max_rss), &(info->current_rss));
}

static void GenerateAppAOTSnapshot() {
  if (Options::use_blobs()) {
    Snapshot::GenerateAppAOTAsBlobs(Options::snapshot_filename());
  } else {
    Snapshot::GenerateAppAOTAsAssembly(Options::snapshot_filename());
  }
}

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    const int exit_code = Dart_IsCompilationError(result)                      \
                              ? kCompilationErrorExitCode                      \
                              : kErrorExitCode;                                \
    ErrorExit(exit_code, "%s\n", Dart_GetError(result));                       \
  }

static void WriteFile(const char* filename,
                      const uint8_t* buffer,
                      const intptr_t size) {
  File* file = File::Open(NULL, filename, File::kWriteTruncate);
  if (file == NULL) {
    ErrorExit(kErrorExitCode, "Unable to open file %s\n", filename);
  }
  if (!file->WriteFully(buffer, size)) {
    ErrorExit(kErrorExitCode, "Unable to write file %s\n", filename);
  }
  file->Release();
}

static void ReadFile(const char* filename, uint8_t** buffer, intptr_t* size) {
  File* file = File::Open(NULL, filename, File::kRead);
  if (file == NULL) {
    ErrorExit(kErrorExitCode, "Unable to open file %s\n", filename);
  }
  *size = file->Length();
  *buffer = reinterpret_cast<uint8_t*>(malloc(*size));
  if (!file->ReadFully(*buffer, *size)) {
    ErrorExit(kErrorExitCode, "Unable to read file %s\n", filename);
  }
  file->Release();
}

static Dart_QualifiedFunctionName standalone_entry_points[] = {
    // Functions.
    {"dart:_builtin", "::", "_getPrintClosure"},
    {"dart:_builtin", "::", "_libraryFilePath"},
    {"dart:_builtin", "::", "_resolveInWorkingDirectory"},
    {"dart:_builtin", "::", "_setPackageRoot"},
    {"dart:_builtin", "::", "_setPackagesMap"},
    {"dart:_builtin", "::", "_setWorkingDirectory"},
    {"dart:async", "::", "_setScheduleImmediateClosure"},
    {"dart:io", "::", "_getUriBaseClosure"},
    {"dart:io", "::", "_getWatchSignalInternal"},
    {"dart:io", "::", "_makeDatagram"},
    {"dart:io", "::", "_makeUint8ListView"},
    {"dart:io", "::", "_setupHooks"},
    {"dart:io", "_EmbedderConfig", "_mayExit"},
    {"dart:io", "_ExternalBuffer", "get:end"},
    {"dart:io", "_ExternalBuffer", "get:start"},
    {"dart:io", "_ExternalBuffer", "set:data"},
    {"dart:io", "_ExternalBuffer", "set:end"},
    {"dart:io", "_ExternalBuffer", "set:start"},
    {"dart:io", "_Namespace", "_setupNamespace"},
    {"dart:io", "_Platform", "set:_nativeScript"},
    {"dart:io", "_ProcessStartStatus", "set:_errorCode"},
    {"dart:io", "_ProcessStartStatus", "set:_errorMessage"},
    {"dart:io", "_SecureFilterImpl", "get:buffers"},
    {"dart:io", "_SecureFilterImpl", "get:ENCRYPTED_SIZE"},
    {"dart:io", "_SecureFilterImpl", "get:SIZE"},
    {"dart:io", "CertificateException", "CertificateException."},
    {"dart:io", "Directory", "Directory."},
    {"dart:io", "File", "File."},
    {"dart:io", "FileSystemException", "FileSystemException."},
    {"dart:io", "HandshakeException", "HandshakeException."},
    {"dart:io", "Link", "Link."},
    {"dart:io", "OSError", "OSError."},
    {"dart:io", "TlsException", "TlsException."},
    {"dart:io", "X509Certificate", "X509Certificate._"},
    {"dart:isolate", "::", "_getIsolateScheduleImmediateClosure"},
    {"dart:isolate", "::", "_setupHooks"},
    {"dart:isolate", "::", "_startMainIsolate"},
    {"dart:vmservice_io", "::", "main"},
    // Fields
    {"dart:_builtin", "::", "_isolateId"},
    {"dart:_builtin", "::", "_loadPort"},
    {"dart:_internal", "::", "_printClosure"},
    {"dart:vmservice_io", "::", "_autoStart"},
    {"dart:vmservice_io", "::", "_ip"},
    {"dart:vmservice_io", "::", "_isFuchsia"},
    {"dart:vmservice_io", "::", "_isWindows"},
    {"dart:vmservice_io", "::", "_originCheckDisabled"},
    {"dart:vmservice_io", "::", "_port"},
    {"dart:vmservice_io", "::", "_signalWatch"},
    {"dart:vmservice_io", "::", "_traceLoading"},
    {NULL, NULL, NULL}  // Must be terminated with NULL entries.
};

bool RunMainIsolate(const char* script_name, CommandLineOptions* dart_options) {
  // Call CreateIsolateAndSetup which creates an isolate and loads up
  // the specified application script.
  char* error = NULL;
  bool is_main_isolate = true;
  int exit_code = 0;
  char* isolate_name = BuildIsolateName(script_name, "main");
  Dart_IsolateFlags flags;
  Dart_IsolateFlagsInitialize(&flags);

  if (Options::gen_snapshot_kind() == kAppAOT) {
    flags.obfuscate = Options::obfuscate();
    flags.entry_points = standalone_entry_points;
  }

  Dart_Isolate isolate = CreateIsolateAndSetupHelper(
      is_main_isolate, script_name, "main", Options::package_root(),
      Options::packages_file(), &flags, &error, &exit_code);
  if (isolate == NULL) {
    delete[] isolate_name;
    Log::PrintErr("%s\n", error);
    free(error);
    error = NULL;
    Process::TerminateExitCodeHandler();
    error = Dart_Cleanup();
    if (error != NULL) {
      Log::PrintErr("VM cleanup failed: %s\n", error);
      free(error);
    }
    Process::ClearAllSignalHandlers();
    EventHandler::Stop();
    Platform::Exit((exit_code != 0) ? exit_code : kErrorExitCode);
  }
  main_isolate = isolate;
  delete[] isolate_name;

  Dart_EnterIsolate(isolate);
  ASSERT(isolate == Dart_CurrentIsolate());
  ASSERT(isolate != NULL);
  Dart_Handle result;

  Dart_EnterScope();

  if (Options::gen_snapshot_kind() == kScript) {
    Snapshot::GenerateScript(Options::snapshot_filename());
  } else {
    // Lookup the library of the root script.
    Dart_Handle root_lib = Dart_RootLibrary();
    // Import the root library into the builtin library so that we can easily
    // lookup the main entry point exported from the root library.
    IsolateData* isolate_data =
        reinterpret_cast<IsolateData*>(Dart_IsolateData(isolate));
    result = Dart_LibraryImportLibrary(isolate_data->builtin_lib(), root_lib,
                                       Dart_Null());
    if ((Options::gen_snapshot_kind() == kAppAOT) ||
        (Options::gen_snapshot_kind() == kAppJIT)) {
      // Load the embedder's portion of the VM service's Dart code so it will
      // be included in the app snapshot.
      void* kernel_vmservice_io = NULL;
#if !defined(DART_PRECOMPILED_RUNTIME)
      if (dfe.UsePlatformBinary()) {
        // Do not cache vmservice_io kernel file as
        // VmService::LoadForGenPrecompiled takes ownership.
        kernel_vmservice_io = dfe.ReadVMServiceIO();
        if (kernel_vmservice_io == NULL) {
          Log::PrintErr("Could not read dart:vmservice_io binary file.");
          Platform::Exit(kErrorExitCode);
        }
      }
#endif  // defined(DART_PRECOMPILED_RUNTIME)
      if (!VmService::LoadForGenPrecompiled(kernel_vmservice_io)) {
        Log::PrintErr("VM service loading failed: %s\n",
                      VmService::GetErrorMessage());
        Platform::Exit(kErrorExitCode);
      }
    }

    if (Options::compile_all()) {
      result = Dart_CompileAll();
      CHECK_RESULT(result);
    }

    if (Options::parse_all()) {
      result = Dart_ParseAll();
      CHECK_RESULT(result);
      Dart_ExitScope();
      // Shutdown the isolate.
      Dart_ShutdownIsolate();
      return false;
    }

    if (Options::gen_snapshot_kind() == kAppAOT) {
      uint8_t* feedback_buffer = NULL;
      intptr_t feedback_length = 0;
      if (Options::load_feedback_filename() != NULL) {
        File* file =
            File::Open(NULL, Options::load_feedback_filename(), File::kRead);
        if (file == NULL) {
          ErrorExit(kErrorExitCode, "Failed to read JIT feedback.\n");
        }
        feedback_length = file->Length();
        feedback_buffer = reinterpret_cast<uint8_t*>(malloc(feedback_length));
        if (!file->ReadFully(feedback_buffer, feedback_length)) {
          ErrorExit(kErrorExitCode, "Failed to read JIT feedback.\n");
        }
        file->Release();
      }

      result = Dart_Precompile(standalone_entry_points, feedback_buffer,
                               feedback_length);
      if (feedback_buffer != NULL) {
        free(feedback_buffer);
      }
      CHECK_RESULT(result);

      if (Options::obfuscate() &&
          (Options::obfuscation_map_filename() != NULL)) {
        uint8_t* buffer = NULL;
        intptr_t size = 0;
        result = Dart_GetObfuscationMap(&buffer, &size);
        CHECK_RESULT(result);
        WriteFile(Options::obfuscation_map_filename(), buffer, size);
      }
    }

    if (Options::gen_snapshot_kind() == kAppAOT) {
      GenerateAppAOTSnapshot();
    } else {
      if (Dart_IsNull(root_lib)) {
        ErrorExit(kErrorExitCode, "Unable to find root library for '%s'\n",
                  script_name);
      }

      if (Options::gen_snapshot_kind() == kAppJIT) {
        result = Dart_SortClasses();
        CHECK_RESULT(result);
      }

      if (Options::load_compilation_trace_filename() != NULL) {
        uint8_t* buffer = NULL;
        intptr_t size = 0;
        ReadFile(Options::load_compilation_trace_filename(), &buffer, &size);
        result = Dart_LoadCompilationTrace(buffer, size);
        CHECK_RESULT(result);
      }

      // Create a closure for the main entry point which is in the exported
      // namespace of the root library or invoke a getter of the same name
      // in the exported namespace and return the resulting closure.
      Dart_Handle main_closure =
          Dart_GetClosure(root_lib, Dart_NewStringFromCString("main"));
      CHECK_RESULT(main_closure);
      if (!Dart_IsClosure(main_closure)) {
        ErrorExit(kErrorExitCode,
                  "Unable to find 'main' in root library '%s'\n", script_name);
      }

      // Call _startIsolate in the isolate library to enable dispatching the
      // initial startup message.
      const intptr_t kNumIsolateArgs = 2;
      Dart_Handle isolate_args[kNumIsolateArgs];
      isolate_args[0] = main_closure;                        // entryPoint
      isolate_args[1] = CreateRuntimeOptions(dart_options);  // args

      Dart_Handle isolate_lib =
          Dart_LookupLibrary(Dart_NewStringFromCString("dart:isolate"));
      result = Dart_Invoke(isolate_lib,
                           Dart_NewStringFromCString("_startMainIsolate"),
                           kNumIsolateArgs, isolate_args);
      CHECK_RESULT(result);

      // Keep handling messages until the last active receive port is closed.
      result = Dart_RunLoop();
      // Generate an app snapshot after execution if specified.
      if (Options::gen_snapshot_kind() == kAppJIT) {
        if (!Dart_IsCompilationError(result)) {
          Snapshot::GenerateAppJIT(Options::snapshot_filename());
        }
      }
      CHECK_RESULT(result);

      if (Options::save_feedback_filename() != NULL) {
        uint8_t* buffer = NULL;
        intptr_t size = 0;
        result = Dart_SaveJITFeedback(&buffer, &size);
        CHECK_RESULT(result);
        WriteFile(Options::save_feedback_filename(), buffer, size);
      }

      if (Options::save_compilation_trace_filename() != NULL) {
        uint8_t* buffer = NULL;
        intptr_t size = 0;
        result = Dart_SaveCompilationTrace(&buffer, &size);
        CHECK_RESULT(result);
        WriteFile(Options::save_compilation_trace_filename(), buffer, size);
      }
    }
  }

  if (Options::snapshot_deps_filename() != NULL) {
    Loader::ResolveDependenciesAsFilePaths();
    IsolateData* isolate_data =
        reinterpret_cast<IsolateData*>(Dart_IsolateData(isolate));
    ASSERT(isolate_data != NULL);
    MallocGrowableArray<char*>* dependencies = isolate_data->dependencies();
    ASSERT(dependencies != NULL);
    File* file = File::Open(NULL, Options::snapshot_deps_filename(),
                            File::kWriteTruncate);
    if (file == NULL) {
      ErrorExit(kErrorExitCode,
                "Error: Unable to open snapshot depfile: %s\n\n",
                Options::snapshot_deps_filename());
    }
    bool success = true;
    success &= file->Print("%s: ", Options::snapshot_filename());
    for (intptr_t i = 0; i < dependencies->length(); i++) {
      char* dep = dependencies->At(i);
      success &= file->Print("%s ", dep);
      free(dep);
    }
    success &= file->Print("\n");
    if (!success) {
      ErrorExit(kErrorExitCode,
                "Error: Unable to write snapshot depfile: %s\n\n",
                Options::snapshot_deps_filename());
    }
    file->Release();
    isolate_data->set_dependencies(NULL);
    delete dependencies;
  }

  Dart_ExitScope();

  // Shutdown the isolate.
  Dart_ShutdownIsolate();

  // No restart.
  return false;
}

#undef CHECK_RESULT

// Observatory assets are only needed in the regular dart binary.
#if !defined(DART_PRECOMPILER) && !defined(NO_OBSERVATORY)
extern unsigned int observatory_assets_archive_len;
extern const uint8_t* observatory_assets_archive;


Dart_Handle GetVMServiceAssetsArchiveCallback() {
  uint8_t* decompressed = NULL;
  intptr_t decompressed_len = 0;
  Decompress(observatory_assets_archive, observatory_assets_archive_len,
             &decompressed, &decompressed_len);
  Dart_Handle tar_file =
      DartUtils::MakeUint8Array(decompressed, decompressed_len);
  // Free decompressed memory as it has been copied into a Dart array.
  free(decompressed);
  return tar_file;
}
#else   // !defined(DART_PRECOMPILER)
static Dart_GetVMServiceAssetsArchive GetVMServiceAssetsArchiveCallback = NULL;
#endif  // !defined(DART_PRECOMPILER)

void main(int argc, char** argv) {
  char* script_name;
  const int EXTRA_VM_ARGUMENTS = 8;
  CommandLineOptions vm_options(argc + EXTRA_VM_ARGUMENTS);
  CommandLineOptions dart_options(argc);
  bool print_flags_seen = false;
  bool verbose_debug_seen = false;

  // Perform platform specific initialization.
  if (!Platform::Initialize()) {
    Log::PrintErr("Initialization failed\n");
  }

  // On Windows, the argv strings are code page encoded and not
  // utf8. We need to convert them to utf8.
  bool argv_converted = ShellUtils::GetUtf8Argv(argc, argv);

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Processing of some command line flags directly manipulates dfe.
  Options::set_dfe(&dfe);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  // Parse command line arguments.
  if (Options::ParseArguments(argc, argv, vm_run_app_snapshot, &vm_options,
                              &script_name, &dart_options, &print_flags_seen,
                              &verbose_debug_seen) < 0) {
    if (Options::help_option()) {
      Options::PrintUsage();
      Platform::Exit(0);
    } else if (Options::version_option()) {
      Options::PrintVersion();
      Platform::Exit(0);
    } else if (print_flags_seen) {
      // Will set the VM flags, print them out and then we exit as no
      // script was specified on the command line.
      Dart_SetVMFlags(vm_options.count(), vm_options.arguments());
      Platform::Exit(0);
    } else {
      Options::PrintUsage();
      Platform::Exit(kErrorExitCode);
    }
  }

  Thread::InitOnce();

  Loader::InitOnce();

  if (!DartUtils::SetOriginalWorkingDirectory()) {
    OSError err;
    Log::PrintErr("Error determining current directory: %s\n", err.message());
    Platform::Exit(kErrorExitCode);
  }

  AppSnapshot* app_snapshot = Snapshot::TryReadAppSnapshot(script_name);
  if (app_snapshot != NULL) {
    vm_run_app_snapshot = true;
    app_snapshot->SetBuffers(&vm_snapshot_data, &vm_snapshot_instructions,
                             &app_isolate_snapshot_data,
                             &app_isolate_snapshot_instructions);
  }

#if !defined(PRODUCT) && !defined(DART_PRECOMPILED_RUNTIME)
  // Constant true if PRODUCT or DART_PRECOMPILED_RUNTIME.
  if ((Options::gen_snapshot_kind() != kNone) || vm_run_app_snapshot) {
    vm_options.AddArgument("--load_deferred_eagerly");
  }
#endif

  if (Options::gen_snapshot_kind() == kAppJIT) {
    vm_options.AddArgument("--fields_may_be_reset");
#if !defined(PRODUCT)
    vm_options.AddArgument("--collect_code=false");
#endif
  }
  if (Options::gen_snapshot_kind() == kAppAOT) {
    vm_options.AddArgument("--precompilation");
  }
#if defined(DART_PRECOMPILED_RUNTIME)
  vm_options.AddArgument("--precompilation");
#endif
  if (Options::gen_snapshot_kind() == kAppJIT) {
    Process::SetExitHook(SnapshotOnExitHook);
  }

  Dart_SetVMFlags(vm_options.count(), vm_options.arguments());

// Note: must read platform only *after* VM flags are parsed because
// they might affect how the platform is loaded.
#if !defined(DART_PRECOMPILED_RUNTIME)
  // If a kernel platform binary file is specified, read it. This
  // step will become redundant once we have the snapshot version
  // of the kernel core/platform libraries.
  if (dfe.UsePlatformBinary()) {
    void* kernel_platform = dfe.ReadPlatform();
    if (kernel_platform == NULL) {
      Log::PrintErr("The platform binary is not a valid Dart Kernel file.");
      Platform::Exit(kErrorExitCode);
    }
    dfe.set_kernel_platform(kernel_platform);
  }
#endif

  // Start event handler.
  TimerUtils::InitOnce();
  EventHandler::Start();

  // Initialize the Dart VM.
  Dart_InitializeParams init_params;
  memset(&init_params, 0, sizeof(init_params));
  init_params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
  init_params.vm_snapshot_data = vm_snapshot_data;
  init_params.vm_snapshot_instructions = vm_snapshot_instructions;
  init_params.create = CreateIsolateAndSetup;
  init_params.shutdown = OnIsolateShutdown;
  init_params.cleanup = DeleteIsolateData;
  init_params.file_open = DartUtils::OpenFile;
  init_params.file_read = DartUtils::ReadFile;
  init_params.file_write = DartUtils::WriteFile;
  init_params.file_close = DartUtils::CloseFile;
  init_params.entropy_source = DartUtils::EntropySource;
  init_params.get_service_assets = GetVMServiceAssetsArchiveCallback;
#if !defined(DART_PRECOMPILED_RUNTIME)
  init_params.start_kernel_isolate = dfe.UseDartFrontend();
#else
  init_params.start_kernel_isolate = false;
#endif

  char* error = Dart_Initialize(&init_params);
  if (error != NULL) {
    EventHandler::Stop();
    Log::PrintErr("VM initialization failed: %s\n", error);
    free(error);
    Platform::Exit(kErrorExitCode);
  }

  Dart_SetServiceStreamCallbacks(&ServiceStreamListenCallback,
                                 &ServiceStreamCancelCallback);
  Dart_SetFileModifiedCallback(&FileModifiedCallback);
  Dart_SetEmbedderInformationCallback(&EmbedderInformationCallback);

  // Run the main isolate until we aren't told to restart.
  while (RunMainIsolate(script_name, &dart_options)) {
    Log::PrintErr("Restarting VM\n");
  }

  // Terminate process exit-code handler.
  Process::TerminateExitCodeHandler();

  error = Dart_Cleanup();
  if (error != NULL) {
    Log::PrintErr("VM cleanup failed: %s\n", error);
    free(error);
  }
  Process::ClearAllSignalHandlers();
  EventHandler::Stop();

  delete app_snapshot;
  free(app_script_uri);

  // Free copied argument strings if converted.
  if (argv_converted) {
    for (int i = 0; i < argc; i++) {
      free(argv[i]);
    }
  }

  // Free environment if any.
  Options::DestroyEnvironment();

  Platform::Exit(Process::GlobalExitCode());
}

}  // namespace bin
}  // namespace dart

int main(int argc, char** argv) {
  dart::bin::main(argc, argv);
  UNREACHABLE();
}
