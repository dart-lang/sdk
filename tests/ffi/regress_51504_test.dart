// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');

void main() {
  dlopenGlobalPlatformSpecific('ffi_test_functions');

  testVariadicAt1Int64x5NativeLeaf();
}

@Native<Int64 Function(Int64, VarArgs<(Int64, Int64, Int64, Int64)>)>(
  symbol: 'VariadicAt1Int64x5',
  isLeaf: true,
)
external int variadicAt1Int64x5NativeLeaf(
  int a0,
  int a1,
  int a2,
  int a3,
  int a4,
);

void testVariadicAt1Int64x5NativeLeaf() {
  final result = variadicAt1Int64x5NativeLeaf(1, 2, 3, 4, 5);
  Expect.equals(15, result);
}
