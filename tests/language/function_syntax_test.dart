// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests function statement and expression syntax.

class FunctionSyntaxTest {
  static void testMain
/* //# 00: compile-time error
      ()
*/ //# 00: continued
  {
    testNestedFunctions();
    testFunctionExpressions();
    testPrecedence();
    testInitializers();
    testFunctionParameter();
    testFunctionIdentifierExpression();
    testFunctionIdentifierStatement();
  }

  static void testNestedFunctions
/* //# 01: compile-time error
      ()
*/ //# 01: continued
  {
    // No types - braces.
    nb0
/* //# 02: compile-time error
        ()
*/ //# 02: continued
    {
      return 42;
    }

    nb1
/* //# 03: compile-time error
        (a)
*/ //# 03: continued
    {
      return a;
    }

    nb2
/* //# 04: compile-time error
        (a, b)
*/ //# 04: continued
    {
      return a + b;
    }

    Expect.equals(42, nb0());
    Expect.equals(87, nb1(87));
    Expect.equals(1 + 2, nb2(1, 2));

    // No types - arrows.
    na0
/* //# 05: compile-time error
        ()
*/ //# 05: continued
            =>
            42;
    na1
/* //# 06: compile-time error
        (a)
*/ //# 06: continued
            =>
            a;
    na2
/* //# 07: compile-time error
        (a, b)
*/ //# 07: continued
            =>
            a + b;
    Expect.equals(42, na0());
    Expect.equals(87, na1(87));
    Expect.equals(1 + 2, na2(1, 2));

    // Return type - braces.
    int rb0
/* //# 08: compile-time error
        ()
*/ //# 08: continued
    {
      return 42;
    }

    int rb1
/* //# 09: compile-time error
        (a)
*/ //# 09: continued
    {
      return a;
    }

    int rb2
/* //# 10: compile-time error
        (a, b)
*/ //# 10: continued
    {
      return a + b;
    }

    Expect.equals(42, rb0());
    Expect.equals(87, rb1(87));
    Expect.equals(1 + 2, rb2(1, 2));

    // Return type - arrows.
    int ra0
/* //# 11: compile-time error
        ()
*/ //# 11: continued
            =>
            42;
    int ra1
/* //# 12: compile-time error
        (a)
*/ //# 12: continued
            =>
            a;
    int ra2
/* //# 13: compile-time error
        (a, b)
*/ //# 13: continued
            =>
            a + b;
    Expect.equals(42, ra0());
    Expect.equals(87, ra1(87));
    Expect.equals(1 + 2, ra2(1, 2));

    // Fully typed - braces.
    int fb1
/* //# 14: compile-time error
        (int a)
*/ //# 14: continued
    {
      return a;
    }

    int fb2
/* //# 15: compile-time error
        (int a, int b)
*/ //# 15: continued
    {
      return a + b;
    }

    Expect.equals(42, rb0());
    Expect.equals(87, rb1(87));
    Expect.equals(1 + 2, rb2(1, 2));

    // Fully typed - arrows.
    int fa1
/* //# 16: compile-time error
        (int a)
*/ //# 16: continued
            =>
            a;
    int fa2
/* //# 17: compile-time error
        (int a, int b)
*/ //# 17: continued
            =>
            a + b;
    Expect.equals(42, ra0());
    Expect.equals(87, ra1(87));
    Expect.equals(1 + 2, ra2(1, 2));

    // Generic types - braces.
    List<int> gb0
/* //# 18: compile-time error
        ()
*/ //# 18: continued
    {
      return [42];
    }

    List<int> gb1
/* //# 19: compile-time error
        (List<int> a)
*/ //# 19: continued
    {
      return a;
    }

    Expect.equals(42, gb0()[0]);
    Expect.equals(87, gb1([87])[0]);

    // Generic types - arrows.
    List<int> ga0
/* //# 20: compile-time error
        ()
*/ //# 20: continued
            =>
            [42];
    List<int> ga1
/* //# 21: compile-time error
        (List<int> a)
*/ //# 21: continued
            =>
            a;
    Expect.equals(42, ga0()[0]);
    Expect.equals(87, ga1([87])[0]);
  }

