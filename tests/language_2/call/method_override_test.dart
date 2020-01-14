// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

class B {}

class C {
  B call(B b) => b;
}

typedef B BToB(B x);

class D {
  BToB f() => null;
  void g(C x) {}
}

class E extends D {
  // This override is illegal because C is not a subtype of BToB.
  C f() => null;
  //^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  // [cfe] The return type of the method 'E.f' is 'C', which does not match the return type, 'B Function(B)', of the overridden method, 'D.f'.

  // This override is illegal because BToB is not a supertype of C.
  void g(BToB x) {}
  //   ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  //          ^
  // [cfe] The parameter 'x' of the method 'E.g' has type 'B Function(B)', which does not match the corresponding type, 'C', in the overridden method, 'D.g'.
}

main() {
  new E();
}
