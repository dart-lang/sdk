// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

void or1() {
  var b = true;
  b = b || b;
  Expect.equals(true, b);
}

void or2() {
  var b = false;
  b = b || b;
  Expect.equals(false, b);
}

void or3() {
  var b = true;
  b = b || false;
  Expect.equals(true, b);
}

void or4() {
  var b = true;
  b = b || true;
  Expect.equals(true, b);
}

void or5() {
  if (true || false) {} else {
    Expect.fail('unreachable');
  }
}

void or6() {
  var b = true;
  if (true || true) b = false;
  Expect.equals(false, b);
}

void or7() {
  var b = false;
  if (true || false) {
    b = true;
  } else {
    b = false;
  }
  Expect.equals(true, b);
}

void main() {
  or1();
  or2();
  or3();
  or4();
  or5();
  or6();
  or7();
}
