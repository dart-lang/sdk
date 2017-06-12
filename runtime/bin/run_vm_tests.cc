// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "bin/dartutils.h"
#include "bin/dfe.h"
#include "bin/file.h"
#include "bin/loader.h"
#include "bin/platform.h"
#include "bin/snapshot_utils.h"
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

namespace bin {
DFE dfe;
}

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
  OS::Print("Running test: %s\n", name());
  (*run_)();
  OS::Print("Done: %s\n", name());
}


void RawTestCase::Run() {
  OS::Print("Running test: %s\n", name());
  (*run_)();
  OS::Print("Done: %s\n", name());
}


void TestCaseBase::RunTest() {
  if (strcmp(run_filter, this->name()) == 0) {
    this->Run();
    run_matches++;
  } else if (run_filter == kList) {
    OS::Print("%s\n", this->name());
    run_matches++;
  }
}


void Benchmark::RunBenchmark() {
  if ((run_filter == kAllBenchmarks) ||
      (strcmp(run_filter, this->name()) == 0)) {
    this->Run();
    OS::Print("%s(%s): %" Pd64 "\n", this->name(), this->score_kind(),
              this->score());
    run_matches++;
  } else if (run_filter == kList) {
    OS::Print("%s\n", this->name());
    run_matches++;
  }
}


static void PrintUsage() {
  OS::PrintErr(
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
  if (kernel_snapshot == NULL) {
    *error =
        strdup("Kernel snapshot location has to be specified via --dfe option");
    return NULL;
  }
  script_uri = kernel_snapshot;

  bin::AppSnapshot* app_snapshot =
      bin::Snapshot::TryReadAppSnapshot(script_uri);
  if (app_snapshot == NULL) {
    *error = strdup("Failed to read kernel service app snapshot");
    return NULL;
  }

  const uint8_t* isolate_snapshot_data = bin::core_isolate_snapshot_data;
  const uint8_t* isolate_snapshot_instructions =
      bin::core_isolate_snapshot_instructions;

  const uint8_t* ignore_vm_snapshot_data;
  const uint8_t* ignore_vm_snapshot_instructions;
  app_snapshot->SetBuffers(
      &ignore_vm_snapshot_data, &ignore_vm_snapshot_instructions,
      &isolate_snapshot_data, &isolate_snapshot_instructions);

  bin::IsolateData* isolate_data = new bin::IsolateData(
      script_uri, package_root, packages_config, NULL /* app_snapshot */);
  Dart_Isolate isolate = Dart_CreateIsolate(
      script_uri, main, isolate_snapshot_data, isolate_snapshot_instructions,
      flags, isolate_data, error);
  if (isolate == NULL) {
    *error = strdup("Failed to create isolate");
    delete isolate_data;
    return NULL;
  }

  Dart_EnterScope();

  bin::DartUtils::SetOriginalWorkingDirectory();
  Dart_Handle result = bin::DartUtils::PrepareForScriptLoading(
      false /* is_service_isolate */, false /* trace_loading */);
  CHECK_RESULT(result);

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

static int Main(int argc, const char** argv) {
  // Flags being passed to the Dart VM.
  int dart_argc = 0;
  const char** dart_argv = NULL;

  // Perform platform specific initialization.
  if (!dart::bin::Platform::Initialize()) {
    OS::PrintErr("Initialization failed\n");
  }

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
  if (strstr(argv[arg_pos], "--dfe") == argv[arg_pos]) {
    const char* delim = strstr(argv[1], "=");
    if (delim == NULL || strlen(delim + 1) == 0) {
      OS::PrintErr("Invalid value for the option: %s\n", argv[1]);
      PrintUsage();
      return 1;
    }
    kernel_snapshot = strdup(delim + 1);
    // VM needs '--use-dart-frontend' option, which we will insert in place
    // of '--dfe' option.
    argv[arg_pos] = strdup("--use-dart-frontend");
    ++arg_pos;
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

  bool set_vm_flags_success =
      Flags::ProcessCommandLineFlags(dart_argc, dart_argv);
  ASSERT(set_vm_flags_success);
  const char* err_msg = Dart::InitOnce(
      dart::bin::vm_snapshot_data, dart::bin::vm_snapshot_instructions,
      CreateIsolateAndSetup /* create */, NULL /* shutdown */,
      NULL /* cleanup */, NULL /* thread_exit */,
      dart::bin::DartUtils::OpenFile, dart::bin::DartUtils::ReadFile,
      dart::bin::DartUtils::WriteFile, dart::bin::DartUtils::CloseFile,
      NULL /* entropy_source */, NULL /* get_service_assets */);

  ASSERT(err_msg == NULL);
  // Apply the filter to all registered tests.
  TestCaseBase::RunAll();
  // Apply the filter to all registered benchmarks.
  Benchmark::RunAll(argv[0]);

  err_msg = Dart::Cleanup();
  ASSERT(err_msg == NULL);

  TestCaseBase::RunAllRaw();
  // Print a warning message if no tests or benchmarks were matched.
  if (run_matches == 0) {
    OS::PrintErr("No tests matched: %s\n", run_filter);
    return 1;
  }
  if (DynamicAssertionHelper::failed()) {
    return 255;
  }
  return 0;
}

}  // namespace dart


int main(int argc, const char** argv) {
  dart::bin::Platform::Exit(dart::Main(argc, argv));
}
