// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

@pragma('vm:never-inline')
int foo<T>(int i, T j, Type t) {
  triggerGc();
  Expect.equals(T, t);
  return i + 2;
}

main() {
  final x = foo(1, 0.0, double);
  final y = foo(2, 0, int);
  Expect.equals(3, x);
  Expect.equals(4, y);
}
