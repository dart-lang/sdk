// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test optimized constant string and constant array access.

int testConstantStringAndIndexCodeUnitAt() {
  int test(b) {
    if (b) return "hest".codeUnitAt(400);
    return "hest".codeUnitAt(2);
  }

  Expect.throws(() => test(true));
  for (int i = 0; i < 10000; i++) test(false);
  Expect.throws(() => test(true));
}


int testConstantArrayAndIndexAt() {
  int test(b) {
    var a = const [1,2,3,4];
    if (b) return a[400];
    return a[2];
  }

  Expect.throws(() => test(true));
  for (int i = 0; i < 10000; i++) test(false);
  Expect.throws(() => test(true));
}


foo(a) {
  if (a == 1) { return 2; }
  var aa = const [1, 2];
  return aa[2.3];
}


int testNonSmiIndex() {
  for (int i = 0; i < 10000; i++) { foo(1); }
  Expect.throws(() => foo(2));
}


main() {
  testConstantStringAndIndexCodeUnitAt();
  testConstantArrayAndIndexAt();
  testNonSmiIndex();
}
