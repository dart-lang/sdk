// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart Mint representations and type propagation issue.
// Testing Int32List and Uint32List loads.
//
// VMOptions=--optimization-counter-threshold=5 --no-use-osr --no-background-compilation

import 'dart:typed_data';
import "package:expect/expect.dart";

main() {
  var a = new Uint32List(100);
  a[2] = 3;
  var res = sumIt1(a, 2);
  Expect.equals(3 * 10, res);
  res = sumIt1(a, 2);
  Expect.equals(3 * 10, res);
  var a1 = new Int32List(100);
  a1[2] = 3;
  res = sumIt2(a1, 2);
  Expect.equals(3 * 10, res);
  res = sumIt2(a1, 2);
  Expect.equals(3 * 10, res);
}

sumIt1(Uint32List a, int n) {
  var sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += a[n];
  }
  return sum;
}

sumIt2(Int32List a, int n) {
  var sum = 0;
  for (int i = 0; i < 10; i++) {
    sum += a[n];
  }
  return sum;
}
