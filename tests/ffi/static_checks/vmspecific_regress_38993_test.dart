// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests a compile time error that should not crash the analyzer or CFE.

// dart format off

import "dart:ffi";

final class C extends Struct {
  dynamic x;
//^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_FIELD_TYPE_IN_STRUCT
//        ^
// [analyzer] COMPILE_TIME_ERROR.FIELD_MUST_BE_EXTERNAL_IN_STRUCT
// [cfe] Deeply immutable classes must only have deeply immutable instance fields. Deeply immutable types include 'int', 'double', 'bool', 'String', 'Pointer', 'Float32x4', 'Float64x2', 'Int32x4', function types and classes annotated with `@pragma('vm:deeply-immutable')`.
// [cfe] Deeply immutable classes must only have final non-late instance fields.
// [cfe] Field 'x' cannot be nullable or have type 'Null', it must be `int`, `double`, `Pointer`, or a subtype of `Struct` or `Union`.

  external Pointer notEmpty;
}

main() {}
