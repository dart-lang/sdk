// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

abstract class B<T> {
  // U will be marked genericCovariantInterface, since U's bound is covariant in
  // the type parameter T.
  void f2<U extends T>();
}

class C extends B<A> {
  void f1<U extends A>() {}

  // x will be marked genericCovariantImpl, since it might be called via
  // e.g. B<Object>.
  void f2<U extends A>() {}
}

main() {
  // Dynamic method calls should always have their type arguments checked.
  dynamic d = new C();
  Expect.throwsTypeError(() => d.f1<Object>()); //# 01: ok

  // Closure calls should have any type arguments marked "genericCovariantImpl"
  // checked.
  B<Object> b = new C();
  void Function<U extends Object>() f = b.f2;
  Expect.throwsTypeError(() => f<Object>()); //# 02: ok

  // Interface calls should have any type arguments marked
  // "genericCovariantImpl" checked provided that the corresponding type
  // argument on the interface target is marked "genericCovariantInterface".
  Expect.throwsTypeError(() => b.f2<Object>()); //# 03: ok
}
