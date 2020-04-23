// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I0 {}

class A {}

class B extends A implements I0 {}

class C {
  void f(B x) {}
}

abstract class I {
  void f(covariant A x);
}

class D extends C implements I {}
//    ^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
// [cfe] unspecified

main() {}
