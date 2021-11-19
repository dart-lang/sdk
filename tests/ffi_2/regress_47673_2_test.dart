// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// @dart=2.9

import 'dart:ffi';

class A extends Struct {
  @Array.multi([16])
  Array<Int8> a;

  // This should not crash the FFI transform.
  @Array.multi([16]) //# 1: compile-time error
  Array<Unknown> b; //# 1: compile-time error
}

main() {}
