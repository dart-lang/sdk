// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that we can call functions through getters.

final TOP_LEVEL_CONST = 1;
final TOP_LEVEL_CONST_REF = TOP_LEVEL_CONST;
final TOP_LEVEL_NULL = null;

var topLevel;

class CallThroughGetterTest {

  static void testMain() {
    testTopLevel();
    testField();
    testGetter();
    testMethod();
    testEvaluationOrder();
  }

  static void testTopLevel() {
    topLevel = function() {
      return 2;
    };
    Expect.equals(1, TOP_LEVEL_CONST);
    Expect.equals(1, TOP_LEVEL_CONST_REF);
    Expect.equals(2, topLevel());

    expectThrowsNotClosure(() { 
      TOP_LEVEL_CONST(); /// static type warning
    });
    expectThrowsNotClosure(() { 
      (TOP_LEVEL_CONST)();  /// static type warning
    });
  }

  static void testField() {
    A a = new A();
    a.field = () => 42;
    Expect.equals(42, a.field());
    Expect.equals(42, (a.field)());

    a.field = () => 87;
    Expect.equals(87, a.field());
    Expect.equals(87, (a.field)());

    a.field = 99;
    expectThrowsNotClosure(() { a.field(); });
    expectThrowsNotClosure(() { (a.field)(); });
  }

  static void testGetter() {
    A a = new A();
    a.field = () => 42;
    Expect.equals(42, a.getter());
    Expect.equals(42, (a.getter)());

    a.field = () => 87;
    Expect.equals(87, a.getter());
    Expect.equals(87, (a.getter)());

    a.field = 99;
    expectThrowsNotClosure(() { a.getter(); });
    expectThrowsNotClosure(() { (a.getter)(); });
  }

  static void testMethod() {
    A a = new A();
    a.field = () => 42;
    Expect.equals(true, a.method() is Function);
    Expect.equals(42, a.method()());

    a.field = () => 87;
    Expect.equals(true, a.method() is Function);
    Expect.equals(87, a.method()());

    a.field = null;
    Expect.equals(null, a.method());
  }

  static void testEvaluationOrder() {
    B b = new B();
    Expect.equals("gf", b.g0());
    b = new B();
    Expect.equals("gf", (b.g0)());

    b = new B();
    Expect.equals("xgf", b.g1(b.x));
    b = new B();
    Expect.equals("gxf", (b.g1)(b.x));

    b = new B();
    Expect.equals("xygf", b.g2(b.x, b.y));
    b = new B();
    Expect.equals("gxyf", (b.g2)(b.x, b.y));

    b = new B();
    Expect.equals("xyzgf", b.g3(b.x, b.y, b.z));
    b = new B();
    Expect.equals("gxyzf", (b.g3)(b.x, b.y, b.z));

    b = new B();
    Expect.equals("yzxgf", b.g3(b.y, b.z, b.x));
    b = new B();
    Expect.equals("gyzxf", (b.g3)(b.y, b.z, b.x));
  }

  static void expectThrowsNotClosure(fn) {
    var exception = catchException(fn);
    if (!(exception is ObjectNotClosureException)) {
      Expect.fail("Wrong exception.  Expected: ObjectNotClosureException"
          " got: ${exception}");
    }
  }

  static catchException(fn) {
    bool caught = false;
    var result = null;
    try {
      fn();
      Expect.equals(true, false);  // Shouldn't reach this.
    } catch (var e) {
      caught = true;
      result = e;
    }
    Expect.equals(true, caught);
    return result;
  }

}


class A {

  A() { }
  var field;
  get getter { return field; }
  method() { return field; }

}


class B {

  B() : _order = new StringBuffer("") { }

  get g0 { _mark('g'); return f0() { return _mark('f'); }; }
  get g1 { _mark('g'); return f1(x) { return _mark('f'); }; }
  get g2 { _mark('g'); return f2(x, y) { return _mark('f'); }; }
  get g3 { _mark('g'); return f3(x, y, z) { return _mark('f'); }; }

  get x { _mark('x'); return 0; }
  get y { _mark('y'); return 1; }
  get z { _mark('z'); return 2; }

  _mark(m) { _order.add(m); return _order.toString(); }
  StringBuffer _order;

}

main() {
  CallThroughGetterTest.testMain();
}
