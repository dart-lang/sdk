// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

void and1() {
  var b = true;
  b = b && b;
  Expect.equals(true, b);
}

void and2() {
  var b = false;
  b = b && b;
  Expect.equals(false, b);
}

void and3() {
  var b = true;
  b = b && false;
  Expect.equals(false, b);
}

void and4() {
  var b = true;
  b = b && true;
  Expect.equals(true, b);
}

void and5() {
  if (true && false) Expect.fail('unreachable');
}

void and6() {
  var b = true;
  if (true && true) b = false;
  Expect.equals(false, b);
}

void and7() {
  var b = false;
  if (true && false) {
    b = false;
  } else {
    b = true;
  }
  Expect.equals(true, b);
}

void main() {
  and1();
  and2();
  and3();
  and4();
  and5();
  and6();
  and7();
}
