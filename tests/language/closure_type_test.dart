// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for a closure result type test that cannot be eliminated at compile
// time.

library closure_type_test;

import "package:expect/expect.dart";
import 'dart:math' as math;

class Math {
  static
  int // //# 01: static type warning
      sqrt(x) => math.sqrt(x);
}

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch (e) {
    return true;
  }
}

void test(int func(int value), int value) {
  bool got_type_error = false;
  try {
    // Because of function subtyping rules, the static return type of a closure
    // call cannot be relied upon for static type analysis. For example, a
    // function returning dynamic (function 'root') can be assigned to a closure
    // variable declared to return int (closure 'func') and may actually return
    // a double at run-time.
    // Therefore, eliminating the run-time type check would be wrong.
    int x = func(value);
    Expect.equals(value, x * x);
  } on TypeError catch (error) {
    got_type_error = true;
  }
  // Type error expected in checked mode only.
  Expect.isTrue(got_type_error == isCheckedMode());
}

root(x) => Math.sqrt(x);

main() => test(root, 4);
