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
#include "bin/process.h"
#include "bin/snapshot_utils.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/vmservice_impl.h"
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

// Snapshot pieces when we link in a snapshot.
const uint8_t* bin::vm_snapshot_data = kDartVmSnapshotData;
const uint8_t* bin::vm_snapshot_instructions = kDartVmSnapshotInstructions;
const uint8_t* bin::core_isolate_snapshot_data = kDartCoreIsolateSnapshotData;
const uint8_t* bin::core_isolate_snapshot_instructions =
    kDartCoreIsolateSnapshotInstructions;

// Only run tests that match the filter string. The default does not match any
// tests.
static const char* const kNone = "No Test or Benchmarks";
static const char* const kList = "List all Tests and Benchmarks";
static const char* const kAllBenchmarks = "All Benchmarks";
static const char* run_filter = kNone;
static const char* kernel_snapshot = nullptr;

static int run_matches = 0;

void TestCase::Run() {
  Syslog::Print("Running test: %s\n", name());
  (*run_)();
  Syslog::Print("Done: %s\n", name());
}

void RawTestCase::Run() {
  Syslog::Print("Running raw test: %s\n", name());
  (*run_)();
  Syslog::Print("Done: %s\n", name());
}

void TestCaseBase::RunTest() {
  if (strcmp(run_filter, this->name()) == 0) {
    this->Run();
    run_matches++;
  } else if (run_filter == kList) {
    Syslog::Print("%s %s\n", this->name(), this->expectation());
    run_matches++;
  }
}

void Benchmark::RunBenchmark() {
  if ((run_filter == kAllBenchmarks) ||
      (strcmp(run_filter, this->name()) == 0)) {
    this->Run();
    Syslog::Print("%s(%s): %" Pd64 "\n", this->name(), this->score_kind(),
                  this->score());
    run_matches++;
  } else if (run_filter == kList) {
    Syslog::Print("%s Pass\n", this->name());
    run_matches++;
  }
}

static void PrintUsage() {
  Syslog::PrintErr(
      "Usage: one of the following\n"
      "  run_vm_tests --list\n"
      "  run_vm_tests [--dfe=<snapshot file name>] --benchmarks\n"
      "  run_vm_tests [--dfe=<snapshot file name>] [vm-flags ...] <test name>\n"
      "  run_vm_tests [--dfe=<snapshot file name>] [vm-flags ...] <benchmark "
      "name>\n");
}

#define CHECK_RESULT(result)                                                   \
  if (Dart_IsError(result)) {                                                  \
    *error = Utils::StrDup(Dart_GetError(result));                             \
    Dart_ExitScope();                                                          \
    Dart_ShutdownIsolate();                                                    \
    return nullptr;                                                            \
  }

static Dart_Isolate CreateAndSetupServiceIsolate(const char* script_uri,
                                                 const char* packages_config,
                                                 Dart_IsolateFlags* flags,
                                                 char** error) {
  // We only enable the vm-service for this particular test.
  // The vm-service seems to have some shutdown race which would cause other
  // vm/cc tests to randomly time out due to inability to shut service-isolate
  // down.
  // Issue(https://dartbug.com/37741):
  if (strcmp(run_filter, "DartAPI_InvokeVMServiceMethod") != 0) {
    return nullptr;
  }

  ASSERT(script_uri != nullptr);
  Dart_Isolate isolate = nullptr;
  auto isolate_group_data = new bin::IsolateGroupData(
      script_uri, packages_config, /*app_snapshot=*/nullptr,
      /*isolate_run_app_snapshot=*/false);

  const uint8_t* kernel_buffer = nullptr;
  intptr_t kernel_buffer_size = 0;

  bin::dfe.Init();
  bin::dfe.LoadPlatform(&kernel_buffer, &kernel_buffer_size);
  RELEASE_ASSERT(kernel_buffer != nullptr);

  flags->load_vmservice_library = true;
  isolate_group_data->SetKernelBufferUnowned(
      const_cast<uint8_t*>(kernel_buffer), kernel_buffer_size);
  isolate = Dart_CreateIsolateGroupFromKernel(
      script_uri, DART_VM_SERVICE_ISOLATE_NAME, kernel_buffer,
      kernel_buffer_size, flags, isolate_group_data, /*isolate_data=*/nullptr,
      error);
  if (isolate == nullptr) {
    delete isolate_group_data;
    return nullptr;
  }

  Dart_EnterScope();

  Dart_Handle result =
      Dart_SetLibraryTagHandler(bin::Loader::LibraryTagHandler);
  CHECK_RESULT(result);

  // Load embedder specific bits and return.
  if (!bin::VmService::Setup("127.0.0.1", 0,
                             /*dev_mode=*/false, /*auth_disabled=*/true,
                             /*write_service_info_filename*/ "",
                             /*trace_loading=*/false, /*deterministic=*/true,
                             /*enable_service_port_fallback=*/false,
                             /*wait_for_dds_to_advertise_service*/ false)) {
    *error = Utils::StrDup(bin::VmService::GetErrorMessage());
    return nullptr;
  }
  result = Dart_SetEnvironmentCallback(bin::DartUtils::EnvironmentCallback);
  CHECK_RESULT(result);
  Dart_ExitScope();
  Dart_ExitIsolate();
  return isolate;
}