  static void testFunctionExpressions
/* //# 22: compile-time error
      ()
*/ //# 22: continued
  {
    eval0
/* //# 23: compile-time error
        (fn)
*/ //# 23: continued
            =>
            fn();
    eval1
/* //# 24: compile-time error
        (fn, a)
*/ //# 24: continued
            =>
            fn(a);
    eval2
/* //# 25: compile-time error
        (fn, a, b)
*/ //# 25: continued
            =>
            fn(a, b);

    // No types - braces.
    Expect.equals(42, eval0(
/* //# 26: compile-time error
        ()
*/ //# 26: continued
        {
      return 42;
    }));
    Expect.equals(
        87,
        eval1(
/* //# 27: compile-time error
            (a)
*/ //# 27: continued
            {
          return a;
        }, 87));
    Expect.equals(
        1 + 2,
        eval2(
/* //# 28: compile-time error
            (a, b)
*/ //# 28: continued
            {
          return a + b;
        }, 1, 2));
    Expect.equals(42, eval0(
/* //# 29: compile-time error
        ()
*/ //# 29: continued
        {
      return 42;
    }));
    Expect.equals(
        87,
        eval1(
/* //# 30: compile-time error
            (a)
*/ //# 30: continued
            {
          return a;
        }, 87));
    Expect.equals(
        1 + 2,
        eval2(
/* //# 31: compile-time error
            (a, b)
*/ //# 31: continued
            {
          return a + b;
        }, 1, 2));

    // No types - arrows.
    Expect.equals(
        42,
        eval0(
/* //# 32: compile-time error
            ()
*/ //# 32: continued
                =>
                42));
    Expect.equals(
        87,
        eval1(
/* //# 33: compile-time error
            (a)
*/ //# 33: continued
                =>
                a,
            87));
    Expect.equals(
        1 + 2,
        eval2(
/* //# 34: compile-time error
            (a, b)
*/ //# 34: continued
                =>
                a + b,
            1,
            2));
    Expect.equals(
        42,
        eval0(
/* //# 35: compile-time error
            ()
*/ //# 35: continued
                =>
                42));
    Expect.equals(
        87,
        eval1(
/* //# 36: compile-time error
            (a)
*/ //# 36: continued
                =>
                a,
            87));
    Expect.equals(
        1 + 2,
        eval2(
/* //# 37: compile-time error
            (a, b)
*/ //# 37: continued
                =>
                a + b,
            1,
            2));

    // Argument types - braces.
    Expect.equals(42, eval0(
/* //# 44: compile-time error
        ()
*/ //# 44: continued
        {
      return 42;
    }));
    Expect.equals(
        87,
        eval1(
/* //# 45: compile-time error
            (int a)
*/ //# 45: continued
            {
          return a;
        }, 87));
    Expect.equals(
        1 + 2,
        eval2(
/* //# 46: compile-time error
            (int a, int b)
*/ //# 46: continued
            {
          return a + b;
        }, 1, 2));
    Expect.equals(42, eval0(
/* //# 47: compile-time error
        ()
*/ //# 47: continued
        {
      return 42;
    }));
    Expect.equals(
        87,
        eval1(
/* //# 48: compile-time error
            (int a)
*/ //# 48: continued
            {
          return a;
        }, 87));
    Expect.equals(
        1 + 2,
        eval2(
/* //# 49: compile-time error
            (int a, int b)
*/ //# 49: continued
            {
          return a + b;
        }, 1, 2));

    // Argument types - arrows.
    Expect.equals(
        42,
        eval0(
/* //# 50: compile-time error
            ()
*/ //# 50: continued
                =>
                42));
    Expect.equals(
        87,
        eval1(
/* //# 51: compile-time error
            (int a)
*/ //# 51: continued
                =>
                a,
            87));
    Expect.equals(
        1 + 2,
        eval2(
/* //# 52: compile-time error
            (int a, int b)
*/ //# 52: continued
                =>
                a + b,
            1,
            2));
    Expect.equals(
        42,
        eval0(
/* //# 53: compile-time error
            ()
*/ //# 53: continued
                =>
                42));
    Expect.equals(
        87,
        eval1(
/* //# 54: compile-time error
            (int a)
*/ //# 54: continued
                =>
                a,
            87));
    Expect.equals(
        1 + 2,
        eval2(
/* //# 55: compile-time error
            (int a, int b)
*/ //# 55: continued
                =>
                a + b,
            1,
            2));
  }

