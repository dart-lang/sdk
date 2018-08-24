// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "include/dart_api.h"
#include "include/dart_embedder_api.h"
#include "include/dart_tools_api.h"

#include "bin/builtin.h"
#include "bin/console.h"
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

#include "vm/flags.h"

extern "C" {
extern const uint8_t kDartVmSnapshotData[];
extern const uint8_t kDartVmSnapshotInstructions[];
extern const uint8_t kDartCoreIsolateSnapshotData[];
extern const uint8_t kDartCoreIsolateSnapshotInstructions[];
}

#if defined(DART_LINK_APP_SNAPSHOT)
extern "C" {
extern const uint8_t _kDartVmSnapshotData[];
extern const uint8_t _kDartVmSnapshotInstructions[];
extern const uint8_t _kDartIsolateSnapshotData[];
extern const uint8_t _kDartIsolateSnapshotInstructions[];
}
#endif

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
static char* app_script_uri = NULL;
static const uint8_t* app_isolate_snapshot_data = NULL;
static const uint8_t* app_isolate_snapshot_instructions = NULL;
static const uint8_t* app_isolate_shared_data = NULL;
static const uint8_t* app_isolate_shared_instructions = NULL;
static bool kernel_isolate_is_running = false;

static Dart_Isolate main_isolate = NULL;

static void ReadFile(const char* filename, uint8_t** buffer, intptr_t* size);

static Dart_Handle CreateRuntimeOptions(CommandLineOptions* options) {
  int options_count = options->count();
  Dart_Handle dart_arguments =
      Dart_NewListOf(Dart_CoreType_String, options_count);
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

static void WriteDepsFile(Dart_Isolate isolate) {
  if (Options::depfile() == NULL) {
    return;
  }
  Loader::ResolveDependenciesAsFilePaths();
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_IsolateData(isolate));
  ASSERT(isolate_data != NULL);
  MallocGrowableArray<char*>* dependencies = isolate_data->dependencies();
  ASSERT(dependencies != NULL);
  File* file =
      File::Open(NULL, Options::depfile(), File::kWriteTruncate);
  if (file == NULL) {
    ErrorExit(kErrorExitCode, "Error: Unable to open snapshot depfile: %s\n\n",
              Options::depfile());
  }
  bool success = true;
  if (Options::snapshot_filename() != NULL) {
    success &= file->Print("%s: ", Options::snapshot_filename());
  } else {
    success &= file->Print("%s: ", Options::depfile_output_filename());
  }
  for (intptr_t i = 0; i < dependencies->length(); i++) {
    char* dep = dependencies->At(i);
    success &= file->Print("%s ", dep);
    free(dep);
  }
  if (Options::preview_dart_2()) {
    if (kernel_isolate_is_running) {
      Dart_KernelCompilationResult result = Dart_KernelListDependencies();
      if (result.status != Dart_KernelCompilationStatus_Ok) {
        ErrorExit(
            kErrorExitCode,
            "Error: Failed to fetch dependencies from kernel service: %s\n\n",
            result.error);
      }
      success &= file->WriteFully(result.kernel, result.kernel_size);
      free(result.kernel);
    }
  }
  success &= file->Print("\n");
  if (!success) {
    ErrorExit(kErrorExitCode, "Error: Unable to write snapshot depfile: %s\n\n",
              Options::depfile());
  }
  file->Release();
  dependencies->Clear();
}

static void OnExitHook(int64_t exit_code) {
  if (Dart_CurrentIsolate() != main_isolate) {
    Log::PrintErr(
        "A snapshot was requested, but a secondary isolate "
        "performed a hard exit (%" Pd64 ").\n",
        exit_code);
    Platform::Exit(kErrorExitCode);
  }
  if (exit_code == 0) {
    if (Options::gen_snapshot_kind() == kAppJIT) {
      Snapshot::GenerateAppJIT(Options::snapshot_filename());
    }
    WriteDepsFile(main_isolate);
  }
}

