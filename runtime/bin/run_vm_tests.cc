// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "bin/file.h"

#include "vm/benchmark_test.h"
#include "vm/dart.h"
#include "bin/dartutils.h"
#include "vm/unit_test.h"


// TODO(iposva, asiva): This is a placeholder for the real unittest framework.
namespace dart {

// Only run tests that match the filter string. The default does not match any
// tests.
static const char* const kNone = "No Test or Benchmarks";
static const char* const kList = "List all Tests and Benchmarks";
static const char* const kAllBenchmarks = "All Benchmarks";
static const char* run_filter = kNone;

static int run_matches = 0;


void TestCase::Run() {
  fprintf(stdout, "Running test: %s\n", name());
  (*run_)();
  fprintf(stdout, "Done: %s\n", name());
}


void TestCaseBase::RunTest() {
  if (strcmp(run_filter, this->name()) == 0) {
    this->Run();
    run_matches++;
  } else if (run_filter == kList) {
    fprintf(stdout, "%s\n", this->name());
    run_matches++;
  }
}


void Benchmark::RunBenchmark() {
  if ((run_filter == kAllBenchmarks) ||
      (strcmp(run_filter, this->name()) == 0)) {
    this->Run();
    OS::Print("%s(%s): %" Pd "\n",
              this->name(), this->score_kind(), this->score());
    run_matches++;
  } else if (run_filter == kList) {
    fprintf(stdout, "%s\n", this->name());
    run_matches++;
  }
}


static void PrintUsage() {
  fprintf(stderr, "run_vm_tests [--list | --benchmarks | "
                  "<test name> | <benchmark name>]\n");
  fprintf(stderr, "run_vm_tests [vm-flags ...] <test name>\n");
  fprintf(stderr, "run_vm_tests [vm-flags ...] <benchmark name>\n");
}


static int Main(int argc, const char** argv) {
  // Flags being passed to the Dart VM.
  int dart_argc = 0;
  const char** dart_argv = NULL;

  if (argc < 2) {
    // Bad parameter count.
    PrintUsage();
    return 1;
  } else if (argc == 2) {
    if (strcmp(argv[1], "--list") == 0) {
      run_filter = kList;
      // List all tests and benchmarks and exit without initializing the VM.
      TestCaseBase::RunAll();
      Benchmark::RunAll(argv[0]);
      return 0;
    } else if (strcmp(argv[1], "--benchmarks") == 0) {
      run_filter = kAllBenchmarks;
    } else {
      run_filter = argv[1];
    }
  } else {
    // Last argument is the test name, the rest are vm flags.
    run_filter = argv[argc - 1];
    // Remove the first value (executable) from the arguments and
    // exclude the last argument which is the test name.
    dart_argc = argc - 2;
    dart_argv = &argv[1];
  }
  bool set_vm_flags_success = Flags::ProcessCommandLineFlags(dart_argc,
                                                             dart_argv);
  ASSERT(set_vm_flags_success);
  const char* err_msg = Dart::InitOnce(NULL, NULL, NULL, NULL,
                                       dart::bin::DartUtils::OpenFile,
                                       dart::bin::DartUtils::ReadFile,
                                       dart::bin::DartUtils::WriteFile,
                                       dart::bin::DartUtils::CloseFile,
                                       NULL,
                                       NULL);
  ASSERT(err_msg == NULL);
  // Apply the filter to all registered tests.
  TestCaseBase::RunAll();
  // Apply the filter to all registered benchmarks.
  Benchmark::RunAll(argv[0]);
  // Print a warning message if no tests or benchmarks were matched.
  if (run_matches == 0) {
    fprintf(stderr, "No tests matched: %s\n", run_filter);
    return 1;
  }
  return 0;
}

}  // namespace dart


int main(int argc, const char** argv) {
  return dart::Main(argc, argv);
}
