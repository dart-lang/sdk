// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type promotion of locals potentially mutated in closures.

class A {
  var a = "a";
  A operator +(int i) => this;
}
class B extends A {
  var b = "b";
}
class C extends B {
  var c = "c";
}
class D extends A {
  var d = "d";
}
class E extends D implements C {
  var a = "";
  var b = "";
  var c = "";
  var d = "";
}

func(x) => true;

void main() {
  test1();
  test2();
  test3();
  test3a();
  test4();
  test5();
  test6();
  test6a();
  test7();
  test8();
  test9();
  test10();
  test11();
  test12();
}

void test1() {
  A a = new E();
  if (a is B) {
    print(a.a);
    print(a.b); /// 01: static type warning
  }
  void foo() {
    a = new D();
  }
}

void test2() {
  A a = new E();
  void foo() {
    a = new D();
  }
  if (a is B) {
    print(a.a);
    print(a.b); /// 02: static type warning
  }
}

void test3() {
  A a = new E();
  void foo() {
    a = new D();
  }
  if (a is B) {
    print(a.a);
    print(a.b); /// 03: static type warning
    void foo() {
      a = new D();
    }
    print(a.a);
    print(a.b); /// 04: static type warning
  }
}

void test3a() {
  A a = new E();
  void foo() {
    a = new D();
  }
  if ((((a)) is B)) {
    print(a.a);
    print(a.b); /// 15: static type warning
    void foo() {
      a = new D();
    }
    print(a.a);
    print(a.b); /// 16: static type warning
  }
}

void test4() {
  A a = new E();
  if (a is B) {
    func(() => a.b); /// 05: ok
    print(a.a);
    print(a.b);
  }
}

void test5() {
  A a = new E();
  if (a is B) {
    func(() => a.b); /// 06: static type warning
    print(a.a);
  }
  a = null;
}

void test6() {
  A a = new E();
  if (a is B) {
    func(() => a);
    print(a.a);
    print(a.b); /// 07: static type warning
  }
  a = null;
}

void test6a() {
  A a = new E();
  if (((a) is B)) {
    func(() => a);
    print(a.a);
    print(a.b); /// 14: static type warning
  }
  a = null;
}

void test7() {
  A a = new E();
  if (a is B && func(() => a)) {
    print(a.a);
    print(a.b); /// 08: ok
  }
  a = null;
}

void test8() {
  A a = new E();
  if (a is B
      && func(() => a.b) /// 09: static type warning
                        ) {
    print(a.a);
  }
  a = null;
}

void test9() {
  A a = new E();
  var b = a is B ? func(() => a.b) : false; /// 10: static type warning
  a = null;
}

void test10() {
  List<A> a = <E>[new E()];
  if (a is List<B>) {
    func(() => a[0]);
    print(a[0].b); /// 11: static type warning
  }
  a = null;
}

void test11() {
  List<A> a = <E>[new E()];
  if (a is List<B>) {
    func(() => a[0] = null);
    print(a[0].b); /// 12: static type warning
  }
  a = null;
}

void test12() {
  A a = new E();
  if (a is B) {
    func(() => a++);
    print(a.a);
    print(a.b); /// 13: static type warning
  }
  a = null;
}
