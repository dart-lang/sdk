// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/unit_test.h"

#include "platform/syslog.h"
#include "vm/compiler/ffi/native_calling_convention.h"

namespace dart {
namespace compiler {
namespace ffi {

const NativeCallingConvention& RunSignatureTest(
    dart::Zone* zone,
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

  return native_calling_convention;
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

UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_floatx20) {
  const auto& floatType = *new (Z) NativePrimitiveType(kFloat);

  auto& arguments = *new (Z) NativeTypes(Z, 20);
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

  RunSignatureTest(Z, "floatx20", arguments, floatType);
}

UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_doublex20) {
  const auto& doubleType = *new (Z) NativePrimitiveType(kDouble);

  auto& arguments = *new (Z) NativeTypes(Z, 20);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);
  arguments.Add(&doubleType);

  RunSignatureTest(Z, "doublex20", arguments, doubleType);
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
  const auto& struct_type = NativeStructType::FromNativeTypes(Z, member_types);

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
  const auto& struct_type = NativeStructType::FromNativeTypes(Z, member_types);

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

// Test with homogenous struct (2).
//
// This time with nested structs and inline arrays.
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_struct16bytesHomogenousx10_2) {
  const auto& float_type = *new (Z) NativePrimitiveType(kFloat);
  const auto& int8type = *new (Z) NativePrimitiveType(kInt8);

  const auto& float_1_array_type = *new (Z) NativeArrayType(float_type, 1);

  const auto& float_2_array_type = *new (Z) NativeArrayType(float_type, 2);
  auto& full_float_member_types = *new (Z) NativeTypes(Z, 1);
  full_float_member_types.Add(&float_2_array_type);
  const auto& float_array_struct_type =
      NativeStructType::FromNativeTypes(Z, full_float_member_types);

  auto& member_types = *new (Z) NativeTypes(Z, 3);
  member_types.Add(&float_1_array_type);
  member_types.Add(&float_array_struct_type);
  member_types.Add(&float_type);
  const auto& struct_type = NativeStructType::FromNativeTypes(Z, member_types);

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

  // Identical expectation files as previous test, struct contains the same
  // members, but nested in arrays and nested structs.
  RunSignatureTest(Z, "struct16bytesHomogenousx10", arguments, struct_type);
}

// Test with homogenous union.
//
// Even though the number of floats nested is different, this is still laid
// out as a homogeneous aggregate in arm64 and arm hardfp.
//
// Even though the member sizes are different, these unions are still passed in
// xmm registers on Linux/MacOS x64.
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_union16bytesHomogenousx10) {
  const auto& float_type = *new (Z) NativePrimitiveType(kFloat);
  const auto& int8type = *new (Z) NativePrimitiveType(kInt8);

  const auto& float_array_type = *new (Z) NativeArrayType(float_type, 3);

  auto& struct_member_types = *new (Z) NativeTypes(Z, 4);
  struct_member_types.Add(&float_type);
  struct_member_types.Add(&float_type);
  struct_member_types.Add(&float_type);
  struct_member_types.Add(&float_type);
  const auto& struct_type =
      NativeStructType::FromNativeTypes(Z, struct_member_types);

  auto& member_types = *new (Z) NativeTypes(Z, 2);
  member_types.Add(&float_array_type);
  member_types.Add(&struct_type);
  const auto& union_type = NativeUnionType::FromNativeTypes(Z, member_types);

  EXPECT_EQ(16, union_type.SizeInBytes());
  EXPECT(union_type.ContainsHomogenuousFloats());

  auto& arguments = *new (Z) NativeTypes(Z, 13);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&int8type);    // Check integer register back filling, if any.
  arguments.Add(&union_type);  // Check stack alignment of struct.

  // Identical expectation files as previous test, struct contains the same
  // members, but nested in arrays and nested structs.
  RunSignatureTest(Z, "union16bytesHomogenousx10", arguments, union_type);
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
  const auto& struct_type = NativeStructType::FromNativeTypes(Z, member_types);

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
  const auto& struct_type = NativeStructType::FromNativeTypes(Z, member_types);

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
  const auto& struct_type = NativeStructType::FromNativeTypes(Z, member_types);

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

