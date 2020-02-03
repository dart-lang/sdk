// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends int> {}

class B {
  A<num> fieldOfA; // Error.
  static A<num> staticFieldOfA; // Error.
}

extension E<X extends A<num>> // Error.
    on A {
  static A<num> fieldOfE; // Error.
  A<num> fooOfE() => null; // Error.
  void barOfE(A<num> a) {} // Error.
  void bazOfE<Y extends A<num>>() {} // Error.
}

main() {}