static Dart_Isolate IsolateSetupHelperAotCompilationDart2(
    const char* script_uri,
    const char* main,
    const char* package_root,
    const char* packages_config,
    Dart_IsolateFlags* flags,
    char** error,
    int* exit_code) {
  uint8_t* payload = NULL;
  intptr_t payload_length = -1;
  if (File::GetType(NULL, script_uri, true) == File::kIsFile) {
    ReadFile(script_uri, &payload, &payload_length);
  }
  if (payload == NULL ||
      DartUtils::SniffForMagicNumber(payload, payload_length) !=
          DartUtils::kKernelMagicNumber) {
    FATAL1(
        "Dart 2.0 AOT compilations only accept Kernel IR files as "
        "input ('%s' is not a valid Kernel IR file).\n",
        script_uri);
  }

  auto isolate_data = new IsolateData(script_uri, NULL, NULL, NULL);
  // Kernel buffer released by ~IsolateData during isolate shutdown.
  isolate_data->set_kernel_buffer(payload, payload_length,
                                  true /*take ownership*/);

  // We bootstrap the isolate from the Kernel file (instead of using a
  // potentially linked-in kernel file).
  Dart_Isolate isolate = Dart_CreateIsolateFromKernel(
      script_uri, main, payload, payload_length, flags, isolate_data, error);
  if (isolate == NULL) {
    free(payload);
    return NULL;
  }

  Dart_EnterScope();
  Dart_Handle library = Dart_LoadScriptFromKernel(payload, payload_length);
  CHECK_RESULT(library);
  Dart_ExitScope();
  Dart_ExitIsolate();

  return isolate;
}

static Dart_Isolate IsolateSetupHelper(Dart_Isolate isolate,
                                       bool is_main_isolate,
                                       const char* script_uri,
                                       const char* package_root,
                                       const char* packages_config,
                                       bool set_native_resolvers,
                                       bool isolate_run_app_snapshot,
                                       Dart_IsolateFlags* flags,
                                       char** error,
                                       int* exit_code) {
  Dart_EnterScope();
#if !defined(DART_PRECOMPILED_RUNTIME)
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_IsolateData(isolate));
  const uint8_t* kernel_buffer = isolate_data->kernel_buffer();
  intptr_t kernel_buffer_size = isolate_data->kernel_buffer_size();
