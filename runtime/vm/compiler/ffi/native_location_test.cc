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

}  // namespace ffi
}  // namespace compiler
}  // namespace dart
