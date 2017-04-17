// compile options: --hoist-signature-types --hoist-instance-creation --hoist-type-tests
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "package:expect/expect.dart";

class A<T> {
  A(this.x, T z);
  A.make();
  void f(T x) {}
  static String g(String x) {
    return x;
  }

  T x;
}

class B extends A<int> {
  B(int x, int z) : super(x, z);
  B.make() : super.make();
  void f(int x) {}
  static int g(int x) {
    return x;
  }
}

class C {
  C(this.x, int z);
  void f(int x) {}
  static int g(int x) {
    return x;
  }

  int x = 0;
}

typedef void ToVoid<T>(T x);
typedef T Id<T>(T x);

void main() {
  {
    A<String> a = new A<String>("hello", "world");
    Expect.isTrue(new A<String>.make() is! A<int>);
    Expect.isTrue(new A.make() is A);
    Expect.isTrue(a is! A<int>);
    Expect.isTrue(a is A<String>);
    Expect.isTrue(a.f is ToVoid<String>);
    Expect.isTrue(A.g is Id<String>);
  }
  {
    B b = new B(0, 1);
    Expect.isTrue(new B.make() is B);
    Expect.isTrue(new B.make() is A<int>);
    Expect.isTrue(b is B);
    Expect.isTrue(b.f is ToVoid<int>);
    Expect.isTrue(B.g is Id<int>);
  }
  {
    C c = new C(0, 1);
    Expect.isTrue(c is C);
    Expect.isTrue(c.f is ToVoid<int>);
    Expect.isTrue(C.g is Id<int>);
  }
}