#endif

  // Set up the library tag handler for this isolate.
  Dart_Handle result = Dart_SetLibraryTagHandler(Loader::LibraryTagHandler);
  CHECK_RESULT(result);

  // Prepare builtin and other core libraries for use to resolve URIs.
  // Set up various closures, e.g: printing, timers etc.
  // Set up 'package root' for URI resolution.
  result = DartUtils::PrepareForScriptLoading(false, Options::trace_loading());
  CHECK_RESULT(result);

  if (FLAG_support_service || !kDartPrecompiledRuntime) {
    // Set up the load port provided by the service isolate so that we can
    // load scripts.
    result = DartUtils::SetupServiceLoadPort();
    CHECK_RESULT(result);
  }

  // Setup package root if specified.
  result = DartUtils::SetupPackageRoot(NULL, packages_config);
  CHECK_RESULT(result);
  const char* resolved_packages_config = NULL;
  if (!Dart_IsNull(result)) {
    result = Dart_StringToCString(result, &resolved_packages_config);
    CHECK_RESULT(result);
    ASSERT(resolved_packages_config != NULL);
#if !defined(DART_PRECOMPILED_RUNTIME)
    isolate_data->set_resolved_packages_config(resolved_packages_config);
#endif
  }

  result = Dart_SetEnvironmentCallback(EnvironmentCallback);
  CHECK_RESULT(result);

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (Options::preview_dart_2() && !isolate_run_app_snapshot &&
      kernel_buffer == NULL && !Dart_IsKernelIsolate(isolate)) {
    if (!dfe.CanUseDartFrontend()) {
      const char* format = "Dart frontend unavailable to compile script %s.";
      intptr_t len = snprintf(NULL, 0, format, script_uri) + 1;
      *error = reinterpret_cast<char*>(malloc(len));
      ASSERT(error != NULL);
      snprintf(*error, len, format, script_uri);
      *exit_code = kErrorExitCode;
      Dart_ExitScope();
      Dart_ShutdownIsolate();
      return NULL;
    }
    uint8_t* application_kernel_buffer = NULL;
    intptr_t application_kernel_buffer_size = 0;
    dfe.CompileAndReadScript(script_uri, &application_kernel_buffer,
                             &application_kernel_buffer_size, error, exit_code,
                             resolved_packages_config);
    if (application_kernel_buffer == NULL) {
      Dart_ExitScope();
      Dart_ShutdownIsolate();
      return NULL;
    }
    isolate_data->set_kernel_buffer(application_kernel_buffer,
                                    application_kernel_buffer_size,
                                    true /*take ownership*/);
    kernel_buffer = application_kernel_buffer;
    kernel_buffer_size = application_kernel_buffer_size;
  }
  if (kernel_buffer != NULL) {
    Dart_Handle uri = Dart_NewStringFromCString(script_uri);
    CHECK_RESULT(uri);
    Dart_Handle resolved_script_uri = DartUtils::ResolveScript(uri);
    CHECK_RESULT(resolved_script_uri);
    result = Dart_LoadScriptFromKernel(kernel_buffer, kernel_buffer_size);
    CHECK_RESULT(result);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  if (set_native_resolvers) {
    // Setup the native resolver as the snapshot does not carry it.
    Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
    Builtin::SetNativeResolver(Builtin::kIOLibrary);
    Builtin::SetNativeResolver(Builtin::kCLILibrary);
  }
  if (isolate_run_app_snapshot) {
    Dart_Handle result = Loader::ReloadNativeExtensions();
    CHECK_RESULT(result);
  }

  const char* namespc =
      Dart_IsKernelIsolate(isolate) ? NULL : Options::namespc();
  if (isolate_run_app_snapshot) {
    result = DartUtils::SetupIOLibrary(namespc, script_uri,
                                       Options::exit_disabled());
    CHECK_RESULT(result);
    if (FLAG_support_service || !kDartPrecompiledRuntime) {
      Loader::InitForSnapshot(script_uri);
    }
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
#if !defined(DART_PRECOMPILED_RUNTIME)
    // Load the specified application script into the newly created isolate.
    Dart_Handle uri =
        DartUtils::ResolveScript(Dart_NewStringFromCString(script_uri));
    CHECK_RESULT(uri);
    if (kernel_buffer == NULL) {
      result = Loader::LibraryTagHandler(Dart_kScriptTag, Dart_Null(), uri);
      CHECK_RESULT(result);
    } else {
      // Various core-library parts will send requests to the Loader to resolve
      // relative URIs and perform other related tasks. We need Loader to be
      // initialized for this to work because loading from Kernel binary
      // bypasses normal source code loading paths that initialize it.
      const char* resolved_script_uri = NULL;
      result = Dart_StringToCString(uri, &resolved_script_uri);
      CHECK_RESULT(result);
      Loader::InitForSnapshot(resolved_script_uri);
    }

    Dart_TimelineEvent("LoadScript", Dart_TimelineGetMicros(),
                       Dart_GetMainPortId(), Dart_Timeline_Event_Async_End, 0,
                       NULL, NULL);

    result = DartUtils::SetupIOLibrary(namespc, script_uri,
                                       Options::exit_disabled());
    CHECK_RESULT(result);
#else
    UNREACHABLE();
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
  }

  // Make the isolate runnable so that it is ready to handle messages.
  Dart_ExitScope();
  Dart_ExitIsolate();
  *error = Dart_IsolateMakeRunnable(isolate);
  if (*error != NULL) {
    Dart_EnterIsolate(isolate);
    Dart_ShutdownIsolate();
    return NULL;
  }

  return isolate;
}

