// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A() { NamingTest.count++; }
  foo(a, b) {
    Expect.equals(1, a);
    Expect.equals(2, b);
  }
}

class MyException {
  MyException() {}
}

class debugger {
  static final int __PROTO__ = 5;

  int x;

  factory debugger.F() {
    return new debugger(1);
  }
  debugger(x) : this.x = x + 1 { }
  debugger.C(x) : this.x = x + 2 { }
  debugger.C$C(x) : this.x = x + 3 { }
  debugger.C$I(x) : this.x = x + 4 { }
}

class debugger$C {
  int x;

  factory debugger$C.F() {
    return new debugger$C(1);
  }
  debugger$C(x) : this.x = x + 5 { }
  debugger$C.C(x) : this.x = x + 6 { }
  debugger$C.C$C(x) : this.x = x + 7 { }
  debugger$C.C$I(x) : this.x = x + 8 { }
}

class debugger$C$C {
  int x;

  factory debugger$C$C.F() {
    return new debugger$C$C(1);
  }
  debugger$C$C(x) : this.x = x + 9 { }
  debugger$C$C.C(x) : this.x = x + 10 { }
  debugger$C$C.C$C(x) : this.x = x + 11 { }
  debugger$C$C.C$I(x) : this.x = x + 12 { }
}

class with extends debugger$C {
  int y;

  factory with.F() {
    return new with(1, 2);
  }
  with(x, y) : super(x), this.y = y + 1 { }
  with.I(x, y) : super.C(x), this.y = y + 2 { }
  with.C(x, y) : super.C$C(x), this.y = y + 3 { }
  with.I$C(x, y) : super.C$I(x), this.y = y + 4 { }
  with.C$C(x, y) : super(x), this.y = y + 5 { }
  with.C$C$C(x, y) : super.C(x), this.y = y + 6 { }
  with.$C$I(x, y) : super.C$C(x), this.y = y + 7 { }
  with.$$I$C(x, y) : super.C$I(x), this.y = y + 8 { }
  with.$(x, y) : super(x), this.y = y + 9 { }
  with.$$(x, y) : super.C(x), this.y = y + 10 { }
}

class with$I extends debugger$C {
  int y;

  factory with$I.F() {
    return new with$I(1, 2);
  }
  with$I(x, y) : super(x), this.y = y + 11 { }
  with$I.I(x, y) : super.C(x), this.y = y + 12 { }
  with$I.C(x, y) : super.C$C(x), this.y = y + 13 { }
  with$I.I$C(x, y) : super.C$I(x), this.y = y + 14 { }
  with$I.C$C(x, y) : super(x), this.y = y + 15 { }
  with$I.C$C$C(x, y) : super.C(x), this.y = y + 16 { }
  with$I.$C$I(x, y) : super.C$C(x), this.y = y + 17 { }
  with$I.$$I$C(x, y) : super.C$I(x), this.y = y + 18 { }
  with$I.$(x, y) : super(x), this.y = y + 19 { }
  with$I.$$(x, y) : super.C(x), this.y = y + 20 { }
}

class with$C extends debugger$C$C {
  int y;

  factory with$C.F() {
    return new with$C(1, 2);
  }
  with$C(x, y) : super(x), this.y = y + 21 { }
  with$C.I(x, y) : super.C(x), this.y = y + 22 { }
  with$C.C(x, y) : super.C$C(x), this.y = y + 23 { }
  with$C.I$C(x, y) : super.C$I(x), this.y = y + 24 { }
  with$C.C$C(x, y) : super(x), this.y = y + 25 { }
  with$C.C$C$C(x, y) : super.C(x), this.y = y + 26 { }
  with$C.$C$I(x, y) : super.C$C(x), this.y = y + 27 { }
  with$C.$$I$C(x, y) : super.C$I(x), this.y = y + 28 { }
  with$C.$(x, y) : super(x), this.y = y + 29 { }
  with$C.$$(x, y) : super.C(x), this.y = y + 30 { }
}

class with$I$C extends debugger$C$C {
  int y;

