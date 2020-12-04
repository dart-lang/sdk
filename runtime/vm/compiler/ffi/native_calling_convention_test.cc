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

// Test with 3-byte struct.
//
// On ia32, result pointer is passed on stack and passed back in eax.
//
// On x64, is passed and returned in registers, except for on Windows where it
// is passed on stack because of its size not being a power of two.
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_struct3bytesx10) {
  const auto& int8type = *new (Z) NativePrimitiveType(kInt8);

  auto& member_types = *new (Z) NativeTypes(Z, 3);
  member_types.Add(&int8type);
  member_types.Add(&int8type);
  member_types.Add(&int8type);
  const auto& struct_type =
      NativeCompoundType::FromNativeTypes(Z, member_types);

  auto& arguments = *new (Z) NativeTypes(Z, 10);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);

  RunSignatureTest(Z, "struct3bytesx10", arguments, struct_type);
}

// Test with homogenous struct.
//
// On arm softfp, the return pointer is passed in the first int register, and
// the first struct is passed in the next 3 registers and 1 stack slot.
//
// On arm hardfp, arm64, and x64 non-Windows the structs are passed in FPU
// registers until exhausted, the rest is passed on the stack, and struct is
// returned in FPU registers.
//
// On ia32 a return pointer and all arguments are passed on the stack.
//
// On x64 on Windows the structs are passed by pointer and pointer to the
// return value is passed in.
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_struct16bytesHomogenousx10) {
  const auto& float_type = *new (Z) NativePrimitiveType(kFloat);
  const auto& int8type = *new (Z) NativePrimitiveType(kInt8);

  // If passed in FPU registers, uses an even amount of them.
  auto& member_types = *new (Z) NativeTypes(Z, 4);
  member_types.Add(&float_type);
  member_types.Add(&float_type);
  member_types.Add(&float_type);
  member_types.Add(&float_type);
  const auto& struct_type =
      NativeCompoundType::FromNativeTypes(Z, member_types);

  auto& arguments = *new (Z) NativeTypes(Z, 13);
  arguments.Add(&struct_type);
  arguments.Add(&float_type);  // Claim a single FPU register.
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&float_type);   // Check float register back filling, if any.
  arguments.Add(&int8type);     // Check integer register back filling, if any.
  arguments.Add(&struct_type);  // Check stack alignment of struct.

  RunSignatureTest(Z, "struct16bytesHomogenousx10", arguments, struct_type);
}

// A fairly big struct.
//
// On arm, split up in 8-byte chunks. The first chunk goes into two registers,
// the rest on the stack. Note that r1 goes unused and is not backfilled.
//
// On arm64 and Windows x64 passed by a pointer to copy.
//
// On ia32, wholly passed on stack.
//
// On non-Windows x64, wholly passed on stack, and the integer argument
// backfills a still unoccupied integer register.
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_struct128bytesx1) {
  const auto& int32_type = *new (Z) NativePrimitiveType(kInt32);
  const auto& int64_type = *new (Z) NativePrimitiveType(kInt64);

  auto& member_types = *new (Z) NativeTypes(Z, 16);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  member_types.Add(&int64_type);
  const auto& struct_type =
      NativeCompoundType::FromNativeTypes(Z, member_types);

  auto& arguments = *new (Z) NativeTypes(Z, 2);
  arguments.Add(&struct_type);
  arguments.Add(&int32_type);  // Check integer register backfilling, if any.

  RunSignatureTest(Z, "struct128bytesx1", arguments, struct_type);
}

#if defined(TARGET_ARCH_X64)
// On x64 non-Windows a struct can be spread over an FPU and int register.
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_struct16bytesMixedx10) {
  const auto& float_type = *new (Z) NativePrimitiveType(kFloat);
  const auto& int32_type = *new (Z) NativePrimitiveType(kInt32);

  auto& member_types = *new (Z) NativeTypes(Z, 4);
  member_types.Add(&float_type);
  member_types.Add(&float_type);
  member_types.Add(&int32_type);
  member_types.Add(&int32_type);
  const auto& struct_type =
      NativeCompoundType::FromNativeTypes(Z, member_types);

  auto& arguments = *new (Z) NativeTypes(Z, 11);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);  // Integer registers exhausted, on stack.
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&float_type);  // Use remaining FPU register.

  RunSignatureTest(Z, "struct16bytesMixedx10", arguments, struct_type);
}

// On x64 non-Windows a struct can be spread over an FPU and int register.
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_struct16bytesMixedx10_2) {
  const auto& float_type = *new (Z) NativePrimitiveType(kFloat);
  const auto& int32_type = *new (Z) NativePrimitiveType(kInt32);

  auto& member_types = *new (Z) NativeTypes(Z, 4);
  member_types.Add(&float_type);
  member_types.Add(&float_type);
  member_types.Add(&int32_type);
  member_types.Add(&int32_type);
  const auto& struct_type =
      NativeCompoundType::FromNativeTypes(Z, member_types);

  auto& arguments = *new (Z) NativeTypes(Z, 15);
  arguments.Add(&float_type);
  arguments.Add(&float_type);
  arguments.Add(&float_type);
  arguments.Add(&float_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);  // FPU registers exhausted, on stack.
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&int32_type);  // Use remaining integer register.

  RunSignatureTest(Z, "struct16bytesMixedx10_2", arguments, struct_type);
}
#endif  // defined(TARGET_ARCH_X64)

// On ia32 Windows a struct can be returned in registers, on non-Windows not.
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_struct8bytesx1) {
  const auto& int8type = *new (Z) NativePrimitiveType(kInt8);

  auto& member_types = *new (Z) NativeTypes(Z, 4);
  member_types.Add(&int8type);
  member_types.Add(&int8type);
  member_types.Add(&int8type);
  member_types.Add(&int8type);
  member_types.Add(&int8type);
  member_types.Add(&int8type);
  member_types.Add(&int8type);
  member_types.Add(&int8type);
  const auto& struct_type =
      NativeCompoundType::FromNativeTypes(Z, member_types);

  auto& arguments = *new (Z) NativeTypes(Z, 1);
  arguments.Add(&struct_type);

  RunSignatureTest(Z, "struct8bytesx1", arguments, struct_type);
}

}  // namespace ffi
}  // namespace compiler
}  // namespace dart
