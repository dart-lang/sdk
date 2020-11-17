// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/unit_test.h"

#include "platform/syslog.h"
#include "vm/compiler/ffi/native_calling_convention.h"

namespace dart {
namespace compiler {
namespace ffi {

void RunSignatureTest(dart::Zone* zone,
                      const char* name,
                      const NativeTypes& argument_types,
                      const NativeType& return_type) {
  const auto& native_signature =
      *new (zone) NativeFunctionType(argument_types, return_type);

  const auto& native_calling_convention =
      NativeCallingConvention::FromSignature(zone, native_signature);

  const char* test_result =
      native_calling_convention.ToCString(zone, /*multi_line=*/true);

  const int kFilePathLength = 100;
  char expectation_file_path[kFilePathLength];
  Utils::SNPrint(expectation_file_path, kFilePathLength,
                 "runtime/vm/compiler/ffi/unit_tests/%s/%s_%s.expect", name,
                 kArch, kOs);

  if (TestCaseBase::update_expectations) {
    Syslog::Print("Updating %s\n", expectation_file_path);
    WriteToFile(expectation_file_path, test_result);
  }

  char* expectation_file_contents = nullptr;
  ReadFromFile(expectation_file_path, &expectation_file_contents);
  EXPECT_NOTNULL(expectation_file_contents);
  if (expectation_file_contents != nullptr) {
    EXPECT_STREQ(expectation_file_contents, test_result);
    free(expectation_file_contents);
  }
}

UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_int8x10) {
  const auto& int8type = *new (Z) NativePrimitiveType(kInt8);

  auto& arguments = *new (Z) NativeTypes(Z, 10);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);
  arguments.Add(&int8type);

  RunSignatureTest(Z, "int8x10", arguments, int8type);
}

UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_floatx10) {
  const auto& floatType = *new (Z) NativePrimitiveType(kFloat);

  auto& arguments = *new (Z) NativeTypes(Z, 10);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);
  arguments.Add(&floatType);

  RunSignatureTest(Z, "floatx10", arguments, floatType);
}

}  // namespace ffi
}  // namespace compiler
}  // namespace dart
