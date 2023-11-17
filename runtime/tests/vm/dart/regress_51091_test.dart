// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/51091.
// Verifies that compiler doesn't crash if there are two local
// variables with the same name in the same local scope.


import 'package:expect/expect.dart';

void test1() {
  if (0 case var x) {
    Expect.equals(0, x);
  }
  var x = 1;
  Expect.equals(1, x);
}

void test2(int arg) {
  switch (arg) {
    case == 0 && var x: Expect.equals(0, x);
    case == 1 && var x: Expect.equals(1, x);
  }
  var x = 1;
  Expect.equals(1, x);
}

void main() {
  test1();
  test2(0);
  test2(1);
}
