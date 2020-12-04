// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A slimmed down version of bin/run_vm_tests.cc that only runs C++ non-DartVM
// unit tests.
//
// By slimming it down to non-VM, we can run with the defines for all target
// architectures and operating systems.

#include "vm/compiler/ffi/unit_test.h"

#include "platform/assert.h"
#include "platform/syslog.h"

namespace dart {
namespace compiler {
namespace ffi {

static const char* const kNone = "No Test";
static const char* const kList = "List all Tests";
static const char* const kAll = "Run all Tests";
static const char* run_filter = kNone;

static const char* kCommandAll = "--all";
static const char* kCommandList = "--list";
static const char* kCommandUpdate = "--update";

static int run_matches = 0;

TestCaseBase* TestCaseBase::first_ = nullptr;
TestCaseBase* TestCaseBase::tail_ = nullptr;
bool TestCaseBase::update_expectations = false;

TestCaseBase::TestCaseBase(const char* name, const char* expectation)
    : next_(nullptr), name_(name), expectation_(expectation) {
  ASSERT(strlen(expectation) > 0);
  if (first_ == nullptr) {
    first_ = this;
  } else {
    tail_->next_ = this;
  }
  tail_ = this;
}

void TestCaseBase::RunAll() {
  TestCaseBase* test = first_;
  while (test != nullptr) {
    test->RunTest();
    test = test->next_;
  }
}

void TestCaseBase::RunTest() {
  if (run_filter == kList) {
    Syslog::Print("%s %s\n", this->name(), this->expectation());
    run_matches++;
  } else if (run_filter == kAll) {
    this->Run();
    run_matches++;
  } else if (strcmp(run_filter, this->name()) == 0) {
    this->Run();
    run_matches++;
  }
}

void RawTestCase::Run() {
  Syslog::Print("Running test: %s\n", name());
  (*run_)();
  Syslog::Print("Done: %s\n", name());
}

static int Main(int argc, const char** argv) {
  if (argc == 2 && strcmp(argv[1], kCommandList) == 0) {
    run_filter = kList;
    // List all tests and benchmarks and exit.
    TestCaseBase::RunAll();
    fflush(stdout);
    return 0;
  }
  if (argc > 1 && strcmp(argv[1], kCommandUpdate) == 0) {
    TestCaseBase::update_expectations = true;
  }
  if (strcmp(argv[argc - 1], kCommandAll) == 0) {
    // Run all tests.
    run_filter = kAll;
  } else if (argc > 1) {
    // Run only test with specific name.
    run_filter = argv[argc - 1];
  }

  TestCaseBase::RunAll();

  // Print a warning message if no tests or benchmarks were matched.
  if (run_matches == 0) {
    Syslog::PrintErr("No tests matched: %s\n", run_filter);
    return 1;
  }
  if (Expect::failed()) {
    Syslog::PrintErr(
        "Some tests failed. Run the following command to update "
        "expectations.\ntools/test.py --vm-options=--update ffi_unit");
    return 255;
  }

  return 0;
}

}  // namespace ffi
}  // namespace compiler
}  // namespace dart

int main(int argc, const char** argv) {
  return dart::compiler::ffi::Main(argc, argv);
}
