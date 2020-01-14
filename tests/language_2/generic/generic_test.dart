// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Dart test program testing generic type allocations and generic type tests.
import "package:expect/expect.dart";

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
  const B(T t)
      : a_ = t,
        t_ = t;
  isT(x) {
    return x is T;
  }
}

class C<T extends A> {
  B<T> b_;
  C(T t) : b_ = new B<T>(t) {}
}

class D {
  C<AA> caa_;
  D() : caa_ = new C<AA>(const AA()) {}
}

class E {
  C<AX> cax_ = new C<AX>(const AX()); //# 01: compile-time error
}

main() {
  D d = new D();
  Expect.equals(true, d.caa_.b_ is B<AA>);
  Expect.equals(true, d.caa_.b_.isT(const AA()));
  C c = new C(const AA()); // inferred as `C<A>` because of the `extends A`.
  Expect.equals(true, c is C<A>);
  Expect.equals(false, c is C<AA>, 'C<A> is not a subtype of C<AA>');
  Expect.equals(true, c.b_ is B);
  Expect.equals(false, c.b_ is B<AA>);
  Expect.equals(true, c.b_.isT(const AA()), 'AA is a subtype of A');
  Expect.equals(false, c.b_.isT(const AX()), 'AX is not a subtype of A');
  new E();
}
