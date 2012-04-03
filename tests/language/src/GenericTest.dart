// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks --enable_asserts
//
// Dart test program testing generic type allocations and generic type tests.

class A {
  const A();
}

class AA extends A {
  const AA();
}

class AX {
  const AX();
}

class B<T extends A> {
  final A a_;
  final T t_;
  const B(T t) : a_ = t, t_ = t;
  isT(x) {
    return x is T;
  }
}

class C<T> {
  B<T> b_;
  C(T t) : b_ = new B<T>(t) { }
}

class D {
  C<AA> caa_;
  D() : caa_ = new C<AA>(const AA()) { }
}

class E {
  C<AX> cax_;
  E() : cax_ = new C<AX>(const AX()) { }
}

class GenericTest {
  static test() {
    int result = 0;
    D d = new D();
    Expect.equals(true, d.caa_.b_ is B<AA>);
    Expect.equals(true, d.caa_.b_.isT(const AA()));
    C c = new C(const AA());  // c is of raw type C, T in C<T> is Dynamic.
    Expect.equals(true, c.b_ is B);
    Expect.equals(true, c.b_ is B<AA>);
    Expect.equals(true, c.b_.isT(const AA()));
    Expect.equals(true, c.b_.isT(const AX()));
    try {
      E e = new E();  // Throws a type error, if type checks are enabled.
    } catch (TypeError error) {
      result = 1;
      // TODO(regis): The error below is detected too late.
      // It should be reported on line 31, at new B<T>(), i.e. new B<AX>().
      // This will be detected when we check the subtyping constraints.
      Expect.equals("A", error.dstType);
      Expect.equals("AX", error.srcType);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("GenericTest.dart", subs);
      Expect.equals(23, error.line);
      Expect.equals(23, error.column);
    }
    return result;
  }

  static testMain() {
    Expect.equals(1, test());
  }
}


main() {
  GenericTest.testMain();
}
