// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests function statement and expression syntax.

class FunctionSyntaxTest {

  static void testMain() {
    testNestedFunctions();
    testFunctionExpressions();
    testPrecedence();
    testInitializers();
    testFunctionParameter();
    testFunctionIdentifierExpression();
    testFunctionIdentifierStatement();
  }

  static void testNestedFunctions() {
    // No types - braces.
    nb0() { return 42; }
    nb1(a) { return a; }
    nb2(a, b) { return a + b; }
    Expect.equals(42, nb0());
    Expect.equals(87, nb1(87));
    Expect.equals(1 + 2, nb2(1, 2));

    // No types - arrows.
    na0() => 42;
    na1(a) => a;
    na2(a, b) => a + b;
    Expect.equals(42, na0());
    Expect.equals(87, na1(87));
    Expect.equals(1 + 2, na2(1, 2));

    // Return type - braces.
    int rb0() { return 42; }
    int rb1(a) { return a; }
    int rb2(a, b) { return a + b; }
    Expect.equals(42, rb0());
    Expect.equals(87, rb1(87));
    Expect.equals(1 + 2, rb2(1, 2));

    // Return type - arrows.
    int ra0() => 42;
    int ra1(a) => a;
    int ra2(a, b) => a + b;
    Expect.equals(42, ra0());
    Expect.equals(87, ra1(87));
    Expect.equals(1 + 2, ra2(1, 2));

    // Fully typed - braces.
    int fb1(int a) { return a; }
    int fb2(int a, int b) { return a + b; }
    Expect.equals(42, rb0());
    Expect.equals(87, rb1(87));
    Expect.equals(1 + 2, rb2(1, 2));

    // Fully typed - arrows.
    int fa1(int a) => a;
    int fa2(int a, int b) => a + b;
    Expect.equals(42, ra0());
    Expect.equals(87, ra1(87));
    Expect.equals(1 + 2, ra2(1, 2));

    // Generic types - braces.
    List<int> gb0() { return [42]; }
    List<int> gb1(List<int> a) { return a; }
    Expect.equals(42, gb0()[0]);
    Expect.equals(87, gb1([87])[0]);

    // Generic types - arrows.
    List<int> ga0() => [42];
    List<int> ga1(List<int> a) => a;
    Expect.equals(42, ga0()[0]);
    Expect.equals(87, ga1([87])[0]);
  }

