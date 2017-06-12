// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing closures.

import "package:expect/expect.dart";

class LocalFunctionTest {
  LocalFunctionTest()
      : field1 = 100,
        field2_ = 200 {}
  static int f(int n) {
    int a = 0;
    g(int m) {
      a = 3 * n + m + 1; // Capture parameter n and local a.
      return a;
    }

    var b = g(n);
    return a + b;
  }

  static int h(int n) {
    k(int n) {
      var a = new List(n);
      var b = new List(n);
      int i;
      for (i = 0; i < n; i++) {
        var j = i;
        a[i] = () => i; // Captured i is always n.
        b[i] = () => j; // Captured j varies from 0 to n-1.
      }
      var a_sum = 0;
      var b_sum = 0;
      for (int i = 0; i < n; i++) {
        a_sum += a[i]();
        b_sum += b[i]();
      }
      return a_sum + b_sum;
    }

    return k(n);
  }

  static int h2(int n) {
    k(int n) {
      var a = new List(n);
      var b = new List(n);
      for (int i = 0; i < n; i++) {
        var j = i;
        a[i] = () => i; // Captured i varies from 0 to n-1.
        b[i] = () => j; // Captured j varies from 0 to n-1.
      }
      var a_sum = 0;
      var b_sum = 0;
      for (int i = 0; i < n; i++) {
        a_sum += a[i]();
        b_sum += b[i]();
      }
      return a_sum + b_sum;
    }

    return k(n);
  }

  int field1;
  int field2_;
  int get field2 {
    return field2_;
  }

  void set field2(int value) {
    field2_ = value;
  }

  int method(int n) {
    incField1() {
      field1++;
    }

    incField2() {
      field2++;
    }

    for (int i = 0; i < n; i++) {
      incField1();
      incField2();
    }
    return field1 + field2;
  }

  int execute(int times, apply(int x)) {
    for (int i = 0; i < times; i++) {
      apply(i);
    }
    return field1;
  }

  int testExecute(int n) {
    execute(n, (int x) {
      field1 += x;
    });
    return field1;
  }

  static int foo(int n) {
    return -100; // Wrong foo.
  }

  static testSelfReference1(int n) {
    int foo(int n) {
      if (n == 0) {
        return 0;
      } else {
        return 1 + foo(n - 1); // Local foo, not static foo.
      }
    }

    ;
    return foo(n); // Local foo, not static foo.
  }

  static void hep(Function f) {
    f();
  }

  static testNesting(int n) {
    var a = new List(n * n);
    f0() {
      for (int i = 0; i < n; i++) {
        int vi = i;
        f1() {
          for (int j = 0; j < n; j++) {
            int vj = j;
            a[i * n + j] = () => vi * n + vj;
          }
        }

        f1();
      }
    }

    f0();
    int result = 0;
    for (int k = 0; k < n * n; k++) {
      Expect.equals(k, a[k]());
      result += a[k]();
    }
    return result;
  }

  static var field5;
  static var set_field5_func;
  static testClosureCallStatement(int x) {
    LocalFunctionTest.set_field5_func = (int n) {
      field5 = n * n;
    };
    (LocalFunctionTest.set_field5_func)(x);
    Expect.equals(x * x, LocalFunctionTest.field5);
    return true;
  }

  static testExceptions() {
    var f = (int n) => n + 1;
    Expect.equals(2, f(1));
    Expect.equals(true, f is Function);
    Expect.equals(true, f is Object);
    Expect.equals(true, f.toString().startsWith("Closure"));
    bool exception_caught = false;
    try {
      f(1, 2);
    } on NoSuchMethodError catch (e) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
    exception_caught = false;
    try {
      f();
    } on NoSuchMethodError catch (e) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);
    exception_caught = false;
    try {
      f.xyz(0);
    } on NoSuchMethodError catch (e) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);

    // Overwrite closure value.
    f = 3;
    exception_caught = false;
    try {
      f(1);
    } on NoSuchMethodError catch (e) {
      exception_caught = true;
    }
    Expect.equals(true, exception_caught);

    // Do not expect any exceptions to be thrown.
    var g = ([int n = 1]) => n + 1;
    Expect.equals(2, g());
    Expect.equals(3, g(2));
  }

  static int doThis(int n, int f(int n)) {
    return f(n);
  }

  static testMain() {
    Expect.equals(2 * (3 * 2 + 2 + 1), f(2));
    Expect.equals(10 * 10 + 10 * 9 / 2, h(10));
    Expect.equals(90, h2(10));
    Expect.equals(320, new LocalFunctionTest().method(10));
    Expect.equals(145, new LocalFunctionTest().testExecute(10));
    Expect.equals(5, testSelfReference1(5));
    Expect.equals(24 * 25 / 2, testNesting(5));
    Expect.equals(true, testClosureCallStatement(7));
    Expect.equals(99, doThis(10, (n) => n * n - 1));
    testExceptions();
  }
}

main() {
  LocalFunctionTest.testMain();
}