// On x64 non-Windows a struct can be spread over an FPU and int register.
//
// This behavior also happens with nested structs and inline arrays.
//
// typedef struct  {
//   int32_t a0;
//   float a1;
// } HalfFloat;
//
// typedef struct  {
//   float a1[1];
// } FullFloat;
//
// typedef struct  {
//   int32_t a0;
//   HalfFloat a1;
//   FullFloat a2;
// } HalfFloat2;
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_struct16bytesMixedx10_3) {
  const auto& float_type = *new (Z) NativePrimitiveType(kFloat);
  const auto& int32_type = *new (Z) NativePrimitiveType(kInt32);

  auto& half_float_member_types = *new (Z) NativeTypes(Z, 2);
  half_float_member_types.Add(&int32_type);
  half_float_member_types.Add(&float_type);
  const auto& half_float_type =
      NativeStructType::FromNativeTypes(Z, half_float_member_types);

  const auto& float_array_type = *new (Z) NativeArrayType(float_type, 1);
  auto& full_float_member_types = *new (Z) NativeTypes(Z, 1);
  full_float_member_types.Add(&float_array_type);
  const auto& full_float_type =
      NativeStructType::FromNativeTypes(Z, full_float_member_types);

  auto& member_types = *new (Z) NativeTypes(Z, 3);
  member_types.Add(&int32_type);
  member_types.Add(&half_float_type);
  member_types.Add(&full_float_type);
  const auto& struct_type = NativeStructType::FromNativeTypes(Z, member_types);

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

  RunSignatureTest(Z, "struct16bytesMixedx10_3", arguments, struct_type);
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
  const auto& struct_type = NativeStructType::FromNativeTypes(Z, member_types);

  auto& arguments = *new (Z) NativeTypes(Z, 1);
  arguments.Add(&struct_type);

  RunSignatureTest(Z, "struct8bytesx1", arguments, struct_type);
}

// The struct is only 8 bytes with packing enabled.
//
// Many calling conventions pass this struct in single registers or less
// stack slots because of this.
//
// Non-windows x64 passes this struct on the stack instead of in a single
// CPU register, because it contains a mis-aligned member.
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_struct8bytesPackedx10) {
  const auto& int8_type = *new (Z) NativePrimitiveType(kInt8);
  const auto& int32_type = *new (Z) NativePrimitiveType(kInt32);

  auto& member_types = *new (Z) NativeTypes(Z, 5);
  member_types.Add(&int8_type);
  member_types.Add(&int32_type);
  member_types.Add(&int8_type);
  member_types.Add(&int8_type);
  member_types.Add(&int8_type);
  const auto& struct_type =
      NativeStructType::FromNativeTypes(Z, member_types, /*packing=*/1);
  EXPECT_EQ(8, struct_type.SizeInBytes());
  EXPECT(struct_type.ContainsUnalignedMembers());

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

  RunSignatureTest(Z, "struct8bytesPackedx10", arguments, struct_type);
}

// Without packing, this would be a 16 byte struct. However, because of packing
// it's 9 bytes.
//
// #pragma pack(push,1)
// typedef struct  {
//   int8_t a0;
//   double a1
// } StructPacked;
// #pragma pack(pop)
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_structPacked) {
  const auto& int8_type = *new (Z) NativePrimitiveType(kInt8);
  const auto& int32_type = *new (Z) NativePrimitiveType(kInt32);
  const auto& double_type = *new (Z) NativePrimitiveType(kDouble);

  auto& member_types = *new (Z) NativeTypes(Z, 2);
  member_types.Add(&int8_type);
  member_types.Add(&double_type);
  const auto& struct_type =
      NativeStructType::FromNativeTypes(Z, member_types, /*packing=*/1);
  EXPECT_EQ(9, struct_type.SizeInBytes());
  EXPECT(struct_type.ContainsUnalignedMembers());

  auto& arguments = *new (Z) NativeTypes(Z, 13);
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
  arguments.Add(&double_type);  // Backfilling float registers.
  arguments.Add(&int32_type);   // Backfilling int registers.
  arguments.Add(&int32_type);   // Backfilling int registers.

  RunSignatureTest(Z, "structPacked", arguments, double_type);
}