static Dart_Isolate CreateIsolateAndSetup(const char* script_uri,
                                          const char* main,
                                          const char* package_root,
                                          const char* packages_config,
                                          Dart_IsolateFlags* flags,
                                          void* data,
                                          char** error) {
  ASSERT(script_uri != nullptr);
  ASSERT(package_root == nullptr);
  if (strcmp(script_uri, DART_VM_SERVICE_ISOLATE_NAME) == 0) {
    return CreateAndSetupServiceIsolate(script_uri, packages_config, flags,
                                        error);
  }
  const bool is_kernel_isolate =
      strcmp(script_uri, DART_KERNEL_ISOLATE_NAME) == 0;
  if (!is_kernel_isolate) {
    *error = Utils::StrDup(
        "Spawning of only Kernel isolate is supported in run_vm_tests.");
    return nullptr;
  }
  Dart_Isolate isolate = nullptr;
  bin::IsolateGroupData* isolate_group_data = nullptr;
  const uint8_t* kernel_service_buffer = nullptr;
  intptr_t kernel_service_buffer_size = 0;

  // Kernel isolate uses an app snapshot or the kernel service dill file.
  if (kernel_snapshot != nullptr &&
      (bin::DartUtils::SniffForMagicNumber(kernel_snapshot) ==
       bin::DartUtils::kAppJITMagicNumber)) {
    script_uri = kernel_snapshot;
    bin::AppSnapshot* app_snapshot =
        bin::Snapshot::TryReadAppSnapshot(script_uri);
    ASSERT(app_snapshot != nullptr);
    const uint8_t* ignore_vm_snapshot_data;
    const uint8_t* ignore_vm_snapshot_instructions;
    const uint8_t* isolate_snapshot_data;
    const uint8_t* isolate_snapshot_instructions;
    app_snapshot->SetBuffers(
        &ignore_vm_snapshot_data, &ignore_vm_snapshot_instructions,
        &isolate_snapshot_data, &isolate_snapshot_instructions);
    isolate_group_data = new bin::IsolateGroupData(
        script_uri, packages_config, app_snapshot, app_snapshot != nullptr);
    isolate = Dart_CreateIsolateGroup(
        DART_KERNEL_ISOLATE_NAME, DART_KERNEL_ISOLATE_NAME,
        isolate_snapshot_data, isolate_snapshot_instructions, flags,
        isolate_group_data, /*isolate_data=*/nullptr, error);
    if (*error != nullptr) {
      OS::PrintErr("Error creating isolate group: %s\n", *error);
      free(*error);
      *error = nullptr;
    }
    // If a test does not actually require the kernel isolate the main thead can
    // start calling Dart::Cleanup() while the kernel isolate is booting up.
    // This can cause the isolate to be killed early which will return `nullptr`
    // here.
    if (isolate == nullptr) {
      delete isolate_group_data;
      return nullptr;
    }
  }
  if (isolate == nullptr) {
    delete isolate_group_data;
    isolate_group_data = nullptr;

    bin::dfe.Init();
    bin::dfe.LoadKernelService(&kernel_service_buffer,
                               &kernel_service_buffer_size);
    ASSERT(kernel_service_buffer != nullptr);
    isolate_group_data =
        new bin::IsolateGroupData(script_uri, packages_config, nullptr, false);
    isolate_group_data->SetKernelBufferUnowned(
        const_cast<uint8_t*>(kernel_service_buffer),
        kernel_service_buffer_size);
    isolate = Dart_CreateIsolateGroupFromKernel(
        script_uri, main, kernel_service_buffer, kernel_service_buffer_size,
        flags, isolate_group_data, /*isolate_data=*/nullptr, error);
  }
  if (isolate == nullptr) {
    delete isolate_group_data;
    return nullptr;
  }

  Dart_EnterScope();

  bin::DartUtils::SetOriginalWorkingDirectory();
  Dart_Handle result = bin::DartUtils::PrepareForScriptLoading(
      /*is_service_isolate=*/false, /*trace_loading=*/false);
  CHECK_RESULT(result);

  // Setup kernel service as the main script for this isolate.
  if (kernel_service_buffer != nullptr) {
    result = Dart_LoadScriptFromKernel(kernel_service_buffer,
                                       kernel_service_buffer_size);
    CHECK_RESULT(result);
  }

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

static void CleanupIsolateGroup(void* callback_data) {
  bin::IsolateGroupData* isolate_data =
      reinterpret_cast<bin::IsolateGroupData*>(callback_data);
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
  const char** dart_argv = nullptr;

  // Perform platform specific initialization.
  if (!dart::bin::Platform::Initialize()) {
    Syslog::PrintErr("Initialization failed\n");
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
    if (delim == nullptr || strlen(delim + 1) == 0) {
      Syslog::PrintErr("Invalid value for the option: %s\n", argv[arg_pos]);
      PrintUsage();
      return 1;
    }
    kernel_snapshot = Utils::StrDup(delim + 1);
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
  bin::Process::Init();
  bin::EventHandler::Start();

  char* error = Flags::ProcessCommandLineFlags(dart_argc, dart_argv);
  if (error != nullptr) {
    Syslog::PrintErr("Failed to parse flags: %s\n", error);
    free(error);
    return 1;
  }

  TesterState::vm_snapshot_data = dart::bin::vm_snapshot_data;
  TesterState::create_callback = CreateIsolateAndSetup;
  TesterState::group_cleanup_callback = CleanupIsolateGroup;
  TesterState::argv = dart_argv;
  TesterState::argc = dart_argc;

  error = Dart::Init(
      dart::bin::vm_snapshot_data, dart::bin::vm_snapshot_instructions,
      /*create_group=*/CreateIsolateAndSetup,
      /*initialize_isolate=*/nullptr,
      /*shutdown_isolate=*/nullptr,
      /*cleanup_isolate=*/nullptr,
      /*cleanup_group=*/CleanupIsolateGroup,
      /*thread_exit=*/nullptr, dart::bin::DartUtils::OpenFile,
      dart::bin::DartUtils::ReadFile, dart::bin::DartUtils::WriteFile,
      dart::bin::DartUtils::CloseFile, /*entropy_source=*/nullptr,
      /*get_service_assets=*/nullptr, start_kernel_isolate,
      /*code_observer=*/nullptr);
  if (error != nullptr) {
    Syslog::PrintErr("Failed to initialize VM: %s\n", error);
    free(error);
    return 1;
  }

  // Apply the filter to all registered tests.
  TestCaseBase::RunAll();
  // Apply the filter to all registered benchmarks.
  Benchmark::RunAll(argv[0]);

  bin::Process::TerminateExitCodeHandler();
  error = Dart::Cleanup();
  if (error != nullptr) {
    Syslog::PrintErr("Failed shutdown VM: %s\n", error);
    free(error);
    return 1;
  }

  TestCaseBase::RunAllRaw();

  bin::EventHandler::Stop();
  bin::Process::Cleanup();

  // Print a warning message if no tests or benchmarks were matched.
  if (run_matches == 0) {
    Syslog::PrintErr("No tests matched: %s\n", run_filter);
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
