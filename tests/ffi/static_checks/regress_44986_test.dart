// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:ffi";

final class S2 extends Struct {
  external Pointer<Int8> notEmpty;

  external Null s;
  //            ^
  // [cfe] Field 's' must have a native type.
  // [analyzer] COMPILE_TIME_ERROR.INVALID_FIELD_TYPE_IN_STRUCT
}

void main() {
  S2? s2;
}
