// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/console.h"
#include "bin/crashpad.h"
#include "bin/dartutils.h"
#include "bin/dfe.h"
#include "bin/eventhandler.h"
#include "bin/file.h"
#include "bin/loader.h"
#include "bin/platform.h"
#include "bin/snapshot_utils.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "platform/assert.h"
#include "vm/benchmark_test.h"
#include "vm/dart.h"
#include "vm/unit_test.h"

extern "C" {
extern const uint8_t kDartVmSnapshotData[];
extern const uint8_t kDartVmSnapshotInstructions[];
extern const uint8_t kDartCoreIsolateSnapshotData[];
extern const uint8_t kDartCoreIsolateSnapshotInstructions[];
}

// TODO(iposva, asiva): This is a placeholder for the real unittest framework.
namespace dart {

// Defined in vm/os_thread_win.cc
extern bool private_flag_windows_run_tls_destructors;

// Snapshot pieces when we link in a snapshot.
#if defined(DART_NO_SNAPSHOT)
#error "run_vm_tests must be built with a snapshot"
#else
const uint8_t* bin::vm_snapshot_data = kDartVmSnapshotData;
const uint8_t* bin::vm_snapshot_instructions = kDartVmSnapshotInstructions;
const uint8_t* bin::core_isolate_snapshot_data = kDartCoreIsolateSnapshotData;
const uint8_t* bin::core_isolate_snapshot_instructions =
    kDartCoreIsolateSnapshotInstructions;
#endif

// Only run tests that match the filter string. The default does not match any
// tests.
static const char* const kNone = "No Test or Benchmarks";
static const char* const kList = "List all Tests and Benchmarks";
static const char* const kAllBenchmarks = "All Benchmarks";
static const char* run_filter = kNone;
static const char* kernel_snapshot = NULL;

static int run_matches = 0;

void TestCase::Run() {
  bin::Log::Print("Running test: %s\n", name());
  (*run_)();
  bin::Log::Print("Done: %s\n", name());
}

void RawTestCase::Run() {
  bin::Log::Print("Running raw test: %s\n", name());
  (*run_)();
  bin::Log::Print("Done: %s\n", name());
}

void TestCaseBase::RunTest() {
  if (strcmp(run_filter, this->name()) == 0) {
    this->Run();
    run_matches++;
  } else if (run_filter == kList) {
    bin::Log::Print("%s\n", this->name());
    run_matches++;
  }
}

void Benchmark::RunBenchmark() {
  if ((run_filter == kAllBenchmarks) ||
      (strcmp(run_filter, this->name()) == 0)) {
    this->Run();
    bin::Log::Print("%s(%s): %" Pd64 "\n", this->name(), this->score_kind(),
                    this->score());
    run_matches++;
  } else if (run_filter == kList) {
    bin::Log::Print("%s\n", this->name());
    run_matches++;
  }
}

static void PrintUsage() {
  bin::Log::PrintErr(
      "Usage: one of the following\n"
      "  run_vm_tests --list\n"
      "  run_vm_tests [--dfe=<snapshot file name>] --benchmarks\n"
      "  run_vm_tests [--dfe=<snapshot file name>] [vm-flags ...] <test name>\n"
      "  run_vm_tests [--dfe=<snapshot file name>] [vm-flags ...] <benchmark "
      "name>\n");
}

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    *error = strdup(Dart_GetError(result));                                    \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    return NULL;                                                               \
  }