#if !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
// Returns newly created Kernel Isolate on success, NULL on failure.
// For now we only support the kernel isolate coming up from an
// application snapshot or from a .dill file.
static Dart_Isolate CreateAndSetupKernelIsolate(const char* script_uri,
                                                const char* main,
                                                const char* package_root,
                                                const char* packages_config,
                                                Dart_IsolateFlags* flags,
                                                char** error,
                                                int* exit_code) {
  // Do not start a kernel isolate if we are doing a training run
  // to create an app JIT snapshot and a kernel file is specified
  // as the application to run.
  if (Options::gen_snapshot_kind() == kAppJIT) {
    const uint8_t* kernel_buffer = NULL;
    intptr_t kernel_buffer_size = 0;
    dfe.application_kernel_buffer(&kernel_buffer, &kernel_buffer_size);
    if (kernel_buffer_size != 0) {
      return NULL;
    }
  }
  // Create and Start the kernel isolate.
  const char* kernel_snapshot_uri = dfe.frontend_filename();
  const char* uri =
      kernel_snapshot_uri != NULL ? kernel_snapshot_uri : script_uri;

  if (packages_config == NULL) {
    packages_config = Options::packages_file();
  }

  Dart_Isolate isolate;
  IsolateData* isolate_data = NULL;
  bool isolate_run_app_snapshot = false;
  AppSnapshot* app_snapshot = NULL;
  // Kernel isolate uses an app snapshot or uses the dill file.
  if ((kernel_snapshot_uri != NULL) &&
      (app_snapshot = Snapshot::TryReadAppSnapshot(kernel_snapshot_uri)) !=
          NULL) {
    const uint8_t* isolate_snapshot_data = NULL;
    const uint8_t* isolate_snapshot_instructions = NULL;
    const uint8_t* ignore_vm_snapshot_data;
    const uint8_t* ignore_vm_snapshot_instructions;
    isolate_run_app_snapshot = true;
    app_snapshot->SetBuffers(
        &ignore_vm_snapshot_data, &ignore_vm_snapshot_instructions,
        &isolate_snapshot_data, &isolate_snapshot_instructions);
    IsolateData* isolate_data =
        new IsolateData(uri, package_root, packages_config, app_snapshot);
    isolate = Dart_CreateIsolate(
        DART_KERNEL_ISOLATE_NAME, main, isolate_snapshot_data,
        isolate_snapshot_instructions, app_isolate_shared_data,
        app_isolate_shared_instructions, flags, isolate_data, error);
  } else {
    const uint8_t* kernel_service_buffer = NULL;
    intptr_t kernel_service_buffer_size = 0;
    dfe.LoadKernelService(&kernel_service_buffer, &kernel_service_buffer_size);
    ASSERT(kernel_service_buffer != NULL);
    IsolateData* isolate_data =
        new IsolateData(uri, package_root, packages_config, NULL);
    isolate_data->set_kernel_buffer(const_cast<uint8_t*>(kernel_service_buffer),
                                    kernel_service_buffer_size,
                                    false /* take_ownership */);
    isolate = Dart_CreateIsolateFromKernel(
        DART_KERNEL_ISOLATE_NAME, main, kernel_service_buffer,
        kernel_service_buffer_size, flags, isolate_data, error);
  }

  if (isolate == NULL) {
    Log::PrintErr("%s\n", *error);
    delete isolate_data;
    return NULL;
  }
  kernel_isolate_is_running = true;

  return IsolateSetupHelper(isolate, false, uri, package_root, packages_config,
                            true, isolate_run_app_snapshot, flags, error,
                            exit_code);
}
#endif  // !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)

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
  isolate = Dart_CreateIsolate(
      script_uri, main, isolate_snapshot_data, isolate_snapshot_instructions,
      app_isolate_shared_data, app_isolate_shared_instructions, flags,
      isolate_data, error);