  static void testFunctionExpressions() {
    eval0(fn) => fn();
    eval1(fn, a) => fn(a);
    eval2(fn, a, b) => fn(a, b);

    // No types - braces.
    Expect.equals(42, eval0(() { return 42; }));
    Expect.equals(87, eval1((a) { return a; }, 87));
    Expect.equals(1 + 2, eval2((a, b) { return a + b; }, 1, 2));
    Expect.equals(42, eval0(nb0() { return 42; }));
    Expect.equals(87, eval1(nb1(a) { return a; }, 87));
    Expect.equals(1 + 2, eval2(nb2(a, b) { return a + b; }, 1, 2));

    // No types - arrows.
    Expect.equals(42, eval0(() => 42));
    Expect.equals(87, eval1((a) => a, 87));
    Expect.equals(1 + 2, eval2((a, b) => a + b, 1, 2));
    Expect.equals(42, eval0(na0() => 42));
    Expect.equals(87, eval1(na1(a) => a, 87));
    Expect.equals(1 + 2, eval2(na2(a, b) => a + b, 1, 2));

    // Return type - braces.
    Expect.equals(42, eval0(int rb0() { return 42; }));
    Expect.equals(87, eval1(int rb1(a) { return a; }, 87));
    Expect.equals(1 + 2, eval2(int rb2(a, b) { return a + b; }, 1, 2));

    // Return type - arrows.
    Expect.equals(42, eval0(int ra0() => 42));
    Expect.equals(87, eval1(int ra1(a) => a, 87));
    Expect.equals(1 + 2, eval2(int ra2(a, b) => a + b, 1, 2));

    // Argument types - braces.
    Expect.equals(42, eval0(() { return 42; }));
    Expect.equals(87, eval1((int a) { return a; }, 87));
    Expect.equals(1 + 2, eval2((int a, int b) { return a + b; }, 1, 2));
    Expect.equals(42, eval0( ab0() { return 42; }));
    Expect.equals(87, eval1(ab1(int a) { return a; }, 87));
    Expect.equals(1 + 2, eval2(ab2(int a, int b) { return a + b; }, 1, 2));

    // Argument types - arrows.
    Expect.equals(42, eval0(() => 42));
    Expect.equals(87, eval1((int a) => a, 87));
    Expect.equals(1 + 2, eval2((int a, int b) => a + b, 1, 2));
    Expect.equals(42, eval0(aa0() => 42));
    Expect.equals(87, eval1(aa1(int a) => a, 87));
    Expect.equals(1 + 2, eval2(aa2(int a, int b) => a + b, 1, 2));

    // Fully typed - braces.
    Expect.equals(87, eval1(int fb1(int a) { return a; }, 87));
    Expect.equals(1 + 2, eval2(int fb2(int a, int b) { return a + b; }, 1, 2));

    // Fully typed - arrows.
    Expect.equals(87, eval1(int fa1(int a) => a, 87));
    Expect.equals(1 + 2, eval2(int fa2(int a, int b) => a + b, 1, 2));

    // Generic types - braces.
    Expect.equals(42, eval0(List<int> gb0() { return [42]; })[0]);
    Expect.equals(87, eval1(List<int> gb1(List<int> a) { return a; }, [87])[0]);

    // Generic types - arrows.
    Expect.equals(42, eval0(List<int> ga0() => [42])[0]);
    Expect.equals(87, eval1(List<int> ga1(List<int> a) => a, [87])[0]);
  }

  static void testPrecedence() {
    expectEvaluatesTo(value, fn) { Expect.equals(value, fn()); }

    // Assignment.
    var x;
    expectEvaluatesTo(42, ()=> x = 42);
    Expect.equals(42, x);
    x = 1;
    expectEvaluatesTo(100, ()=> x += 99);
    Expect.equals(100, x);
    x = 1;
    expectEvaluatesTo(87, ()=> x *= 87);
    Expect.equals(87, x);

    // Conditional.
    expectEvaluatesTo(42, ()=> true ? 42 : 87);
    expectEvaluatesTo(87, ()=> false ? 42 : 87);

    // Logical or.
    expectEvaluatesTo(true, ()=> true || true);
    expectEvaluatesTo(true, ()=> true || false);
    expectEvaluatesTo(true, ()=> false || true);
    expectEvaluatesTo(false, ()=> false || false);

    // Logical and.
    expectEvaluatesTo(true, ()=> true && true);
    expectEvaluatesTo(false, ()=> true && false);
    expectEvaluatesTo(false, ()=> false && true);
    expectEvaluatesTo(false, ()=> false && false);

    // Bitwise operations.
    expectEvaluatesTo(3, ()=> 1 | 2);
    expectEvaluatesTo(2, ()=> 3 ^ 1);
    expectEvaluatesTo(1, ()=> 3 & 1);

    // Equality.
    expectEvaluatesTo(true, ()=> 1 == 1);
    expectEvaluatesTo(false, ()=> 1 != 1);
    expectEvaluatesTo(true, ()=> 1 === 1);
    expectEvaluatesTo(false, ()=> 1 !== 1);

    // Relational.
    expectEvaluatesTo(true, ()=> 1 <= 1);
    expectEvaluatesTo(false, ()=> 1 < 1);
    expectEvaluatesTo(false, ()=> 1 > 1);
    expectEvaluatesTo(true, ()=> 1 >= 1);

    // Is.
    expectEvaluatesTo(true, ()=> 1 is int);
    expectEvaluatesTo(true, ()=> 1.0 is double);

    // Shift.
    expectEvaluatesTo(2, ()=> 1 << 1);
    expectEvaluatesTo(1, ()=> 2 >> 1);

    // Additive.
    expectEvaluatesTo(2, ()=> 1 + 1);
    expectEvaluatesTo(1, ()=> 2 - 1);

    // Multiplicative.
    expectEvaluatesTo(2, ()=> 1 * 2);
    expectEvaluatesTo(2.0, ()=> 4 / 2);
    expectEvaluatesTo(2, ()=> 4 ~/ 2);
    expectEvaluatesTo(0, ()=> 4 % 2);

    // Negate.
    expectEvaluatesTo(-3, ()=> ~2);
    expectEvaluatesTo(false, ()=> !true);

    // Postfix / prefix.
    var y = 0;
    expectEvaluatesTo(0, ()=> y++);
    expectEvaluatesTo(2, ()=> ++y);
    expectEvaluatesTo(1, ()=> --y);
    expectEvaluatesTo(1, ()=> y--);
    Expect.equals(0, y);

    // Selector.
    fn() => 42;
    var list = [87];
    expectEvaluatesTo(42, ()=> fn());
    expectEvaluatesTo(1, ()=> list.length);
    expectEvaluatesTo(87, ()=> list[0]);
    expectEvaluatesTo(87, ()=> list.removeLast());
  }

