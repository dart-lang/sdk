// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

abstract class B<T> {
  // x will be marked genericCovariantInterface, since x's type is covariant in
  // the type parameter T.
  void set s2(T x);

  // x will be marked genericCovariantInterface, since x's type is covariant in
  // the type parameter T.
  void set s3(T x);

  void set s4(Object x);

  void set s5(Object x) {
    s4 = x;
  }
}

class C extends B<A> {
  void set s1(A x) {}

  // x will be marked genericCovariantImpl, since it might be called via
  // e.g. B<Object>.
  void set s2(A x) {}

  // x will be marked genericCovariantImpl, since it might be called via
  // e.g. B<Object>.
  void set s3(covariant A x) {}

  void set s4(covariant A x) {}
}

main() {
  // Dynamic method calls should always have their arguments type checked.
  dynamic d = new C();
  Expect.throwsTypeError(() => d.s1 = new Object()); //# 01: ok

  // Interface calls should have any arguments marked "genericCovariantImpl"
  // type checked provided that the corresponding argument on the interface
  // target is marked "genericCovariantInterface".
  B<Object> b = new C();
  Expect.throwsTypeError(() => b.s2 = new Object()); //# 02: ok

  // Interface calls should have any arguments marked "covariant" type checked,
  // regardless of whether the corresponding argument on the interface target is
  // marked "genericCovariantInterface".
  Expect.throwsTypeError(() => b.s3 = new Object()); //# 03: ok
  Expect.throwsTypeError(() => b.s4 = new Object()); //# 04: ok

  // This calls should have any arguments marked "covariant" type checked.
  Expect.throwsTypeError(() => b.s5 = new Object()); //# 05: ok
}