  factory with$I$C.F() {
    return new with$I$C(1, 2);
  }
  with$I$C(x, y) : super(x), this.y = y + 31 { }
  with$I$C.I(x, y) : super.C(x), this.y = y + 32 { }
  with$I$C.C(x, y) : super.C$C(x), this.y = y + 33 { }
  with$I$C.I$C(x, y) : super.C$I(x), this.y = y + 34 { }
  with$I$C.C$C(x, y) : super(x), this.y = y + 35 { }
  with$I$C.C$C$C(x, y) : super.C(x), this.y = y + 36 { }
  with$I$C.$C$I(x, y) : super.C$C(x), this.y = y + 37 { }
  with$I$C.$$I$C(x, y) : super.C$I(x), this.y = y + 38 { }
  with$I$C.$(x, y) : super(x), this.y = y + 39 { }
  with$I$C.$$(x, y) : super.C(x), this.y = y + 40 { }
}

class Tata {
  var prototype;

  Tata() : this.prototype = 0 {}

  __PROTO__$() { return 12; }
}

class Toto extends Tata {
  var __PROTO__;

  Toto() : super(), this.__PROTO__ = 0 { }

  prototype$() { return 10; }

  titi() {
    Expect.equals(0, prototype);
    Expect.equals(0, __PROTO__);
    prototype = 3;
    __PROTO__ = 5;
    Expect.equals(3, prototype);
    Expect.equals(5, __PROTO__);
    Expect.equals(10, prototype$());
    Expect.equals(12, __PROTO__$());
    Expect.equals(12, this.__PROTO__$());
    Expect.equals(10, this.prototype$());
    Expect.equals(12, __PROTO__$());
  }
}

class Bug4082360 {
  int x_;
  Bug4082360() {}

  int get x { return x_; }
  void set x(int value) { x_ = value; }

  void indirectSet(int value) { x = value; }

  static void test() {
    var bug = new Bug4082360();
    bug.indirectSet(42);
    Expect.equals(42, bug.x_);
    Expect.equals(42, bug.x);
  }
}

class Hoisting {
  var f_;
  Hoisting.negate(var x) {
    f_ = () { return x; };
  }

  // TODO(hausner): Rename to operator -.
  operator negate() {
    var x = 3;
    return () { return x + 1; };
  }

  operator[] (x) {
    return () { return x + 3; };
  }

  static void test() {
    var h = new Hoisting.negate(1);
    Expect.equals(1, (h.f_)());
    var f = -h;
    Expect.equals(4, f());
    Expect.equals(7, h[4]());
  }
}

// It is not possible to make sure that the backend uses the hardcoded names
// we are testing against. This test might therefore become rapidly out of date
class NamingTest {
  static int count;

  static testExceptionNaming() {
    // Exceptions use a hardcoded "e" as exception name. If the namer works
    // correctly then it will be renamed in case of clashes.
    var e = 3;
    var caught = false;
    try {
      throw new MyException();
    } catch (var exc) {
      try {
        throw new MyException();
      } catch (var exc2) {
        exc = 9;
      }
      Expect.equals(9, exc);
      caught = true;
    }
    Expect.equals(true, caught);
    Expect.equals(3, e);
  }

  static testTmpNaming() {
    Expect.equals(0, count);
    var tmp$0 = 1;
    var tmp$1 = 2;
    new A().foo(tmp$0, tmp$1++);
    Expect.equals(1, count);
    Expect.equals(3, tmp$1);
  }

  static testScopeNaming() {
    // Alias scopes use a hardcoded "dartc_scp$<depth>" as names.
    var dartc_scp$1 = 5;
    var foo = 8;
    var f = () {
      var dartc_scp$1 = 15;
      return foo + dartc_scp$1;
    };
    Expect.equals(5, dartc_scp$1);
    Expect.equals(23, f());
  }

