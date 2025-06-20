// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// Formatting can break multitests, so don't format them.
// dart format off

import 'dart:ffi';

final class A extends Struct {
  @Array.multi([16])
  external Array<Int8> a;

  // This should not crash the FFI transform.
  @Array.multi([16])
  external Array<Unknown> b;
//               ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CLASS
// [cfe] Type 'Unknown' not found.
}

main() {}
