// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong
import "package:expect/expect.dart";

main() {
  // Pre-NNBD bottom type.
  int Function(Null) f = (x) => 1; // Runtime type is int Function(Object?)
  Expect.isTrue(f is int Function(Null));
  Expect.isTrue(f is int Function(Never));
  Expect.isTrue(f is int Function(String));
  Expect.isTrue(f is int Function(Object));
  Expect.isTrue(f is int Function(Object?));

  // NNBD bottom type.
  int Function(Never) g = (x) => 1; // Runtime type is int Function(Object?)
  Expect.isTrue(g is int Function(Null));
  Expect.isTrue(g is int Function(Never));
  Expect.isTrue(g is int Function(String));
  Expect.isTrue(g is int Function(Object));
  Expect.isTrue(g is int Function(Object?));

  int Function(String) h = (x) => 1; // Runtime type is int Function(String)
  Expect.isFalse(h is int Function(Null));
  Expect.isTrue(h is int Function(Never));
  Expect.isTrue(h is int Function(String));
  Expect.isFalse(h is int Function(Object));
  Expect.isFalse(h is int Function(Object?));

  int Function(Null) i = (Null x) => 1; // Runtime type is int Function(Null)
  Expect.isTrue(i is int Function(Null));
  Expect.isTrue(i is int Function(Never));
  Expect.isFalse(i is int Function(String));
  Expect.isFalse(i is int Function(Object));
  Expect.isFalse(i is int Function(Object?));

  int Function(Never) j = (Never x) => 1; // Runtime type is int Function(Never)
  Expect.isFalse(j is int Function(Null));
  Expect.isTrue(j is int Function(Never));
  Expect.isFalse(j is int Function(String));
  Expect.isFalse(j is int Function(Object));
  Expect.isFalse(j is int Function(Object?));

  // Test that the criteria used for weakening the parameter type
  // is that the downwards context parameter type is a subtype of Null
  void test<X extends Null, Y extends Never>() {
    int Function(X) f = (x) => 1; // Runtime type is int Function(Object?)
    Expect.isTrue(f is int Function(Null));
    Expect.isTrue(f is int Function(Never));
    Expect.isTrue(f is int Function(String));
    Expect.isTrue(f is int Function(Object));
    Expect.isTrue(f is int Function(Object?));

    int Function(Y) g = (x) => 1; // Runtime type is int Function(Object?)
    Expect.isTrue(g is int Function(Null));
    Expect.isTrue(g is int Function(Never));
    Expect.isTrue(g is int Function(String));
    Expect.isTrue(g is int Function(Object));
    Expect.isTrue(g is int Function(Object?));
  }

  test<Null, Never>();
  test<Never, Never>();
}
