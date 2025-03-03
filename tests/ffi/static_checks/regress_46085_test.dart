// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Formatting can break multitests, so don't format them.
// dart format off

import "dart:ffi";

final class MyStruct extends Struct {
  external Pointer<Int8> notEmpty;

  @Array.multi([]) // [cfe] unspecified
  external Array<Int16> a0; // [cfe] unspecified

  @Array.multi([1]) // [cfe] unspecified
  external Array<Array<Int16>> a1; // [cfe] unspecified
}

void main() {
  MyStruct? ms = null;
}
