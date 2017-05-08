// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_overrides`

class Base {
  int get x => 0;
  set x(other) {}

  int max1(int a, int b) => 0;
  int max2(int a, int b) => 0;
  int m1({int a, int b}) => 0;
  int m2({int a, int b}) => 0;
  int m3({int a, int b}) => 0;
  int operator +(other) => 0;
  Base operator ~()=> null;
}

class Parent extends Base {
  @override
  int get x => super.x; // LINT

  @override
  set x(other) { // LINT
    super.x = other;
  }

  @override
  int max1(int a, int b) => super.max1(a, b); // LINT

  @override
  int max2(int a, int b) => super.max2(b, a); // OK

  @override
  int m1({int a, int b}) => super.m1(a: a, b: b); // LINT

  @override
  int m2({int a, int b}) => super.m2(b: b, a: a); // LINT

  @override
  int m3({int a, int b}) => super.m3(b: a, a: b); // OK

  @override
  int operator +(other) => super + other; // LINT

  @override
  Base operator ~()=> ~super; // LINT
}

class Okay extends Parent {
  final a = new Parent();
  @override
  int get x => a.x; // OK

  @override
  set x(other) { // OK
    a.x = other;
  }
}

class NoError extends Okay {
  @override
  int get x => x; // OK

  @override
  set x(other) { // OK
    x = other;
  }
}

class A {
  void foo() {}

  void bar() {}

  int getA(Iterable a) => 0;

  int getB(Iterable a) => 0;

  int getC(Iterable a) => 0;
}

class B extends A {
  @override
  void foo() { // LINT
    super.foo();
  }

  @override
  void bar() { // OK
    bar();
  }

  @override
  int getA(Iterable a) => super.getA(a); // LINT

  @override
  int getB(Iterable a) { // LINT
    return super.getB(a);
  }

  @override
  int getC(Iterable a) { // OK
    print("something");
    return super.getC(a);
  }
}
