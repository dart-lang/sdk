// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type promotion of locals potentially mutated in closures.

import "package:meta/meta.dart" show virtual;

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

  }
}

void test3() {
  A a = new E();
  void foo() {
    a = new D();
  }

  if (a is B) {
    print(a.a);

    void foo() {
      a = new D();
    }

    print(a.a);

  }
}

void test3a() {
  A a = new E();
  void foo() {
    a = new D();
  }

  if ((((a)) is B)) {
    print(a.a);

    void foo() {
      a = new D();
    }

    print(a.a);

  }
}

void test4() {
  A a = new E();
  if (a is B) {

    print(a.a);
    print(a.b);
  }
}

void test5() {
  A a = new E();
  if (a is B) {

    print(a.a);
  }
  a = A();
}

void test6() {
  A a = new E();
  if (a is B) {
    func(() => a);
    print(a.a);

  }
  a = A();
}

void test6a() {
  A a = new E();
  if (((a) is B)) {
    func(() => a);
    print(a.a);

  }
  a = A();
}

void test7() {
  A a = new E();
  if (a is B && func(() => a)) {
    print(a.a);

  }
  a = A();
}

void test8() {
  A a = new E();
  if (a is B

      ) {
    print(a.a);
  }
  a = A();
}

void test9() {
  A a = new E();

  a = A();
}

void test10() {
  List<A> a = <E>[new E()];
  if (a is List<B>) {
    func(() => a[0]);

  }
  a = [];
}

void test11() {
  List<A> a = <E>[new E()];
  if (a is List<B>) {
    func(() => a[0] = E());

  }
  a = [];
}

void test12() {
  A a = new E();
  if (a is B) {
    func(() => a++);
    print(a.a);

  }
  a = A();
}
