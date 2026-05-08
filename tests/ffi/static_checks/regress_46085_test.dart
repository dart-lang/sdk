// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart format off

import "dart:ffi";

final class MyStruct extends Struct {
  external Pointer<Int8> notEmpty;

  @Array.multi([])
  // [error column 3, length 16]
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  external Array<Int16> a0;
  //                    ^
  // [cfe] Field 'a0' must have an 'Array' annotation that matches the dimensions.

  @Array.multi([1])
  // [error column 3, length 17]
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  external Array<Array<Int16>> a1;
  //                           ^
  // [cfe] Field 'a1' must have an 'Array' annotation that matches the dimensions.
}

void main() {
  MyStruct? ms = null;
}
