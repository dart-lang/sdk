// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class I0 {}

class A {}

class B extends A implements I0 {}

class B2 extends A {}

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
// Super calls in a derived class resolve directly to C.f, and are type checked
// accordingly at compile time.
class D extends C implements I<B> {}

class E extends D {
  void test() {
    I0? i0 = null;
    B2? b2 = null;

    // ok since I0 is assignable to B
    super.f(i0 as B?);

    // not ok since B2 is not assignable to B
    super.f(b2);
    //      ^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'B2?' can't be assigned to the parameter type 'B?'.

    var superF = super.f; // Inferred static type: void Function(B)

    // ok since I0 is assignable to B
    superF(i0 as B?);

    // not ok since B2 is not assignable to B
    superF(b2);
    //     ^^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'B2?' can't be assigned to the parameter type 'B?'.

    // Should pass since superF's runtime type is void Function(Object)
    Expect.isTrue(superF is void Function(B));
    Expect.isTrue(superF is void Function(I0));
    Expect.isTrue(superF is void Function(A));
    Expect.isTrue(superF is void Function(Object));
  }
}

main() {
  new E().test();
}
