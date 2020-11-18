// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that dynamic invocation of closures works as expected, including
// appropriate type checks.
//
// VMOptions=--lazy-dispatchers
// VMOptions=--no-lazy-dispatchers

import 'package:expect/expect.dart';

class A {
  final int nonce_;

  const A(this.nonce_);
}

class B {
  final int nonce_;

  const B(this.nonce_);
}

class C extends A {
  const C(int nonce) : super(nonce);
}

void main() {
  dynamic f = (String a1, int a2, A a3,
      {String n1 = "default_named", int n2 = -1, A n3 = const A(-1)}) {};

  f("test_fixed", 1, A(1), n1: "test_named", n2: 2, n3: A(2));

  // Test named argument permutations
  f("test_fixed", 1, A(1), n1: "test_named", n3: A(2), n2: 2);
  f("test_fixed", 1, A(1), n2: 2, n1: "test_named", n3: A(2));
  f("test_fixed", 1, A(1), n2: 2, n3: A(2), n1: "test_named");
  f("test_fixed", 1, A(1), n3: A(2), n1: "test_named", n2: 2);
  f("test_fixed", 1, A(1), n3: A(2), n2: 2, n1: "test_named");

  // Test subclasses match the type
  f("test_fixed", 1, C(1), n1: "test_named", n2: 2, n3: A(2));
  f("test_fixed", 1, A(1), n1: "test_named", n2: 2, n3: C(2));

  // Should fail with no such method errors
  Expect.throwsNoSuchMethodError(() => f());
  Expect.throwsNoSuchMethodError(() => f("test_fixed", 1, A(1), n4: 4));

  // Should fail with type errors
  Expect.throwsTypeError(
      () => f(100, 1, A(1), n1: "test_named", n2: 2, n3: A(2)));
  Expect.throwsTypeError(
      () => f("test_fixed", 1.1, A(1), n1: "test_named", n2: 2, n3: A(2)));
  Expect.throwsTypeError(
      () => f("test_fixed", 1, B(1), n1: "test_named", n2: 2, n3: A(2)));
  Expect.throwsTypeError(
      () => f("test_fixed", 1, A(1), n1: 100, n2: 2, n3: A(2)));
  Expect.throwsTypeError(
      () => f("test_fixed", 1, A(1), n1: "test_named", n2: 2.2, n3: A(2)));
  Expect.throwsTypeError(
      () => f("test_fixed", 1, A(1), n1: "test_named", n2: 2, n3: B(2)));
}