  static void testPrecedence
/* //# 64: compile-time error
      ()
*/ //# 64: continued
  {
    expectEvaluatesTo
/* //# 65: compile-time error
        (value, fn)
*/ //# 65: continued
    {
      Expect.equals(value, fn());
    }

    // Assignment.
    var x;
    expectEvaluatesTo(42, () => x = 42);
    Expect.equals(42, x);
    x = 1;
    expectEvaluatesTo(100, () => x += 99);
    Expect.equals(100, x);
    x = 1;
    expectEvaluatesTo(87, () => x *= 87);
    Expect.equals(87, x);

    // Conditional.
    expectEvaluatesTo(42, () => true ? 42 : 87);
    expectEvaluatesTo(87, () => false ? 42 : 87);

    // Logical or.
    expectEvaluatesTo(true, () => true || true);
    expectEvaluatesTo(true, () => true || false);
    expectEvaluatesTo(true, () => false || true);
    expectEvaluatesTo(false, () => false || false);

    // Logical and.
    expectEvaluatesTo(true, () => true && true);
    expectEvaluatesTo(false, () => true && false);
    expectEvaluatesTo(false, () => false && true);
    expectEvaluatesTo(false, () => false && false);

    // Bitwise operations.
    expectEvaluatesTo(3, () => 1 | 2);
    expectEvaluatesTo(2, () => 3 ^ 1);
    expectEvaluatesTo(1, () => 3 & 1);

    // Equality.
    expectEvaluatesTo(true, () => 1 == 1);
    expectEvaluatesTo(false, () => 1 != 1);
    expectEvaluatesTo(true, () => identical(1, 1));
    expectEvaluatesTo(false, () => !identical(1, 1));

    // Relational.
    expectEvaluatesTo(true, () => 1 <= 1);
    expectEvaluatesTo(false, () => 1 < 1);
    expectEvaluatesTo(false, () => 1 > 1);
    expectEvaluatesTo(true, () => 1 >= 1);

    // Is.
    expectEvaluatesTo(true, () => 1 is int);
    expectEvaluatesTo(true, () => 1.0 is double);

    // Shift.
    expectEvaluatesTo(2, () => 1 << 1);
    expectEvaluatesTo(1, () => 2 >> 1);

    // Additive.
    expectEvaluatesTo(2, () => 1 + 1);
    expectEvaluatesTo(1, () => 2 - 1);

    // Multiplicative.
    expectEvaluatesTo(2, () => 1 * 2);
    expectEvaluatesTo(2.0, () => 4 / 2);
    expectEvaluatesTo(2, () => 4 ~/ 2);
    expectEvaluatesTo(0, () => 4 % 2);

    // Negate.
    expectEvaluatesTo(false, () => !true);

    // Postfix / prefix.
    var y = 0;
    expectEvaluatesTo(0, () => y++);
    expectEvaluatesTo(2, () => ++y);
    expectEvaluatesTo(1, () => --y);
    expectEvaluatesTo(1, () => y--);
    Expect.equals(0, y);

    // Selector.
    fn
/* //# 66: compile-time error
        ()
*/ //# 66: continued
            =>
            42;
    var list = [87];
    expectEvaluatesTo(42, () => fn());
    expectEvaluatesTo(1, () => list.length);
    expectEvaluatesTo(87, () => list[0]);
    expectEvaluatesTo(87, () => list.removeLast());
  }

