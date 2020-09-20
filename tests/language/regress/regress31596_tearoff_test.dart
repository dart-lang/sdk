// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class C {
  void f(B? x) {}
}

abstract class I<X> {
  void f(X? x);
}

// This class contains a forwarding stub for f to allow it to satisfy the
// interface I<B>, while still ensuring that the x argument is type checked
// before C.f is executed.
//
// For purposes of static type checking, the interface of the class D is
// considered to contain a method f with signature (B) -> void.  For purposes of
// runtime behavior, a tearoff of D.f is considered to have the reified runtime
// type (Object) -> void.
class D extends C implements I<B> {}

main() {
  var d = new D();
  A? aNull = null;
  A a = new A();

  // Since the compile-time type of D.f is (B?) -> void, it is assignable to (A)
  // -> void.  Since the runtime type is (Object?) -> void, the assignment is
  // allowed at runtime as well.
  void Function(A?) g = d.f as dynamic;

  // However, the tear-off performs a runtime check of its argument, so it
  // accepts a value of `null`, but it does not accept a value whose runtime
  // type is A.
  g(aNull);
  Expect.throwsTypeError(() {
    g(a);
  });
}
