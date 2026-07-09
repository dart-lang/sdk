// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart format off

import "dart:ffi";

final class S2 extends Struct {
  external Pointer<Int8> notEmpty;

  external Null s;
  //       ^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_FIELD_TYPE_IN_STRUCT
  //            ^
  // [cfe] Field 's' cannot be nullable or have type 'Null', it must be `int`, `double`, `Pointer`, or a subtype of `Struct` or `Union`.
}

void main() {
  S2? s2;
}
