// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of reading and writing to variables.

import 'package:expect/expect.dart';

test0() {
  var x0 = 0, x1;
  Expect.isTrue(x0 == 0);
  Expect.isTrue(x1 == null);
  x0 = 1;
  Expect.isTrue(x0 == 1);
  Expect.isTrue((x0 = 2) == 2);
  Expect.isTrue(x0 == 2);
}

var x2 = 0, x3;

test1() {
  Expect.isTrue(x2 == 0);
  Expect.isTrue(x3 == null);
  x2 = 1;
  Expect.isTrue(x2 == 1);
  Expect.isTrue((x2 = 2) == 2);
  Expect.isTrue(x2 == 2);
}

class C {
  static var x4 = 0;
  static var x5;
}

test3() {
  Expect.isTrue(C.x4 == 0);
  Expect.isTrue(C.x5 == null);
  C.x4 = 1;
  Expect.isTrue(C.x4 == 1);
  Expect.isTrue((C.x4 = 2) == 2);
  Expect.isTrue(C.x4 == 2);
}

class D {
  var x6 = 0;
  var x7;
}

test4() {
  var d = new D();
  Expect.isTrue(d.x6 == 0);
  Expect.isTrue(d.x7 == null);
  d.x6 = 1;
  Expect.isTrue(d.x6 == 1);
  Expect.isTrue((d.x6 = 2) == 2);
  Expect.isTrue(d.x6 == 2);
}

main() {
  test0();
  test1();
  test3();
  test4();
}
