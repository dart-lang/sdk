// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "dart:ffi";

class MyStruct extends Struct {
  Pointer<Int8> notEmpty;

  @Array.multi([]) //# 01: compile-time error
  Array<Int16> a0; //# 01: compile-time error

  @Array.multi([1]) //# 02: compile-time error
  Array<Array<Int16>> a1; //# 02: compile-time error
}

void main() {
  MyStruct ms = null;
}
