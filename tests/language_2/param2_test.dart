// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing function type parameters.

import "package:expect/expect.dart";

class Param2Test {
  static forEach(List<int> a, int f(k)) {
    for (int i = 0; i < a.length; i++) {
      a[i] = f(a[i]);
    }
  }

  static int apply(f(int k), int arg) {
    var res = f(arg);
    return res;
  }

  static exists(List<int> a, f(e)) {
    for (int i = 0; i < a.length; i++) {
      if (f(a[i])) return true;
    }
    return false;
  }

  static testMain() {
    int square(int x) {
      return x * x;
    }

    Expect.equals(4, apply(square, 2));
    Expect.equals(100, apply(square, 10));

    var v = [1, 2, 3, 4, 5, 6];
    forEach(v, square);
    Expect.equals(1, v[0]);
    Expect.equals(4, v[1]);
    Expect.equals(9, v[2]);
    Expect.equals(16, v[3]);
    Expect.equals(25, v[4]);
    Expect.equals(36, v[5]);

    isOdd(element) {
      return element % 2 == 1;
    }

    Expect.equals(true, exists([3, 5, 7, 11, 13], isOdd));
    Expect.equals(false, exists([2, 4, 10], isOdd));
    Expect.equals(false, exists([], isOdd));

    v = [4, 5, 7];
    Expect.equals(true, exists(v, (e) => e % 2 == 1));
    Expect.equals(false, exists(v, (e) => e == 6));

    var isZero = (e) => e == 0;
    Expect.equals(false, exists(v, isZero));
  }
}

main() {
  Param2Test.testMain();
}
