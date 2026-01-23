// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



import "dart:ffi";

final class MyStruct extends Struct {
  external Pointer<Int8> notEmpty;

  @Array.multi([])
  external Array<Int16> a0;
  // [cfe] Array dimensions must be positive integers.
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS

  @Array.multi([1])
  external Array<Array<Int16>> a1;
  // [cfe] Dimension count mismatch.
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
}

void main() {
  MyStruct? ms = null;
}
