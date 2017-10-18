// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing closures.

import "package:expect/expect.dart";

typedef T F<T>(T t);

class Parameterized<T> {
  Parameterized() {}
  T mul3(F f, T t) {
    return 3 * f(t); //# 01: compile-time error
  }

  T test(T t) {
    return mul3((T t) {
      return 3 * t; //# 02: compile-time error
    }, t);
  }
}

class LocalFunction2Test {
  static int f(int n) {
    int a = 0;
    var g = (int n) {
      a += n;
      return a;
    };
    var h = (int n) {
      a += 10 * n;
      return a;
    };
    return g(n) + h(n);
  }

  static testMain() {
    Expect.equals(3 + 33, f(3));
    Expect.equals(9.0, new Parameterized<double>().test(1.0));
  }
}

main() {
  LocalFunction2Test.testMain();
}
