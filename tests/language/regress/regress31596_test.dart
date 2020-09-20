// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class B2 extends A {}

class C {
  void f(B? x, B y) {}
}

abstract class I<X> {
  void f(X? x, B y);
}

// This class contains a forwarding stub for f to allow it to satisfy the
// interface I<B>, while still ensuring that the x argument is type checked
// before C.f is executed.
//
// For purposes of static type checking, the interface of the class D is
// considered to contain a method f with signature (B, B) -> void. For purposes
// of runtime behavior, a tearoff of D.f is considered to have the reified
// runtime type (Object, B) -> void.
class D extends C implements I<B> {}

main() {
  var d = new D();
  I<A> i = d;
  A a = new A();
  B b = new B();
  B2? b2 = null;
  d.f(b2, b);
  //  ^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'B2?' can't be assigned to the parameter type 'B?'.
  i.f(b2, b); // Ok since B2 assignable to A
  void Function(Object, B) g = d.f as dynamic; // Ok; D.f reified as (Object, B) -> void
  Expect.throwsTypeError(() {
    d.f(a as B, b);
  });
  Expect.throwsTypeError(() {
    i.f(a, b);
  });
}
