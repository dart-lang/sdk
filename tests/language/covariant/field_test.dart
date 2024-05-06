// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:expect/variations.dart" as v;

class A {}

abstract class B<T> {
  // x will be marked genericCovariantInterface, since x's type is covariant in
  // the type parameter T.
  void set s2(T x);

  // x will be marked genericCovariantInterface, since x's type is covariant in
  // the type parameter T.
  void set s3(T x);

  void set s4(Object? x);

  void set s5(Object? x) {
    s4 = x;
  }
}

class C extends B<A> {
  A? s1;

  // s2 will be marked genericCovariantImpl, since it might be called via
  // e.g. B<Object>.
  A? s2;

  // s3 will be marked genericCovariantImpl, since it might be called via
  // e.g. B<Object>.
  covariant A? s3;

  covariant A? s4;
}

main() {
  // Dynamic method calls should always have their arguments type checked.
  dynamic d = new C();
  Expect.throwsTypeErrorWhen(v.checkedParameters, () => d.s1 = new Object());

  // Interface calls should have any arguments marked "genericCovariantImpl"
  // type checked provided that the corresponding argument on the interface
  // target is marked "genericCovariantInterface".
  B<Object> b = new C();
  Expect.throwsTypeErrorWhen(v.checkedParameters, () => b.s2 = new Object());

  // Interface calls should have any arguments marked "covariant" type checked,
  // regardless of whether the corresponding argument on the interface target is
  // marked "genericCovariantInterface".
  Expect.throwsTypeErrorWhen(v.checkedParameters, () => b.s3 = new Object());
  Expect.throwsTypeErrorWhen(v.checkedParameters, () => b.s4 = new Object());

  // This calls should have any arguments marked "covariant" type checked.
  Expect.throwsTypeErrorWhen(v.checkedParameters, () => b.s5 = new Object());
}
