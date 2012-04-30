// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of parameterized types with invalid bounds.

interface J<T> { }

interface K<T> { }

interface I<T 
  extends num /// 00: continued
  extends num /// 01: continued
  extends num /// 02: continued
  extends num /// 03: continued
  extends num /// 04: continued
  extends num /// 05: continued
  extends num /// 06: continued
> { }

class A<T> implements I<T>, J<T> {
}

main() {
  var a = new A<String>();

  {
    I i = a;  /// 00: dynamic type error, static type warning
    J j = a;  /// 01: static type warning
    K k = a;  /// 02: dynamic type error, static type warning

    // In production mode, A<String> is subtype of I, error in checked mode.
    var x = a is I;  /// 03: dynamic type error, static type warning

    // In both production and checked modes, A<String> is a subtype of J.
    Expect.isTrue(a is J);  /// 04: static type warning

    // In both production and checked modes, A<String> is not a subtype of K.
    // However, while unsuccessfully trying to prove that A<String> is a K,
    // a malformed type is encountered in checked mode, resulting in a dynamic
    // type error.
    Expect.isTrue(a is !K);  /// 05: dynamic type error
  }

  a = new A<int>();

  {
    I i = a;
    J j = a;
    K k = a;  /// 06: dynamic type error, static type warning

    // In both production and checked modes, A<int> is a subtype of I.
    Expect.isTrue(a is I);

    // In both production and checked modes, A<int> is a subtype of J.
    Expect.isTrue(a is J);

    // In both production and checked modes, A<int> is not a subtype of K.
    Expect.isTrue(a is !K);
  }
}
