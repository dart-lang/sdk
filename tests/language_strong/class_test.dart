// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests basic classes and methods.
class ClassTest {
  ClassTest() {}

  static testMain() {
    var test = new ClassTest();
    test.testSuperCalls();
    test.testVirtualCalls();
    test.testStaticCalls();
    test.testInheritedField();
    test.testMemberRefInClosure();
    test.testFactory();
    test.testNamedConstructors();
    test.testDefaultImplementation();
    test.testFunctionParameter((int a) {
      return a;
    });
  }

  testFunctionParameter(int func(int a)) {
    Expect.equals(1, func(1));
  }

  testSuperCalls() {
    var sub = new Sub();
    Expect.equals(43, sub.methodX());
    Expect.equals(84, sub.methodK());
  }

  testVirtualCalls() {
    var sub = new Sub();
    Expect.equals(41, sub.method2());
    Expect.equals(41, sub.method3());
  }

  testStaticCalls() {
    var sub = new Sub();
    Expect.equals(-42, Sub.method4());
    Expect.equals(-41, sub.method5());
  }

  testInheritedField() {
    var sub = new Sub();
    Expect.equals(42, sub.method6());
  }

  testMemberRefInClosure() {
    var sub = new Sub();
    Expect.equals(1, sub.closureRef());
    Expect.equals(2, sub.closureRef());
    // Make sure it is actually on the object, not the global 'this'.
    sub = new Sub();
    Expect.equals(1, sub.closureRef());
    Expect.equals(2, sub.closureRef());
  }

  testFactory() {
    var sup = new Sup.named();
    Expect.equals(43, sup.methodX());
    Expect.equals(84, sup.methodK());
  }

  testNamedConstructors() {
    var sup = new Sup.fromInt(4);
    Expect.equals(4, sup.methodX());
    Expect.equals(0, sup.methodK());
  }

  testDefaultImplementation() {
    var x = new Inter(4);
    Expect.equals(4, x.methodX());
    Expect.equals(8, x.methodK());

    x = new Inter.fromInt(4);
    Expect.equals(4, x.methodX());
    Expect.equals(0, x.methodK());

    x = new Inter.named();
    Expect.equals(43, x.methodX());
    Expect.equals(84, x.methodK());

    x = new Inter.factory();
    Expect.equals(43, x.methodX());
    Expect.equals(84, x.methodK());
  }
}

abstract class Inter {
  factory Inter.named() = Sup.named;
  factory Inter.fromInt(int x) = Sup.fromInt;
  factory Inter(int x) = Sup;
  factory Inter.factory() = Sup.factory;
  int methodX();
  int methodK();
  int x_;
}

class Sup implements Inter {
  int x_;
  int k_;

  factory Sup.named() {
    return new Sub();
  }

  factory Sup.factory() {
    return new Sub();
  }

  Sup.fromInt(int x) {
    x_ = x;
    k_ = 0;
  }

  int methodX() {
    return x_;
  }

  int methodK() {
    return k_;
  }

  Sup(int x) : this.x_ = x {
    k_ = x * 2;
  }

  int method2() {
    return x_ - 1;
  }
}

class Sub extends Sup {
  int y_;

  // Override
  int methodX() {
    return super.methodX() + 1;
  }

  int method3() {
    return method2();
  }

  static int method4() {
    return -42;
  }

  int method5() {
    return method4() + 1;
  }

  int method6() {
    return x_ + y_;
  }

  int closureRef() {
    var f = () {
      y_ += 1;
      return y_;
    };
    return f();
  }

  Sub() : super(42) {
    y_ = 0;
  }
}

main() {
  ClassTest.testMain();
}
