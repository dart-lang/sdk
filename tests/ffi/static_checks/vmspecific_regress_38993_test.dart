// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests a compile time error that should not crash the analyzer or CFE.

import "dart:ffi";

final class C extends Struct {
  dynamic x;
  //      ^
  // [cfe] Field 'x' must have a native type.
  // [analyzer] COMPILE_TIME_ERROR.INVALID_FIELD_TYPE_IN_STRUCT

  external Pointer notEmpty;
}

main() {}
