// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// @dart=2.9

import 'dart:ffi';

typedef T = Int64; //# 1: compile-time error

class A extends Struct {
  @Array.multi([16])
  Array<Int8> a;

  // In language version 2.12 we do not support non-function typedefs.
  // This should not crash the FFI transform.
  @Array.multi([16]) //# 1: compile-time error
  Array<T> b; //# 1: compile-time error
}

main() {}
