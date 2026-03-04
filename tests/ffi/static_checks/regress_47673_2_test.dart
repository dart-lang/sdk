// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// dart format off

import 'dart:ffi';

final class A extends Struct {
  @Array.multi([16])
  external Array<Int8> a;

  // This should not crash the FFI transform.
  @Array.multi([16])
  external Array<Unknown> b;
  //             ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_SIZED_TYPE_ARGUMENT
  // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
  // [cfe] 'Unknown' isn't a type.
  // [cfe] Type 'Unknown' not found.
  //                      ^
  // [cfe] Expected type 'Array<invalid-type>' to be a valid and instantiated subtype of 'NativeType'.
}

main() {}