  static testGlobalMangling() {
    var x;
    x = new debugger(0);
    Expect.equals(1, x.x);
    x = new debugger.C(0);
    Expect.equals(2, x.x);
    x = new debugger.C$C(0);
    Expect.equals(3, x.x);
    x = new debugger.C$I(0);
    Expect.equals(4, x.x);
    x = new debugger$C(0);
    Expect.equals(5, x.x);
    x = new debugger$C.C(0);
    Expect.equals(6, x.x);
    x = new debugger$C.C$C(0);
    Expect.equals(7, x.x);
    x = new debugger$C.C$I(0);
    Expect.equals(8, x.x);
    x = new debugger$C$C(0);
    Expect.equals(9, x.x);
    x = new debugger$C$C.C(0);
    Expect.equals(10, x.x);
    x = new debugger$C$C.C$C(0);
    Expect.equals(11, x.x);
    x = new debugger$C$C.C$I(0);
    Expect.equals(12, x.x);
    x = new with(0, 0);
    Expect.equals(5, x.x);
    Expect.equals(1, x.y);
    x = new with.I(0, 0);
    Expect.equals(6, x.x);
    Expect.equals(2, x.y);
    x = new with.C(0, 0);
    Expect.equals(7, x.x);
    Expect.equals(3, x.y);
    x = new with.I$C(0, 0);
    Expect.equals(8, x.x);
    Expect.equals(4, x.y);
    x = new with.C$C(0, 0);
    Expect.equals(5, x.x);
    Expect.equals(5, x.y);
    x = new with.C$C$C(0, 0);
    Expect.equals(6, x.x);
    Expect.equals(6, x.y);
    x = new with.$C$I(0, 0);
    Expect.equals(7, x.x);
    Expect.equals(7, x.y);
    x = new with.$$I$C(0, 0);
    Expect.equals(8, x.x);
    Expect.equals(8, x.y);
    x = new with.$(0, 0);
    Expect.equals(5, x.x);
    Expect.equals(9, x.y);
    x = new with.$$(0, 0);
    Expect.equals(6, x.x);
    Expect.equals(10, x.y);
    x = new with$I(0, 0);
    Expect.equals(5, x.x);
    Expect.equals(11, x.y);
    x = new with$I.I(0, 0);
    Expect.equals(6, x.x);
    Expect.equals(12, x.y);
    x = new with$I.C(0, 0);
    Expect.equals(7, x.x);
    Expect.equals(13, x.y);
    x = new with$I.I$C(0, 0);
    Expect.equals(8, x.x);
    Expect.equals(14, x.y);
    x = new with$I.C$C(0, 0);
    Expect.equals(5, x.x);
    Expect.equals(15, x.y);
    x = new with$I.C$C$C(0, 0);
    Expect.equals(6, x.x);
    Expect.equals(16, x.y);
    x = new with$I.$C$I(0, 0);
    Expect.equals(7, x.x);
    Expect.equals(17, x.y);
    x = new with$I.$$I$C(0, 0);
    Expect.equals(8, x.x);
    Expect.equals(18, x.y);
    x = new with$I.$(0, 0);
    Expect.equals(5, x.x);
    Expect.equals(19, x.y);
    x = new with$I.$$(0, 0);
    Expect.equals(6, x.x);
    Expect.equals(20, x.y);
    x = new with$C(0, 0);
    Expect.equals(9, x.x);
    Expect.equals(21, x.y);
    x = new with$C.I(0, 0);
    Expect.equals(10, x.x);
    Expect.equals(22, x.y);
    x = new with$C.C(0, 0);
    Expect.equals(11, x.x);
    Expect.equals(23, x.y);
    x = new with$C.I$C(0, 0);
    Expect.equals(12, x.x);
    Expect.equals(24, x.y);
    x = new with$C.C$C(0, 0);
    Expect.equals(9, x.x);
    Expect.equals(25, x.y);
    x = new with$C.C$C$C(0, 0);
    Expect.equals(10, x.x);
    Expect.equals(26, x.y);
    x = new with$C.$C$I(0, 0);
    Expect.equals(11, x.x);
    Expect.equals(27, x.y);
    x = new with$C.$$I$C(0, 0);
    Expect.equals(12, x.x);
    Expect.equals(28, x.y);
    x = new with$C.$(0, 0);
    Expect.equals(9, x.x);
    Expect.equals(29, x.y);
    x = new with$C.$$(0, 0);
    Expect.equals(10, x.x);
    Expect.equals(30, x.y);
    x = new with$I$C(0, 0);
    Expect.equals(9, x.x);
    Expect.equals(31, x.y);
    x = new with$I$C.I(0, 0);
    Expect.equals(10, x.x);
    Expect.equals(32, x.y);
    x = new with$I$C.C(0, 0);
    Expect.equals(11, x.x);
    Expect.equals(33, x.y);
    x = new with$I$C.I$C(0, 0);
    Expect.equals(12, x.x);
    Expect.equals(34, x.y);
    x = new with$I$C.C$C(0, 0);
    Expect.equals(9, x.x);
    Expect.equals(35, x.y);
    x = new with$I$C.C$C$C(0, 0);
    Expect.equals(10, x.x);
    Expect.equals(36, x.y);
    x = new with$I$C.$C$I(0, 0);
    Expect.equals(11, x.x);
    Expect.equals(37, x.y);
    x = new with$I$C.$$I$C(0, 0);
    Expect.equals(12, x.x);
    Expect.equals(38, x.y);
    x = new with$I$C.$(0, 0);
    Expect.equals(9, x.x);
    Expect.equals(39, x.y);
    x = new with$I$C.$$(0, 0);
    Expect.equals(10, x.x);
    Expect.equals(40, x.y);
    var wasCaught = false;
    try {
      throw new with(0, 0);
    } catch(with e) {
      wasCaught = true;
      Expect.equals(5, e.x);
    }
    Expect.equals(true, wasCaught);
  }

