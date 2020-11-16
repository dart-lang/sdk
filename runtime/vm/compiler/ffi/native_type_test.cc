// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/unit_test.h"

#include "vm/compiler/ffi/native_type.h"

namespace dart {
namespace compiler {
namespace ffi {

UNIT_TEST_CASE_WITH_ZONE(NativeType) {
  const auto& native_type = *new (Z) NativePrimitiveType(kInt8);

  EXPECT_EQ(1, native_type.SizeInBytes());
  EXPECT(native_type.IsInt());
  EXPECT(native_type.IsPrimitive());

  EXPECT_STREQ("int8", native_type.ToCString(Z));
}

}  // namespace ffi
}  // namespace compiler
}  // namespace dart