static Dart_Isolate CreateIsolateAndSetup(const char* script_uri,
                                          const char* main,
                                          const char* package_root,
                                          const char* packages_config,
                                          Dart_IsolateFlags* flags,
                                          void* data,
                                          char** error) {
  ASSERT(script_uri != NULL);
  const bool is_service_isolate =
      strcmp(script_uri, DART_VM_SERVICE_ISOLATE_NAME) == 0;
  if (is_service_isolate) {
    // We don't need service isolate for VM tests.
    return NULL;
  }
  const bool is_kernel_isolate =
      strcmp(script_uri, DART_KERNEL_ISOLATE_NAME) == 0;
  if (!is_kernel_isolate) {
    *error =
        strdup("Spawning of only Kernel isolate is supported in run_vm_tests.");
    return NULL;
  }
  Dart_Isolate isolate = NULL;
  bin::IsolateData* isolate_data = NULL;
  const uint8_t* kernel_service_buffer = NULL;
  intptr_t kernel_service_buffer_size = 0;

  // Kernel isolate uses an app snapshot or the kernel service dill file.
  if (kernel_snapshot != NULL &&
      (bin::DartUtils::SniffForMagicNumber(kernel_snapshot) ==
       bin::DartUtils::kAppJITMagicNumber)) {
    script_uri = kernel_snapshot;
    bin::AppSnapshot* app_snapshot =
        bin::Snapshot::TryReadAppSnapshot(script_uri);
    ASSERT(app_snapshot != NULL);
    const uint8_t* ignore_vm_snapshot_data;
    const uint8_t* ignore_vm_snapshot_instructions;
    const uint8_t* isolate_snapshot_data;
    const uint8_t* isolate_snapshot_instructions;
    app_snapshot->SetBuffers(
        &ignore_vm_snapshot_data, &ignore_vm_snapshot_instructions,
        &isolate_snapshot_data, &isolate_snapshot_instructions);
    isolate_data = new bin::IsolateData(script_uri, package_root,
                                        packages_config, app_snapshot);
    isolate = Dart_CreateIsolate(
        DART_KERNEL_ISOLATE_NAME, main, isolate_snapshot_data,
        isolate_snapshot_instructions, NULL, NULL, flags, isolate_data, error);
    if (*error != NULL) {
      free(*error);
      *error = NULL;
    }
  }
  if (isolate == NULL) {
    delete isolate_data;
    isolate_data = NULL;

    bin::dfe.Init();
    bin::dfe.LoadKernelService(&kernel_service_buffer,
                               &kernel_service_buffer_size);
    ASSERT(kernel_service_buffer != NULL);
    isolate_data =
        new bin::IsolateData(script_uri, package_root, packages_config, NULL);
    isolate_data->SetKernelBufferUnowned(
        const_cast<uint8_t*>(kernel_service_buffer),
        kernel_service_buffer_size);
    isolate = Dart_CreateIsolateFromKernel(
        script_uri, main, kernel_service_buffer, kernel_service_buffer_size,
        flags, isolate_data, error);
  }
  if (isolate == NULL) {
    delete isolate_data;
    return NULL;
  }

  Dart_EnterScope();

  bin::DartUtils::SetOriginalWorkingDirectory();
  Dart_Handle result = bin::DartUtils::PrepareForScriptLoading(
      false /* is_service_isolate */, false /* trace_loading */);
  CHECK_RESULT(result);

  // Setup kernel service as the main script for this isolate.
  if (kernel_service_buffer) {
    result = Dart_LoadScriptFromKernel(kernel_service_buffer,
                                       kernel_service_buffer_size);
    CHECK_RESULT(result);
  }

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

static void CleanupIsolate(void* callback_data) {
  bin::IsolateData* isolate_data =
      reinterpret_cast<bin::IsolateData*>(callback_data);
  delete isolate_data;
}

void ShiftArgs(int* argc, const char** argv) {
  // Remove the first flag from the list by shifting all arguments down.
  for (intptr_t i = 1; i < *argc - 1; i++) {
    argv[i] = argv[i + 1];
  }
  argv[*argc - 1] = nullptr;
  (*argc)--;
}

static int Main(int argc, const char** argv) {
  // Flags being passed to the Dart VM.
  int dart_argc = 0;
  const char** dart_argv = NULL;

  // Perform platform specific initialization.
  if (!dart::bin::Platform::Initialize()) {
    bin::Log::PrintErr("Initialization failed\n");
    return 1;
  }

  // Save the console state so we can restore it later.
  dart::bin::Console::SaveConfig();

  // Store the executable name.
  dart::bin::Platform::SetExecutableName(argv[0]);

  if (argc < 2) {
    // Bad parameter count.
    PrintUsage();
    return 1;
  }

  if (argc == 2 && strcmp(argv[1], "--list") == 0) {
    run_filter = kList;
    // List all tests and benchmarks and exit without initializing the VM.
    TestCaseBase::RunAll();
    Benchmark::RunAll(argv[0]);
    TestCaseBase::RunAllRaw();
    fflush(stdout);
    return 0;
  }

  int arg_pos = 1;
  bool start_kernel_isolate = false;
  bool suppress_core_dump = false;
  if (strcmp(argv[arg_pos], "--suppress-core-dump") == 0) {
    suppress_core_dump = true;
    ShiftArgs(&argc, argv);
  }

  if (suppress_core_dump) {
    bin::Platform::SetCoreDumpResourceLimit(0);
  } else {
    bin::InitializeCrashpadClient();
  }

  if (strncmp(argv[arg_pos], "--dfe", strlen("--dfe")) == 0) {
    const char* delim = strstr(argv[arg_pos], "=");
    if (delim == NULL || strlen(delim + 1) == 0) {
      bin::Log::PrintErr("Invalid value for the option: %s\n", argv[arg_pos]);
      PrintUsage();
      return 1;
    }
    kernel_snapshot = strdup(delim + 1);
    start_kernel_isolate = true;
    ShiftArgs(&argc, argv);
  }

  if (arg_pos == argc - 1 && strcmp(argv[arg_pos], "--benchmarks") == 0) {
    // "--benchmarks" is the last argument.
    run_filter = kAllBenchmarks;
  } else {
    // Last argument is the test name, the rest are vm flags.
    run_filter = argv[argc - 1];
    // Remove the first value (executable) from the arguments and
    // exclude the last argument which is the test name.
    dart_argc = argc - 2;
    dart_argv = &argv[1];
  }

  bin::TimerUtils::InitOnce();
  bin::EventHandler::Start();

  char* error = Flags::ProcessCommandLineFlags(dart_argc, dart_argv);
  if (error != NULL) {
    bin::Log::PrintErr("Failed to parse flags: %s\n", error);
    free(error);
    return 1;
  }

  TesterState::vm_snapshot_data = dart::bin::vm_snapshot_data;
  TesterState::create_callback = CreateIsolateAndSetup;
  TesterState::cleanup_callback = CleanupIsolate;
  TesterState::argv = dart_argv;
  TesterState::argc = dart_argc;

  error = Dart::Init(
      dart::bin::vm_snapshot_data, dart::bin::vm_snapshot_instructions,
      CreateIsolateAndSetup /* create */, nullptr /* shutdown */,
      CleanupIsolate /* cleanup */, nullptr /* thread_exit */,
      dart::bin::DartUtils::OpenFile, dart::bin::DartUtils::ReadFile,
      dart::bin::DartUtils::WriteFile, dart::bin::DartUtils::CloseFile,
      nullptr /* entropy_source */, nullptr /* get_service_assets */,
      start_kernel_isolate);
  if (error != nullptr) {
    bin::Log::PrintErr("Failed to initialize VM: %s\n", error);
    free(error);
    return 1;
  }

  // Apply the filter to all registered tests.
  TestCaseBase::RunAll();
  // Apply the filter to all registered benchmarks.
  Benchmark::RunAll(argv[0]);

  error = Dart::Cleanup();
  if (error != nullptr) {
    bin::Log::PrintErr("Failed shutdown VM: %s\n", error);
    free(error);
    return 1;
  }

  TestCaseBase::RunAllRaw();

  bin::EventHandler::Stop();

  // Print a warning message if no tests or benchmarks were matched.
  if (run_matches == 0) {
    bin::Log::PrintErr("No tests matched: %s\n", run_filter);
    return 1;
  }
  if (Expect::failed()) {
    return 255;
  }
  return 0;
}

}  // namespace dart

int main(int argc, const char** argv) {
  dart::bin::Platform::Exit(dart::Main(argc, argv));
}
