// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A slimmed down version of runtime/vm/unit_test.h that only runs C++
// non-DartVM unit tests.

#ifndef RUNTIME_VM_COMPILER_FFI_UNIT_TEST_H_
#define RUNTIME_VM_COMPILER_FFI_UNIT_TEST_H_

// Don't use the DartVM zone, so include this first.
#include "vm/compiler/ffi/unit_test_custom_zone.h"

#include "platform/globals.h"

// The UNIT_TEST_CASE macro is used for tests.
#define UNIT_TEST_CASE_WITH_EXPECTATION(name, expectation)                     \
  void Dart_Test##name();                                                      \
  static const dart::compiler::ffi::RawTestCase kRegister##name(               \
      Dart_Test##name, #name, expectation);                                    \
  void Dart_Test##name()

#define UNIT_TEST_CASE(name) UNIT_TEST_CASE_WITH_EXPECTATION(name, "Pass")

// The UNIT_TEST_CASE_WITH_ZONE macro is used for tests that need a custom
// dart::Zone.
#define UNIT_TEST_CASE_WITH_ZONE_WITH_EXPECTATION(name, expectation)           \
  static void Dart_TestHelper##name(dart::Zone* Z);                            \
  UNIT_TEST_CASE_WITH_EXPECTATION(name, expectation) {                         \
    dart::Zone zone;                                                           \
    Dart_TestHelper##name(&zone);                                              \
  }                                                                            \
  static void Dart_TestHelper##name(dart::Zone* Z)

#define UNIT_TEST_CASE_WITH_ZONE(name)                                         \
  UNIT_TEST_CASE_WITH_ZONE_WITH_EXPECTATION(name, "Pass")

namespace dart {
namespace compiler {
namespace ffi {

extern const char* kArch;
extern const char* kOs;

void WriteToFile(char* path, const char* contents);

void ReadFromFile(char* path, char** buffer_pointer);

class TestCaseBase {
 public:
  explicit TestCaseBase(const char* name, const char* expectation);
  virtual ~TestCaseBase() {}

  const char* name() const { return name_; }
  const char* expectation() const { return expectation_; }

  virtual void Run() = 0;
  void RunTest();

  static void RunAll();
  static void RunAllRaw();

  static bool update_expectations;

 private:
  static TestCaseBase* first_;
  static TestCaseBase* tail_;

  TestCaseBase* next_;
  const char* name_;
  const char* expectation_;

  DISALLOW_COPY_AND_ASSIGN(TestCaseBase);
};

class RawTestCase : TestCaseBase {
 public:
  typedef void(RunEntry)();

  RawTestCase(RunEntry* run, const char* name, const char* expectation)
      : TestCaseBase(name, expectation), run_(run) {}
  virtual void Run();

 private:
  RunEntry* const run_;
};

}  // namespace ffi
}  // namespace compiler
}  // namespace dart

#endif  // RUNTIME_VM_COMPILER_FFI_UNIT_TEST_H_
