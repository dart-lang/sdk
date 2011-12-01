// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>

#include "vm/dart.h"
#include "vm/unit_test.h"

// TODO(iposva, asiva): This is a placeholder for the real unittest framework.
namespace dart {

// Only run tests that match the filter string. The default does not match any
// tests.
static const char* const kNoTests = "No Test";
static const char* const kAllTests = "All Tests";
static const char* const kListTests = "List Tests";
static const char* test_filter = kNoTests;

static int test_matches = 0;


void TestCase::Run() {
  fprintf(stdout, "Running test: %s\n", name());
  (*run_)();
  fprintf(stdout, "Done: %s\n", name());
}


void TestCaseBase::RunTest() {
  if ((test_filter == kAllTests) || (strcmp(test_filter, this->name()) == 0)) {
    this->Run();
    test_matches++;
  } else if (test_filter == kListTests) {
    fprintf(stdout, "%s\n", this->name());
    test_matches++;
  }
}


static void PrintUsage() {
  fprintf(stderr, "run_vm_tests [--list | --all | <test name>]\n");
  fprintf(stderr, "run_vm_tests  <test name> [vm-flags ...]\n");
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
      test_filter = kListTests;
      // List all the tests and exit without initializing the VM at all.
      TestCaseBase::RunAll();
      return 0;
    } else if (strcmp(argv[1], "--all") == 0) {
      test_filter = kAllTests;
    } else {
      test_filter = argv[1];
    }
  } else {
    // First argument is the test name, the rest are vm flags.
    test_filter = argv[1];
    // Remove the first two values from the arguments.
    dart_argc = argc - 2;
    dart_argv = &argv[2];
  }
  bool init_success = Dart::InitOnce(dart_argc, dart_argv, NULL);
  ASSERT(init_success);
  // Apply the test filter to all registered tests.
  TestCaseBase::RunAll();
  // Print a warning message if no tests were matched.
  if (test_matches == 0) {
    fprintf(stderr, "No tests matched: %s\n", test_filter);
    return 1;
  }
  return 0;
}

}  // namespace dart


int main(int argc, const char** argv) {
  return dart::Main(argc, argv);
}