  static void testMemberMangling() {
    Expect.equals(5, debugger.__PROTO__);
    new Toto().titi();
  }

  static void testFactoryMangling() {
    var o = new debugger.F();
    Expect.equals(2, o.x);
    o = new debugger$C.F();
    Expect.equals(6, o.x);
    o = new debugger$C$C.F();
    Expect.equals(10, o.x);
    o = new with.F();
    Expect.equals(6, o.x);
    Expect.equals(3, o.y);
    o = new with$I.F();
    Expect.equals(6, o.x);
    Expect.equals(13, o.y);
    o = new with$C.F();
    Expect.equals(10, o.x);
    Expect.equals(23, o.y);
    o = new with$I$C.F();
    Expect.equals(10, o.x);
    Expect.equals(33, o.y);
  }

  static testFunctionParameters() {
    a(with) {
      return with;
    }

    b(eval) {
      return eval;
    }

    c(arguments) {
      return arguments;
    }

    Expect.equals(10, a(10));
    Expect.equals(10, b(10));
    Expect.equals(10, c(10));
  }

  static testPseudoTokens() {
    var EOS = 400;
    var ILLEGAL = 99;
    Expect.equals(499, EOS + ILLEGAL);
  }

  static testDollar() {
    Expect.equals(123, $(123).wrapped);
    var x = new Object(), y = new Object();
    Expect.identical(x, $(x).wrapped);
    Expect.identical(y, $(x).$add(y));
    Expect.identical(x, $(x).$negate());
    Expect.equals(123, $(x) + x);
    Expect.equals(444, -$(x));
  }

  static void testMain() {
    count = 0;
    testExceptionNaming();
    testTmpNaming();
    testScopeNaming();
    testGlobalMangling();
    testMemberMangling();
    testFactoryMangling();
    testFunctionParameters();
    Bug4082360.test();
    Hoisting.test();
    testPseudoTokens();
    testDollar();
  }
}

// Test that the generated JS names don't conflict with "$"
class DartQuery {
  Object wrapped;
  DartQuery(this.wrapped);

  $add(Object other) => other;
  $negate() => wrapped;

  operator +(Object other) => 123;
  operator negate() => 444;
}

$add(Object first, Object second) => second;
DartQuery $(Object obj) => new DartQuery(obj);

// Ensure we don't have false positive. named constructor and methods
// are in different namespaces, therefore it is ok to have a method
// called foo and a named constructor CLASS.foo
class Naming1Test {
  Naming1Test.foo() { }
  foo() { }

  static void main(args) {
    var a = new Naming1Test.foo();
    a.foo();
  }
}

// Ensure we don't have false positive.
class Naming2Test {
  Naming2Test() { }
  int get foo { return 1; }
  set foo(x) { }

  static void main(args) {
    var a = new Naming2Test();
    Expect.throws(() => a.foo(2), (e) => e is ObjectNotClosureException);
  }
}

main() {
  NamingTest.testMain();
  Naming1Test.main(null);
  Naming2Test.main(null);
}