  static void testInitializers
/* //# 67: compile-time error
      ()
*/ //# 67: continued
  {
    Expect.equals(42, (new C.cb0().fn)());
    Expect.equals(43, (new C.ca0().fn)());
    Expect.equals(44, (new C.cb1().fn)());
    Expect.equals(45, (new C.ca1().fn)());
    Expect.equals(46, (new C.cb2().fn)());
    Expect.equals(47, (new C.ca2().fn)());
    Expect.equals(48, (new C.cb3().fn)());
    Expect.equals(49, (new C.ca3().fn)());

    Expect.equals(52, (new C.nb0().fn)());
    Expect.equals(53, (new C.na0().fn)());
    Expect.equals(54, (new C.nb1().fn)());
    Expect.equals(55, (new C.na1().fn)());
    Expect.equals(56, (new C.nb2().fn)());
    Expect.equals(57, (new C.na2().fn)());
    Expect.equals(58, (new C.nb3().fn)());
    Expect.equals(59, (new C.na3().fn)());

    Expect.equals(62, (new C.rb0().fn)());
    Expect.equals(63, (new C.ra0().fn)());
    Expect.equals(64, (new C.rb1().fn)());
    Expect.equals(65, (new C.ra1().fn)());
    Expect.equals(66, (new C.rb2().fn)());
    Expect.equals(67, (new C.ra2().fn)());
    Expect.equals(68, (new C.rb3().fn)());
    Expect.equals(69, (new C.ra3().fn)());
  }

  static void testFunctionParameter
/* //# 68: compile-time error
      ()
*/ //# 68: continued
  {
    f0(fn()) => fn();
    Expect.equals(42, f0(() => 42));

    f1(int fn()) => fn();
    Expect.equals(87, f1(() => 87));

    f2(fn(a)) => fn(42);
    Expect.equals(43, f2((a) => a + 1));

    f3(fn(int a)) => fn(42);
    Expect.equals(44, f3((int a) => a + 2));
  }

  static void testFunctionIdentifierExpression
/* //# 69: compile-time error
      ()
*/ //# 69: continued
  {
    Expect.equals(
        87,
        (
/* //# 70: compile-time error
            ()
*/ //# 70: continued
                =>
                87)());
  }

  static void testFunctionIdentifierStatement
/* //# 71: compile-time error
      ()
*/ //# 71: continued
  {
    function
/* //# 72: compile-time error
        ()
*/ //# 72: continued
            =>
            42;
    Expect.equals(42, function());
    Expect.equals(true, function is Function);
  }
}

class C {
  C.cb0()
      : fn = (() {
          return 42;
        }) {}
  C.ca0() : fn = (() => 43) {}

  C.cb1()
      : fn = wrap(() {
          return 44;
        }) {}
  C.ca1() : fn = wrap(() => 45) {}

  C.cb2()
      : fn = [
          () {
            return 46;
          }
        ][0] {}
  C.ca2() : fn = [() => 47][0] {}

  C.cb3()
      : fn = {
          'x': () {
            return 48;
          }
        }['x'] {}
  C.ca3() : fn = {'x': () => 49}['x'] {}

  C.nb0()
      : fn = (() {
          return 52;
        }) {}
  C.na0() : fn = (() => 53) {}

  C.nb1()
      : fn = wrap(() {
          return 54;
        }) {}
  C.na1() : fn = wrap(() => 55) {}

  C.nb2()
      : fn = [
          () {
            return 56;
          }
        ][0] {}
  C.na2() : fn = [() => 57][0] {}

  C.nb3()
      : fn = {
          'x': () {
            return 58;
          }
        }['x'] {}
  C.na3() : fn = {'x': () => 59}['x'] {}

  C.rb0()
      : fn = (() {
          return 62;
        }) {}
  C.ra0() : fn = (() => 63) {}

  C.rb1()
      : fn = wrap(() {
          return 64;
        }) {}
  C.ra1() : fn = wrap(() => 65) {}

  C.rb2()
      : fn = [
          () {
            return 66;
          }
        ][0] {}
  C.ra2() : fn = [() => 67][0] {}

  C.rb3()
      : fn = {
          'x': () {
            return 68;
          }
        }['x'] {}
  C.ra3() : fn = {'x': () => 69}['x'] {}

  static wrap
/* //# 73: compile-time error
      (fn)
*/ //# 73: continued
  {
    return fn;
  }

  final fn;
}

main
/* //# 74: compile-time error
    ()
*/ //# 74: continued
{
  FunctionSyntaxTest.testMain();
}
