// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of parameterized types with invalid bounds.

interface I<T extends num> { }

interface J<T> { }

interface K<T> { }

class A<T> implements I<T>, J<T> {
}

main() {
  var a = new A<String>();

  {
    I i = a;  /// 00: dynamic type error
    J j = a;  /// 01: static type error
    K k = a;  /// 02: dynamic type error

    // In production mode, A<String> is subtype of I, but error in checked mode.
    var x = a is I;  /// 03: dynamic type error

    // In both production and checked modes, A<String> is a subtype of I.
    Expect.isTrue(a is J);  /// 04: static type error

    // In both production and checked modes, A<String> is not a subtype of K.
    Expect.isTrue(a is !K);  /// 05: static type error
  }

  a = new A<int>();

  {
    I i = a;
    J j = a;
    K k = a;  /// 06: dynamic type error

    // In both production and checked modes, A<int> is a subtype of I.
    Expect.isTrue(a is I);

    // In both production and checked modes, A<int> is a subtype of J.
    Expect.isTrue(a is J);

    // In both production and checked modes, A<int> is not a subtype of K.
    Expect.isTrue(a is !K);
  }
}
