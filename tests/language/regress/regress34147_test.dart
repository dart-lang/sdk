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

void expectError(Function() callback) {
  if (hasUnsoundNullSafety) {
    Expect.throwsAssertionError(callback);
  } else {
    Expect.throwsTypeError(callback);
  }
}

void conditionalTest() {
  dynamic x = null;
  expectError(() => x ? 1 : 0);
}

void orTest() {
  dynamic x = null;
  expectError(() => x || x);
  expectError(() => x || false);
  expectError(() => x || true);
  expectError(() => false || x);
  Expect.isTrue(true || x);
}

void andTest() {
  dynamic x = null;
  expectError(() => x && x);
  expectError(() => x && false);
  expectError(() => x && true);
  Expect.isFalse(false && x);
  expectError(() => true && x);
}

void ifTest() {
  dynamic x = null;
  expectError(() {
    if (x) {}
  });
}

void forTest() {
  dynamic x = null;
  expectError(() {
    for (; x;) {}
  });
}

void whileTest() {
  dynamic x = null;
  expectError(() {
    while (x) {}
  });
}

void doTest() {
  dynamic x = null;
  expectError(() {
    do {} while (x);
  });
}

void notTest() {
  dynamic x = null;
  expectError(() => !x);
}
