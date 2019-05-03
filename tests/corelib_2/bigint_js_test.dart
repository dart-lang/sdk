// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing Bigints with and without intrinsics.
// VMOptions=--intrinsify --no-enable-asserts
// VMOptions=--intrinsify --enable-asserts
// VMOptions=--no-intrinsify --enable-asserts
// VMOptions=--optimization-counter-threshold=5 --no-background-compilation

// Test for JavaScript specific BigInt behaviour. Any JavaScript number (double)
// that is an integral value is a Dart 'int' value, so any BigInt that has a
// value that is exactly a double integral value should return `true` for
// [BigInt.isValidInt].

import "package:expect/expect.dart";

int intPow(int a, int p) {
  int result = 1;
  for (int i = 0; i < p; i++) result *= a;
  return result;
}

int pow2_53 = intPow(2, 53);

test(int n1, int n2, int shift, [bool expectedIsValidInt = true]) {
  var n = (new BigInt.from(n1) * new BigInt.from(n2)) << shift;
  Expect.equals(expectedIsValidInt, n.isValidInt, '${n}.isValidInt');
  if (n >= new BigInt.from(pow2_53)) {
    var nplus1 = n + BigInt.one;
    Expect.isFalse(nplus1.isValidInt, '${nplus1}.isValidInt');
  }
}

main() {
  test(13, 19, 1);
  test(19997, 19993, 100);
  test(19997, pow2_53 ~/ 19997, 0);
  test(19997, pow2_53 ~/ 19997, 1);
  test(19997, pow2_53 ~/ 19997, 100);
  test(1, 1, 100);
  test(1, 1, 10000, false);

  // More than 53 bits in product,
  test(pow2_53 ~/ 3, pow2_53 ~/ 5, 0, false);
}
