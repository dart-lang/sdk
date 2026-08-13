// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

assertRightSubtype(dynamic x) {
  x as Set<Object?>;
}

assertLeftSubtype<X>(X x) {
  new Set<Object?>() as X;
}

class C<X extends Object?, Y extends Object> {
  test(X x, Y? y) {
    var v = {x, 42}; // Checking UP(X, int).
    var w = {42, x}; // Checking UP(int, X).
    var p = {y, 42}; // Checking UP(Y?, int).
    var q = {42, y}; // Checking UP(int, Y?).

    // Check that variable types are both subtype and supertype of Set<Object?>.
    assertRightSubtype(v);
    assertLeftSubtype(v);
    assertRightSubtype(w);
    assertLeftSubtype(w);
    assertRightSubtype(p);
    assertLeftSubtype(p);
    assertRightSubtype(q);
    assertLeftSubtype(q);

    // Check the same for intersection types.
    if (x is Object?) {
      var v = {x, 42}; // Checking UP(X & Object?, int).
      var w = {42, x}; // Checking UP(int, X & Object?).

      assertRightSubtype(v);
      assertLeftSubtype(v);
      assertRightSubtype(w);
      assertLeftSubtype(w);
    }
  }
}

main() {
  new C<int?, int>().test(42, null);
  new C<int?, int>().test(null, null);
}
