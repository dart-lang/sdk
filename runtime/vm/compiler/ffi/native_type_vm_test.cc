// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/compiler/ffi/native_type.h"

#include "vm/compiler/backend/il_test_helper.h"
#include "vm/unit_test.h"

namespace dart {
namespace compiler {
namespace ffi {

ISOLATE_UNIT_TEST_CASE(Ffi_NativeType_Primitive_FromAbstractType) {
  Zone* Z = thread->zone();

  const auto& ffi_library = Library::Handle(Library::FfiLibrary());
  const auto& int8_class = Class::Handle(GetClass(ffi_library, "Int8"));
  const auto& int8_type = Type::Handle(int8_class.DeclarationType());
  const auto& native_type = NativeType::FromAbstractType(Z, int8_type);

  EXPECT_EQ(1, native_type.SizeInBytes());
  EXPECT_STREQ("int8", native_type.ToCString());
  EXPECT(native_type.IsInt());
  EXPECT(native_type.IsPrimitive());
}

// Test that we construct `NativeType` correctly from `Type`.
ISOLATE_UNIT_TEST_CASE(Ffi_NativeType_Struct_FromAbstractType) {
  Zone* Z = thread->zone();

  const char* kScript =
      R"(
      import 'dart:ffi';

      class MyStruct extends Struct {
        @Int8()
        external int a0;

        external Pointer<Int8> a1;
      }
      )";

  const auto& root_library = Library::Handle(LoadTestScript(kScript));
  const auto& struct_class = Class::Handle(GetClass(root_library, "MyStruct"));
  const auto& struct_type = Type::Handle(struct_class.DeclarationType());

  const auto& native_type =
      NativeType::FromAbstractType(Z, struct_type).AsCompound();

  EXPECT_EQ(2, native_type.members().length());

  const auto& int8_type = *new (Z) NativePrimitiveType(kInt8);
  EXPECT(int8_type.Equals(*native_type.members()[0]));

  EXPECT_EQ(compiler::target::kWordSize,
            native_type.members()[1]->SizeInBytes());
}

}  // namespace ffi
}  // namespace compiler
}  // namespace dart