// The union is only 5 bytes because it's members are packed.
//
// Many calling conventions pass this struct in single registers or less
// stack slots because of this.
//
// Non-windows x64 passes this struct on the stack instead of in a single
// CPU register, because it contains a mis-aligned member.
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_union5bytesPackedx10) {
  const auto& uint8_type = *new (Z) NativePrimitiveType(kUint8);
  const auto& uint32_type = *new (Z) NativePrimitiveType(kUint32);

  auto& inner_members = *new (Z) NativeTypes(Z, 2);
  inner_members.Add(&uint8_type);
  inner_members.Add(&uint32_type);
  const intptr_t packing = 1;
  const auto& struct_type =
      NativeStructType::FromNativeTypes(Z, inner_members, packing);

  const auto& array_type = *new (Z) NativeArrayType(uint8_type, 5);

  auto& member_types = *new (Z) NativeTypes(Z, 2);
  member_types.Add(&array_type);
  member_types.Add(&struct_type);
  const auto& union_type = NativeUnionType::FromNativeTypes(Z, member_types);

  EXPECT_EQ(5, union_type.SizeInBytes());
  EXPECT_EQ(1, union_type.AlignmentInBytesField());

  auto& arguments = *new (Z) NativeTypes(Z, 10);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);
  arguments.Add(&union_type);

  RunSignatureTest(Z, "union5bytesPackedx10", arguments, union_type);
}

// http://dartbug.com/46127
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_regress46127) {
  const auto& uint64_type = *new (Z) NativePrimitiveType(kUint64);

  auto& member_types = *new (Z) NativeTypes(Z, 1);
  member_types.Add(&uint64_type);
  const auto& struct_type = NativeStructType::FromNativeTypes(Z, member_types);

  EXPECT_EQ(8, struct_type.SizeInBytes());

  auto& arguments = *new (Z) NativeTypes(Z, 0);

  const auto& native_calling_convention =
      RunSignatureTest(Z, "regress46127", arguments, struct_type);

#if defined(TARGET_ARCH_IA32) &&                                               \
    (defined(DART_TARGET_OS_ANDROID) || defined(DART_TARGET_OS_LINUX))
  // We must count the result pointer passed on the stack as well.
  EXPECT_EQ(4, native_calling_convention.StackTopInBytes());
#else
  EXPECT_EQ(0, native_calling_convention.StackTopInBytes());
#endif
}

// MacOS arm64 alignment of 12-byte homogenous float structs.
//
// http://dartbug.com/46305
//
// See the *.expect in ./unit_tests for this behavior.
UNIT_TEST_CASE_WITH_ZONE(NativeCallingConvention_struct12bytesFloatx6) {
  const auto& float_type = *new (Z) NativePrimitiveType(kFloat);
  const auto& int64_type = *new (Z) NativePrimitiveType(kInt64);

  auto& member_types = *new (Z) NativeTypes(Z, 3);
  member_types.Add(&float_type);
  member_types.Add(&float_type);
  member_types.Add(&float_type);
  const auto& struct_type = NativeStructType::FromNativeTypes(Z, member_types);

#if defined(TARGET_ARCH_ARM64) &&                                              \
    (defined(DART_TARGET_OS_MACOS) || defined(DART_TARGET_OS_MACOS_IOS))
  EXPECT_EQ(4, struct_type.AlignmentInBytesStack());
#endif

  auto& arguments = *new (Z) NativeTypes(Z, 6);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);
  arguments.Add(&struct_type);

  RunSignatureTest(Z, "struct12bytesFloatx6", arguments, int64_type);
}

}  // namespace ffi
}  // namespace compiler
}  // namespace dart