#else
  // Set the flag to load the vmservice library. If not set, the kernel
  // loader might skip loading it. This is flag is not relevant for the
  // non-kernel flow.
  ASSERT(flags != NULL);
  flags->load_vmservice_library = true;

  if (Options::preview_dart_2()) {
    // If there is intention to use DFE, then we create the isolate
    // from kernel only if we can.
    const uint8_t* kernel_buffer = NULL;
    intptr_t kernel_buffer_size = 0;
    dfe.LoadPlatform(&kernel_buffer, &kernel_buffer_size);
    if (kernel_buffer == NULL) {
      dfe.application_kernel_buffer(&kernel_buffer, &kernel_buffer_size);
    }

    // TODO(sivachandra): When the platform program is unavailable, check if
    // application kernel binary is self contained or an incremental binary.
    // Isolate should be created only if it is a self contained kernel binary.
    if (kernel_buffer != NULL) {
      isolate = Dart_CreateIsolateFromKernel(script_uri, NULL, kernel_buffer,
                                             kernel_buffer_size, flags,
                                             isolate_data, error);
    } else {
      *error =
          strdup("Platform kernel not available to create service isolate.");
      delete isolate_data;
      return NULL;
    }
    skip_library_load = true;
  } else {
    isolate = Dart_CreateIsolate(
        script_uri, main, isolate_snapshot_data, isolate_snapshot_instructions,
        app_isolate_shared_data, app_isolate_shared_instructions, flags,
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

  // Load embedder specific bits and return.
  if (!VmService::Setup(Options::vm_service_server_ip(),
                        Options::vm_service_server_port(), skip_library_load,
                        Options::vm_service_dev_mode(),
                        Options::trace_loading(), Options::deterministic())) {
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
  int64_t start = Dart_TimelineGetMicros();
  ASSERT(script_uri != NULL);
  uint8_t* kernel_buffer = NULL;
  intptr_t kernel_buffer_size = 0;
  AppSnapshot* app_snapshot = NULL;

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
    dfe.ReadScript(script_uri, &kernel_buffer, &kernel_buffer_size);
  }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  IsolateData* isolate_data =
      new IsolateData(script_uri, package_root, packages_config, app_snapshot);
  if (kernel_buffer != NULL) {
    isolate_data->set_kernel_buffer(kernel_buffer, kernel_buffer_size,
                                    true /*take ownership*/);
  }
  if (is_main_isolate && (Options::depfile() != NULL)) {
    isolate_data->set_dependencies(new MallocGrowableArray<char*>());
  }

  Dart_Isolate isolate = NULL;

#if !defined(DART_PRECOMPILED_RUNTIME)
  if (Options::preview_dart_2() && !isolate_run_app_snapshot) {
    const uint8_t* platform_kernel_buffer = NULL;
    intptr_t platform_kernel_buffer_size = 0;
    dfe.LoadPlatform(&platform_kernel_buffer, &platform_kernel_buffer_size);
    if (platform_kernel_buffer == NULL) {
      platform_kernel_buffer = kernel_buffer;
      platform_kernel_buffer_size = kernel_buffer_size;
    }
    if (platform_kernel_buffer == NULL) {
#if defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
      FATAL(
          "Binary built with --exclude-kernel-service. Cannot run"
          " from source.");
#else
      FATAL("platform_program cannot be NULL.");
#endif  // defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
    }
    // TODO(sivachandra): When the platform program is unavailable, check if
    // application kernel binary is self contained or an incremental binary.
    // Isolate should be created only if it is a self contained kernel binary.
    isolate = Dart_CreateIsolateFromKernel(
        script_uri, main, platform_kernel_buffer, platform_kernel_buffer_size,
        flags, isolate_data, error);
  } else {
    isolate = Dart_CreateIsolate(
        script_uri, main, isolate_snapshot_data, isolate_snapshot_instructions,
        app_isolate_shared_data, app_isolate_shared_instructions, flags,
        isolate_data, error);
  }
#else
  isolate = Dart_CreateIsolate(
      script_uri, main, isolate_snapshot_data, isolate_snapshot_instructions,
      app_isolate_shared_data, app_isolate_shared_instructions, flags,
      isolate_data, error);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

  Dart_Isolate created_isolate = NULL;
  if (isolate == NULL) {
    delete isolate_data;
  } else {
#if !defined(DART_PRECOMPILED_RUNTIME)
    bool set_native_resolvers =
        (kernel_buffer != NULL) || (isolate_snapshot_data != NULL);
#else
    bool set_native_resolvers = isolate_snapshot_data != NULL;
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

    created_isolate =
        IsolateSetupHelper(isolate, is_main_isolate, script_uri, package_root,
                           packages_config, set_native_resolvers,
                           isolate_run_app_snapshot, flags, error, exit_code);
  }
  int64_t end = Dart_TimelineGetMicros();
  Dart_TimelineEvent("CreateIsolateAndSetupHelper", start, end,
                     Dart_Timeline_Event_Duration, 0, NULL, NULL);
  return created_isolate;
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
#if !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
  if (strcmp(script_uri, DART_KERNEL_ISOLATE_NAME) == 0) {
    return CreateAndSetupKernelIsolate(script_uri, main, package_root,
                                       package_config, flags, error,
                                       &exit_code);
  }
#endif  // !defined(EXCLUDE_CFE_AND_KERNEL_PLATFORM)
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
  if (strncmp(url, "file:///", 8) != 0) {
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
    Snapshot::GenerateAppAOTAsBlobs(Options::snapshot_filename(),
                                    app_isolate_shared_data,
                                    app_isolate_shared_instructions);
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

  Dart_Isolate isolate = NULL;
  if (flags.strong && Options::gen_snapshot_kind() == kAppAOT) {
    isolate = IsolateSetupHelperAotCompilationDart2(
        script_name, "main", Options::package_root(), Options::packages_file(),
        &flags, &error, &exit_code);
  } else {
    isolate = CreateIsolateAndSetupHelper(
        is_main_isolate, script_name, "main", Options::package_root(),
        Options::packages_file(), &flags, &error, &exit_code);
  }

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

  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_IsolateData(isolate));
  if (Options::gen_snapshot_kind() == kScript) {
    if (vm_run_app_snapshot) {
      Log::PrintErr("Cannot create a script snapshot from an app snapshot.\n");
      // The snapshot would contain references to the app snapshot instead of
      // the core snapshot.
      Platform::Exit(kErrorExitCode);
    }
    if (Options::preview_dart_2()) {
      Snapshot::GenerateKernel(Options::snapshot_filename(), script_name,
                               isolate_data->resolved_packages_config());
    } else {
      Snapshot::GenerateScript(Options::snapshot_filename());
    }
  } else {
    // Lookup the library of the root script.
    Dart_Handle root_lib = Dart_RootLibrary();
    // Import the root library into the builtin library so that we can easily
    // lookup the main entry point exported from the root library.
    result = Dart_LibraryImportLibrary(DartUtils::LookupBuiltinLib(), root_lib,
                                       Dart_Null());
#if !defined(DART_PRECOMPILED_RUNTIME)
    if (Options::gen_snapshot_kind() == kAppAOT) {
      // Load the embedder's portion of the VM service's Dart code so it will
      // be included in the app snapshot.
      if (!VmService::LoadForGenPrecompiled(dfe.UseDartFrontend())) {
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
      result = Dart_Precompile(standalone_entry_points);
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
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

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
          Dart_GetField(root_lib, Dart_NewStringFromCString("main"));
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

      if (Options::save_compilation_trace_filename() != NULL) {
        uint8_t* buffer = NULL;
        intptr_t size = 0;
        result = Dart_SaveCompilationTrace(&buffer, &size);
        CHECK_RESULT(result);
        WriteFile(Options::save_compilation_trace_filename(), buffer, size);
      }
    }
  }

  WriteDepsFile(isolate);

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
  const int EXTRA_VM_ARGUMENTS = 10;
  CommandLineOptions vm_options(argc + EXTRA_VM_ARGUMENTS);
  CommandLineOptions dart_options(argc);
  bool print_flags_seen = false;
  bool verbose_debug_seen = false;

  // Perform platform specific initialization.
  if (!Platform::Initialize()) {
    Log::PrintErr("Initialization failed\n");
    Platform::Exit(kErrorExitCode);
  }

  // Save the console state so we can restore it at shutdown.
  Console::SaveConfig();

  // On Windows, the argv strings are code page encoded and not
  // utf8. We need to convert them to utf8.
  bool argv_converted = ShellUtils::GetUtf8Argv(argc, argv);

#if !defined(DART_PRECOMPILED_RUNTIME)
  // Processing of some command line flags directly manipulates dfe.
  Options::set_dfe(&dfe);
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

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
      char* error = Dart_SetVMFlags(vm_options.count(), vm_options.arguments());
      if (error != NULL) {
        Log::PrintErr("Setting VM flags failed: %s\n", error);
        free(error);
        Platform::Exit(kErrorExitCode);
      }
      Platform::Exit(0);
    } else {
      Options::PrintUsage();
      Platform::Exit(kErrorExitCode);
    }
  }

  Loader::InitOnce();

#if defined(DART_LINK_APP_SNAPSHOT)
  vm_run_app_snapshot = true;
  vm_snapshot_data = _kDartVmSnapshotData;
  vm_snapshot_instructions = _kDartVmSnapshotInstructions;
  app_isolate_snapshot_data = _kDartIsolateSnapshotData;
  app_isolate_snapshot_instructions = _kDartIsolateSnapshotInstructions;
#else
  AppSnapshot* shared_blobs = NULL;
  if (Options::shared_blobs_filename() != NULL) {
    Log::PrintErr("Shared blobs in the standalone VM are for testing only.\n");
    shared_blobs =
        Snapshot::TryReadAppSnapshot(Options::shared_blobs_filename());
    if (shared_blobs == NULL) {
      Log::PrintErr("Failed to load: %s\n", Options::shared_blobs_filename());
      Platform::Exit(kErrorExitCode);
    }
    const uint8_t* ignored;
    shared_blobs->SetBuffers(&ignored, &ignored, &app_isolate_shared_data,
                             &app_isolate_shared_instructions);
  }
  AppSnapshot* app_snapshot = Snapshot::TryReadAppSnapshot(script_name);
  if (app_snapshot != NULL) {
    vm_run_app_snapshot = true;
    app_snapshot->SetBuffers(&vm_snapshot_data, &vm_snapshot_instructions,
                             &app_isolate_snapshot_data,
                             &app_isolate_snapshot_instructions);
  }
#endif

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
  // If we need to write an app-jit snapshot or a depfile, then add an exit
  // hook that writes the snapshot and/or depfile as appropriate.
  if ((Options::gen_snapshot_kind() == kAppJIT) ||
      (Options::depfile() != NULL)) {
    Process::SetExitHook(OnExitHook);
  }

  char* error = nullptr;
  if (!dart::embedder::InitOnce(&error)) {
    Log::PrintErr("Stanalone embedder initialization failed: %s\n", error);
    free(error);
    Platform::Exit(kErrorExitCode);
  }

  error = Dart_SetVMFlags(vm_options.count(), vm_options.arguments());
  if (error != NULL) {
    Log::PrintErr("Setting VM flags failed: %s\n", error);
    free(error);
    Platform::Exit(kErrorExitCode);
  }

// Note: must read platform only *after* VM flags are parsed because
// they might affect how the platform is loaded.
#if !defined(DART_PRECOMPILED_RUNTIME)
  dfe.Init();
  uint8_t* application_kernel_buffer = NULL;
  intptr_t application_kernel_buffer_size = 0;
  dfe.ReadScript(script_name, &application_kernel_buffer,
                 &application_kernel_buffer_size);
  if (application_kernel_buffer != NULL) {
    // Since we loaded the script anyway, save it.
    dfe.set_application_kernel_buffer(application_kernel_buffer,
                                      application_kernel_buffer_size);
    // Since we saw a dill file, it means we have to turn on all the
    // preview_dart_2 options.
    if (Options::no_preview_dart_2()) {
      Log::PrintErr(
          "A kernel file is specified as the input, "
          "--no-preview-dart-2 option is incompatible with it\n");
      Platform::Exit(kErrorExitCode);
    }
    Options::dfe()->set_use_dfe();
  }
#endif

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
  init_params.start_kernel_isolate =
      dfe.UseDartFrontend() && dfe.CanUseDartFrontend();
#else
  init_params.start_kernel_isolate = false;
#endif

  error = Dart_Initialize(&init_params);
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

#if !defined(DART_LINK_APP_SNAPSHOT)
  delete app_snapshot;
  delete shared_blobs;
#endif
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
