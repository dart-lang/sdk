// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests the resolution of a bare type variable with bounded or promoted type.

extension E<T> on T {
  T Function(T) get f => (_) => this;
}

class A<S extends num> {
  void testBoundedTypeVariable(S s) {
    // Check that `num` has no `f` so E is applicable, then bind `T` to `S`.
    S Function(S) f = s.f;
  }

  void testPromotedTypeVariable(S s) {
    if (s is int) {
      // Check that `int` has no `f`, erase `S & int` to `S`, bind `T` to `S`.
      S Function(S) f = s.f;
    }
  }
}

class B<S extends dynamic> {
  void testBoundedTypeVariable(S s) {
    // `dynamic` considered to have `f`, E not applicable, dynamic invocation.
    Expect.throws(() => s.f);
  }

  void testPromotedType(S s) {
    if (s is int) {
      // Check that `int` has no `f`, erase `S & int` to `S`, bind `T` to `S`.
      S Function(S) f = s.f;
    }
  }
}

class C<S> {
  void testBoundedTypeVariable(S s) {
    // Check that `Object?` has no `f` so E is applicable, then bind `T` to `S`.
    S Function(S) f = s.f;
  }

  void testPromotedType(S s) {
    if (s is int) {
      // Check that `int` has no `f`, bind `T` to `S`.
      S Function(S) f = s.f;
    }
  }
}

void main() {
  A<int>()
    ..testBoundedTypeVariable(1)
    ..testPromotedTypeVariable(2);
  B<int>()
    ..testBoundedTypeVariable(1)
    ..testPromotedType(2);
  C<int>()
    ..testBoundedTypeVariable(1)
    ..testPromotedType(2);
}
