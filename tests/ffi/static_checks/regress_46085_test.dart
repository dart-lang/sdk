// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

import "dart:ffi";

final class MyStruct extends Struct {
  external Pointer<Int8> notEmpty;

  @Array.multi([])
  external Array<Int16> a0;
//                      ^^
// [analyzer] COMPILE_TIME_ERROR.EMPTY_ARRAY_ANNOTATION
// [cfe] Array dimensions cannot be empty.

  @Array.multi([1])
  external Array<Array<Int16>> a1;
//               ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NESTED_ARRAY_UNSUPPORTED
// [cfe] Nested arrays are not supported.
}

void main() {
  MyStruct? ms = null;
}
