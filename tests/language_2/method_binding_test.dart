// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Bind a method to a variable that can be invoked as a function

class A {
  int a;

  static var func;

  A(this.a) {}

  static foo() {
    return 4;
  }

  bar() {
    return a;
  }

  int baz() {
    return a;
  }

  getThis() {
    return this.bar;
  }

  getNoThis() {
    return bar;
  }

  methodArgs(arg) {
    return arg + a;
  }

  selfReference() {
    return selfReference;
  }

  invokeBaz() {
    return (baz)();
  }

  invokeBar(var obj) {
    return (obj.bar)();
  }

  invokeThisBar() {
    return (this.bar)();
  }

  implicitStaticRef() {
    return foo;
  }
}

class B {
  static foo() {
    return -1;
  }
}

class C {
  C() {}
  var f;
}

topLevel99() {
  return 99;
}

var topFunc;

class D extends A {
  D(a) : super(a) {}
  getSuper() {
    return super.bar;
  }
}

class MethodBindingTest {
  static test() {
    // Create closure from global
    Expect.equals(99, topLevel99());
    Function f99 = topLevel99;
    Expect.equals(99, f99());

    // Invoke closure through a global
    topFunc = f99;
    Expect.equals(99, topFunc());

    // Create closure from static method
    Function f4 = A.foo;
    Expect.equals(4, f4());

    // Create closure from instance method
    var o5 = new A(5);
    Function f5 = o5.bar;
    Expect.equals(5, f5());

    // Assign closure to field and invoke it
    var c = new C();
    c.f = () => "success";
    Expect.equals("success", c.f());

    // referencing instance method with explicit 'this' qualiier
    var o6 = new A(6);
    var f6 = o6.getThis();
    Expect.equals(6, f6());

    // referencing an instance method with no qualifier
    var o7 = new A(7);
    var f7 = o7.getNoThis();
    Expect.equals(7, f7());

    // bind a method that takes arguments
    var o8 = new A(8);
    Function f8 = o8.methodArgs;
    Expect.equals(9, f8(1));

    // Self referential method
    var o9 = new A(9);
    Function f9 = o9.selfReference;

    // invoking a known method as if it were a bound closure...
    var o10 = new A(10);
    Expect.equals(10, o10.invokeBaz());

    // invoking a known method as if it were a bound closure...
    var o11 = new A(11);
    Expect.equals(10, o11.invokeBar(o10));

    // invoking a known method as if it were a bound closure...
    var o12 = new A(12);
    Expect.equals(12, o12.invokeThisBar());

    // bind to a static variable with no explicit class qualifier
    var o13 = new A(13);
    Function f13 = o13.implicitStaticRef();
    Expect.equals(4, f13());

    var o14 = new D(14);
    Function f14 = o14.getSuper();
    Expect.equals(14, f14());

    // Assign static field to a function and invoke it.
    A.func = A.foo;
    Expect.equals(4, A.func());

    // bind a function that is possibly native in Javascript.
    String o15 = 'hithere';
    var f15 = o15.substring;
    Expect.equals('i', f15(1, 2));

    var o16 = 'hithere';
    var f16 = o16.substring;
    Expect.equals('i', f16(1, 2));

    var f17 = 'hithere'.substring;
    Expect.equals('i', f17(1, 2));
  }

  static testMain() {
    test();
  }
}

main() {
  MethodBindingTest.testMain();
}