  static void testInitializers() {
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

  static void testFunctionParameter() {
    f0(fn()) => fn();
    Expect.equals(42, f0(()=> 42));

    f1(int fn()) => fn();
    Expect.equals(87, f1(()=> 87));

    f2(fn(a)) => fn(42);
    Expect.equals(43, f2((a)=> a + 1));

    f3(fn(int a)) => fn(42);
    Expect.equals(44, f3((int a)=> a + 2));
  }

  static void testFunctionIdentifierExpression() {
    Expect.equals(87, (function() => 87)());
  }

  static void testFunctionIdentifierStatement() {
    function() => 42;
    Expect.equals(42, function());
    Expect.equals(true, function is Function);
  }

}


class C {

  C.cb0() : fn = (() { return 42; }) { }
  C.ca0() : fn = (() => 43) { }

  C.cb1() : fn = wrap(() { return 44; }) { }
  C.ca1() : fn = wrap(()=> 45) { }

  C.cb2() : fn = [() { return 46; }][0] { }
  C.ca2() : fn = [() => 47][0] { }

  C.cb3() : fn = {'x': () { return 48; }}['x'] { }
  C.ca3() : fn = {'x': () => 49}['x'] { }

  C.nb0() : fn = (f() { return 52; }) { }
  C.na0() : fn = (f() => 53) { }

  C.nb1() : fn = wrap(f() { return 54; }) { }
  C.na1() : fn = wrap(f()=> 55) { }

  C.nb2() : fn = [f() { return 56; }][0] { }
  C.na2() : fn = [f() => 57][0] { }

  C.nb3() : fn = {'x': f() { return 58; }}['x'] { }
  C.na3() : fn = {'x': f() => 59}['x'] { }

  C.rb0() : fn = (int _() { return 62; }) { }
  C.ra0() : fn = (int _() => 63) { }

  C.rb1() : fn = wrap(int _() { return 64; }) { }
  C.ra1() : fn = wrap(int _()=> 65) { }

  C.rb2() : fn = [int _() { return 66; }][0] { }
  C.ra2() : fn = [int _() => 67][0] { }

  C.rb3() : fn = {'x': int _() { return 68; }}['x'] { }
  C.ra3() : fn = {'x': int _() => 69}['x'] { }

  static wrap(fn) { return fn; }

  final fn;

}

main() {
  FunctionSyntaxTest.testMain();
}
