// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

// Test optimized constant string and constant array access.

int testConstantStringAndIndexCodeUnitAt() {
  int test(b) {
    if (b) return "hest".codeUnitAt(400);
    return "hest".codeUnitAt(2);
  }

  Expect.throws(() => test(true));
  for (int i = 0; i < 20; i++) test(false);
  Expect.throws(() => test(true));
}

int testConstantArrayAndIndexAt() {
  int testPositive(b) {
    var a = const [1, 2, 3, 4];
    if (b) return a[400];
    return a[2];
  }

  int testNegative(b) {
    var a = const [1, 2, 3, 4];
    if (b) return a[-1];
    return a[2];
  }

  Expect.throws(() => testPositive(true));
  for (int i = 0; i < 20; i++) testPositive(false);
  Expect.throws(() => testPositive(true));

  Expect.throws(() => testNegative(true));
  for (int i = 0; i < 20; i++) testNegative(false);
  Expect.throws(() => testNegative(true));
}

foo(a) {
  if (a == 1) {
    return 2;
  }
  var aa = const [1, 2];
  return aa[2.3]; /*@compile-error=unspecified*/
}

int testNonSmiIndex() {
  for (int i = 0; i < 20; i++) {
    foo(1);
  }
  Expect.throws(() => foo(2));
}

main() {
  testConstantStringAndIndexCodeUnitAt();
  testConstantArrayAndIndexAt();
  testNonSmiIndex();
}
