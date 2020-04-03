// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  conditionalTest();
  orTest();
  andTest();
  ifTest();
  forTest();
  whileTest();
  doTest();
  notTest();
}

void conditionalTest() {
  bool x = null;
  Expect.throwsAssertionError(() => x ? 1 : 0);
}

void orTest() {
  bool x = null;
  Expect.throwsAssertionError(() => x || x);
  Expect.throwsAssertionError(() => x || false);
  Expect.throwsAssertionError(() => x || true);
  Expect.throwsAssertionError(() => false || x);
  Expect.isTrue(true || x);
}

void andTest() {
  bool x = null;
  Expect.throwsAssertionError(() => x && x);
  Expect.throwsAssertionError(() => x && false);
  Expect.throwsAssertionError(() => x && true);
  Expect.isFalse(false && x);
  Expect.throwsAssertionError(() => true && x);
}

void ifTest() {
  bool x = null;
  Expect.throwsAssertionError(() {
    if (x) {}
  });
}

void forTest() {
  bool x = null;
  Expect.throwsAssertionError(() {
    for (; x;) {}
  });
}

void whileTest() {
  bool x = null;
  Expect.throwsAssertionError(() {
    while (x) {}
  });
}

void doTest() {
  bool x = null;
  Expect.throwsAssertionError(() {
    do {} while (x);
  });
}

void notTest() {
  bool x = null;
  Expect.throwsAssertionError(() => !x);
}
