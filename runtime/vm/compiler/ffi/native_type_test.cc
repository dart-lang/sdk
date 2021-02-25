// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/unit_test.h"

#include "platform/syslog.h"
#include "vm/compiler/ffi/native_type.h"
#include "vm/compiler/runtime_api.h"

namespace dart {
namespace compiler {
namespace ffi {

const NativeCompoundType& RunStructTest(dart::Zone* zone,
                                        const char* name,
                                        const NativeTypes& member_types) {
  const auto& struct_type =
      NativeCompoundType::FromNativeTypes(zone, member_types);

  const char* test_result = struct_type.ToCString(zone, /*multi_line=*/true);

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

  return struct_type;
}

UNIT_TEST_CASE_WITH_ZONE(NativeType) {
  const auto& native_type = *new (Z) NativePrimitiveType(kInt8);

  EXPECT_EQ(1, native_type.SizeInBytes());
  EXPECT(native_type.IsInt());
  EXPECT(native_type.IsPrimitive());

  EXPECT_STREQ("int8", native_type.ToCString(Z));
}

UNIT_TEST_CASE_WITH_ZONE(NativeCompoundType_int8x10) {
  const auto& int8type = *new (Z) NativePrimitiveType(kInt8);

  auto& members = *new (Z) NativeTypes(Z, 10);
  members.Add(&int8type);
  members.Add(&int8type);
  members.Add(&int8type);
  members.Add(&int8type);
  members.Add(&int8type);
  members.Add(&int8type);
  members.Add(&int8type);
  members.Add(&int8type);
  members.Add(&int8type);
  members.Add(&int8type);

  const auto& struct_type = RunStructTest(Z, "struct_int8x10", members);

  EXPECT(!struct_type.ContainsHomogenuousFloats());
  EXPECT(!struct_type.ContainsOnlyFloats(0, 8));
  EXPECT_EQ(0, struct_type.NumberOfWordSizeChunksOnlyFloat());
  EXPECT_EQ(
      Utils::RoundUp(struct_type.SizeInBytes(), compiler::target::kWordSize) /
          compiler::target::kWordSize,
      struct_type.NumberOfWordSizeChunksNotOnlyFloat());
}

UNIT_TEST_CASE_WITH_ZONE(NativeCompoundType_floatx4) {
  const auto& float_type = *new (Z) NativePrimitiveType(kFloat);

  auto& members = *new (Z) NativeTypes(Z, 4);
  members.Add(&float_type);
  members.Add(&float_type);
  members.Add(&float_type);
  members.Add(&float_type);

  const auto& struct_type = RunStructTest(Z, "struct_floatx4", members);

  // This is a homogenous float in the arm and arm64 ABIs.
  //
  // On Arm64 iOS stack alignment of homogenous floats is not word size see
  // runtime/vm/compiler/ffi/unit_tests/struct_floatx4/arm64_ios.expect.
  EXPECT(struct_type.ContainsHomogenuousFloats());

  // On x64, 8-byte parts of the chunks contain only floats and will be passed
  // in FPU registers.
  EXPECT(struct_type.ContainsOnlyFloats(0, 8));
  EXPECT(struct_type.ContainsOnlyFloats(8, 8));
  EXPECT_EQ(struct_type.SizeInBytes() / compiler::target::kWordSize,
            struct_type.NumberOfWordSizeChunksOnlyFloat());
  EXPECT_EQ(0, struct_type.NumberOfWordSizeChunksNotOnlyFloat());
}

// A struct designed to exercise all kinds of alignment rules.
// Note that offset32A (System V ia32, iOS arm) aligns doubles on 4 bytes while
// offset32B (Arm 32 bit and MSVC ia32) aligns on 8 bytes.
// TODO(37271): Support nested structs.
// TODO(37470): Add uncommon primitive data types when we want to support them.
struct VeryLargeStruct {
  //                             size32 size64 offset32A offset32B offset64
  int8_t a;                   // 1              0         0         0
  int16_t b;                  // 2              2         2         2
  int32_t c;                  // 4              4         4         4
  int64_t d;                  // 8              8         8         8
  uint8_t e;                  // 1             16        16        16
  uint16_t f;                 // 2             18        18        18
  uint32_t g;                 // 4             20        20        20
  uint64_t h;                 // 8             24        24        24
  intptr_t i;                 // 4      8      32        32        32
  double j;                   // 8             36        40        40
  float k;                    // 4             44        48        48
  VeryLargeStruct* parent;    // 4      8      48        52        56
  intptr_t numChildren;       // 4      8      52        56        64
  VeryLargeStruct* children;  // 4      8      56        60        72
  int8_t smallLastField;      // 1             60        64        80
                              // sizeof        64        72        88
};

UNIT_TEST_CASE_WITH_ZONE(NativeCompoundType_VeryLargeStruct) {
  const auto& intptr_type = *new (Z) NativePrimitiveType(
      compiler::target::kWordSize == 4 ? kInt32 : kInt64);

  auto& members = *new (Z) NativeTypes(Z, 15);
  members.Add(new (Z) NativePrimitiveType(kInt8));
  members.Add(new (Z) NativePrimitiveType(kInt16));
  members.Add(new (Z) NativePrimitiveType(kInt32));
  members.Add(new (Z) NativePrimitiveType(kInt64));
  members.Add(new (Z) NativePrimitiveType(kUint8));
  members.Add(new (Z) NativePrimitiveType(kUint16));
  members.Add(new (Z) NativePrimitiveType(kUint32));
  members.Add(new (Z) NativePrimitiveType(kUint64));
  members.Add(&intptr_type);
  members.Add(new (Z) NativePrimitiveType(kDouble));
  members.Add(new (Z) NativePrimitiveType(kFloat));
  members.Add(&intptr_type);
  members.Add(&intptr_type);
  members.Add(&intptr_type);
  members.Add(new (Z) NativePrimitiveType(kInt8));

  RunStructTest(Z, "struct_VeryLargeStruct", members);
}

}  // namespace ffi
}  // namespace compiler
}  // namespace dart
