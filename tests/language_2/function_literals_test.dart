// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/**
 * Test various forms of function literals.
 */
typedef int IntFunc(int);

class FunctionLiteralsTest {
  static void checkIntFunction<T>(expected, int f(T x), arg) {
    Expect.equals(expected, f(arg));
  }

  static void checkIntFuncFunction<T>(expected, IntFunc f(T x), arg) {
    Expect.equals(expected, f(arg)(arg));
  }

  int func1(int x) => x;

  int func2(x) => x;

  int func3(int x) {
    return x;
  }

  int func4(x) {
    return x;
  }

  FunctionLiteralsTest() {}

  static void testMain() {
    var test = new FunctionLiteralsTest();
    test.testArrow();
    test.testArrowArrow();
    test.testArrowBlock();
    test.testBlock();
    test.testBlockArrow();
    test.testBlockBlock();
    test.testFunctionRef();
  }

  void testArrow() {
    checkIntFunction(42, (x) => x, 42);
    checkIntFunction(42, (dynamic x) => x, 42);
  }

  void testArrowArrow() {
    checkIntFuncFunction(84, (x) => (y) => x + y, 42);
    checkIntFuncFunction(84, (dynamic x) => (y) => x + y, 42);
  }

  void testArrowBlock() {
    checkIntFuncFunction(
        84,
        (x) => (y) {
              return x + y;
            },
        42);
    checkIntFuncFunction(
        84,
        (int x) => (y) {
              return x + y;
            },
        42);
  }

  void testBlock() {
    checkIntFunction(42, (x) {
      return x;
    }, 42);
    checkIntFunction(42, (int x) {
      return x;
    }, 42);
  }

  void testBlockArrow() {
    checkIntFuncFunction(84, (x) {
      return (y) => x + y;
    }, 42);
    checkIntFuncFunction(84, (int x) {
      return (y) => (x + y) as int;
    }, 42);
  }

  void testBlockBlock() {
    checkIntFuncFunction(84, (x) {
      return (y) {
        return x + y;
      };
    }, 42);
    checkIntFuncFunction(84, (int x) {
      return (y) {
        return x + y;
      };
    }, 42);
  }

  void testFunctionRef() {
    checkIntFunction(42, func1, 42);
    checkIntFunction(42, func2, 42);
    checkIntFunction(42, func3, 42);
    checkIntFunction(42, func4, 42);
  }
}

main() {
  FunctionLiteralsTest.testMain();
}
