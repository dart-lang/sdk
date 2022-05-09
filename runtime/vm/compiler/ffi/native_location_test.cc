// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/unit_test.h"

#include "vm/compiler/ffi/native_location.h"

namespace dart {
namespace compiler {
namespace ffi {

UNIT_TEST_CASE_WITH_ZONE(NativeStackLocation) {
  const auto& native_type = *new (Z) NativePrimitiveType(kInt8);

  const int kUnalignedStackLocation = 17;

  const auto& native_location = *new (Z) NativeStackLocation(
      native_type, native_type, SPREG, kUnalignedStackLocation);

  EXPECT_EQ(kUnalignedStackLocation + native_type.SizeInBytes(),
            native_location.StackTopInBytes());
}

UNIT_TEST_CASE_WITH_ZONE(NativeStackLocation_Split) {
  const auto& native_type = *new (Z) NativePrimitiveType(kInt64);

  const auto& native_location =
      *new (Z) NativeStackLocation(native_type, native_type, SPREG, 0);

  const auto& half_0 = native_location.Split(Z, 2, 0);
  const auto& half_1 = native_location.Split(Z, 2, 1);

  EXPECT_EQ(0, half_0.offset_in_bytes());
  EXPECT_EQ(4, half_1.offset_in_bytes());
}

// Regression test for NativeFpuRegistersLocation::Equals not considering kind
// when comparing.
UNIT_TEST_CASE_WITH_ZONE(NativeStackLocation_Equals) {
  const auto& native_type = *new (Z) NativePrimitiveType(kInt8);

  // Two FPU registers of the same kind and number are equal.
  {
    const auto& native_location1 = *new (Z) NativeFpuRegistersLocation(
        native_type, native_type, kQuadFpuReg,
        /*fpu_register=*/0);

    const auto& native_location2 = *new (Z) NativeFpuRegistersLocation(
        native_type, native_type, kQuadFpuReg,
        /*fpu_register=*/0);

    EXPECT(native_location1.Equals(native_location2));
  }

  // Two FPU registers with different numbers are NOT equal.
  {
    const auto& native_location1 = *new (Z) NativeFpuRegistersLocation(
        native_type, native_type, kQuadFpuReg,
        /*fpu_register=*/2);

    const auto& native_location2 = *new (Z) NativeFpuRegistersLocation(
        native_type, native_type, kQuadFpuReg,
        /*fpu_register=*/4);

    EXPECT(!native_location1.Equals(native_location2));
  }

  // Two FPU registers with different kinds are NOT equal.
  {
    const auto& native_location1 = *new (Z) NativeFpuRegistersLocation(
        native_type, native_type, kQuadFpuReg,
        /*fpu_register=*/3);

    const auto& native_location2 = *new (Z) NativeFpuRegistersLocation(
        native_type, native_type, kDoubleFpuReg,
        /*fpu_register=*/3);

    EXPECT(!native_location1.Equals(native_location2));
  }
}

}  // namespace ffi
}  // namespace compiler
}  // namespace dart
