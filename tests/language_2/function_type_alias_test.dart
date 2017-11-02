// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// Dart test for function type alias.

import "package:expect/expect.dart";

typedef Fun(a, b);

typedef int IntFun(a, b);

typedef bool BoolFun(a, b);

typedef int CompareObj(Object a, Object b);

typedef int CompareInt(int a, int b);

typedef int CompareString(String a, String b, [bool swap]);

typedef void Test();

typedef ParameterizedFun1<T, U extends bool, V>(T t, U u);

typedef List<T> ParameterizedFun2<T, U, V extends Map<T, int>>(
    Map<T, int> t, U u);

typedef void BoundsCheck<T extends num>(T arg);

class FunctionTypeAliasTest {
  FunctionTypeAliasTest() {}
  static int test<T>(int compare(T a, T b), T a, T b) {
    return compare(a, b);
  }

  foo(Test arg) {}
  static bar() {
    FunctionTypeAliasTest a = new FunctionTypeAliasTest();
    a.foo(() {});
    return 0;
  }

  static void testMain() {
    int compareStrLen(String a, String b) {
      return a.length - b.length;
    }

    Expect.isTrue(compareStrLen is Fun);
    Expect.isTrue(compareStrLen is IntFun);
    Expect.isTrue(compareStrLen is! BoolFun);
    Expect.isTrue(compareStrLen is! CompareObj);
    Expect.isTrue(compareStrLen is! CompareInt);
    Expect.isTrue(compareStrLen is! CompareString);
    Expect.equals(3, test(compareStrLen, "abcdef", "xyz"));

    int compareStrLenSwap(String a, String b, [bool swap = false]) {
      return swap ? (a.length - b.length) : (b.length - a.length);
    }

    Expect.isTrue(compareStrLenSwap is Fun);
    Expect.isTrue(compareStrLenSwap is IntFun);
    Expect.isTrue(compareStrLenSwap is! BoolFun);
    Expect.isTrue(compareStrLenSwap is! CompareObj);
    Expect.isTrue(compareStrLenSwap is! CompareInt);
    Expect.isTrue(compareStrLenSwap is CompareString);

    int compareStrLenReverse(String a, String b, [bool reverse = false]) {
      return reverse ? (a.length - b.length) : (b.length - a.length);
    }

    Expect.isTrue(compareStrLenReverse is Fun);
    Expect.isTrue(compareStrLenReverse is IntFun);
    Expect.isTrue(compareStrLenReverse is! BoolFun);
    Expect.isTrue(compareStrLenReverse is! CompareObj);
    Expect.isTrue(compareStrLenReverse is! CompareInt);
    Expect.isTrue(compareStrLenReverse is CompareString);

    int compareObj(Object a, Object b) {
      return identical(a, b) ? 0 : -1;
    }

    Expect.isTrue(compareObj is Fun);
    Expect.isTrue(compareObj is IntFun);
    Expect.isTrue(compareObj is! BoolFun);
    Expect.isTrue(compareObj is CompareObj);
    Expect.isTrue(compareObj is CompareInt);
    Expect.isTrue(compareObj is! CompareString);
    Expect.equals(-1, test(compareObj, "abcdef", "xyz"));

    CompareInt minus = (int a, int b) {
      return a - b;
    };
    Expect.isTrue(minus is Fun);
    Expect.isTrue(minus is IntFun);
    Expect.isTrue(minus is! BoolFun);
    Expect.isTrue(minus is! CompareObj);
    Expect.isTrue(minus is CompareInt);
    Expect.isTrue(minus is! CompareString);
    Expect.equals(99, test(minus, 100, 1));

    int plus(int a, [int b = 1]) {
      return a + b;
    }

    ;
    Expect.isTrue(plus is Fun);
    Expect.isTrue(plus is IntFun);
    Expect.isTrue(plus is! BoolFun);
    Expect.isTrue(plus is! CompareObj);
    Expect.isTrue(plus is CompareInt);
    Expect.isTrue(plus is! CompareString);

    Expect.equals(0, bar());

    Function boundsTrue = (num arg) {};
    Function boundsFalse = (String arg) {};
    Expect.isTrue(boundsTrue is BoundsCheck<int>);
    Expect.isFalse(boundsFalse is BoundsCheck<num>);
  }
}

main() {
  FunctionTypeAliasTest.testMain();
}
