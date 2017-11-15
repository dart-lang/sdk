// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

abstract class B<T> {
  // x will be marked genericCovariantInterface, since x's type is covariant in
  // the type parameter T.
  void f2(T x);

  // x will be marked genericCovariantInterface, since x's type is covariant in
  // the type parameter T.
  void f3(T x);

  void f4(Object x);

  void f5(Object x) {
    f4(x);
  }
}

class C extends B<A> {
  void f1(A x) {}

  // x will be marked genericCovariantImpl, since it might be called via
  // e.g. B<Object>.
  void f2(A x) {}

  // x will be marked genericCovariantImpl, since it might be called via
  // e.g. B<Object>.
  void f3(covariant A x) {}

  void f4(covariant A x) {}
}

main() {
  // Dynamic method calls should always have their arguments type checked.
  dynamic d = new C();
  Expect.throwsTypeError(() => d.f1(new Object())); //# 01: ok

  // Closure calls should have any arguments marked "genericCovariantImpl" type
  // checked.
  B<Object> b = new C();
  void Function(Object) f = b.f2;
  Expect.throwsTypeError(() => f(new Object())); //# 02: ok

  // Interface calls should have any arguments marked "genericCovariantImpl"
  // type checked provided that the corresponding argument on the interface
  // target is marked "genericCovariantInterface".
  Expect.throwsTypeError(() => b.f2(new Object())); //# 03: ok

  // Interface calls should have any arguments marked "covariant" type checked,
  // regardless of whether the corresponding argument on the interface target is
  // marked "genericCovariantInterface".
  Expect.throwsTypeError(() => b.f3(new Object())); //# 04: ok
  Expect.throwsTypeError(() => b.f4(new Object())); //# 05: ok

  // This calls should have any arguments marked "covariant" type checked.
  Expect.throwsTypeError(() => b.f5(new Object())); //# 06: ok
}
