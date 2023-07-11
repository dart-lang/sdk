// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that if a field of an unstable target is promoted within a cascade
// expression, that promotion isn't over-applied to uses of the field within
// subsequent cascades.

// SharedOptions=--enable-experiment=inference-update-2

import '../static_type_helper.dart';

class C {
  D get d => D(E()); // Unstable
}

class D {
  final E? _e; // Promotable
  D(this._e);
}

class E {
  void f() {}
}

void test(C c) {
  // The value of `c.d` is cached in a temporary variable, call it `t0`.
  ((c.d)
        // `t0._e` could be null at this point.
        .._e.expectStaticType<Exactly<E?>>()
        // This `!` operator ensures that `t0._e` is not null.
        .._e!.f()
        // Therefore, `t0._e` is now promoted.
        .._e.expectStaticType<Exactly<E>>())
      // This `._e` also refers to `t0._e`, so it is promoted too.
      ._e
      .expectStaticType<Exactly<E>>();
  // Now, a new value of `c.d` is computed, and cached in a new temporary
  // variable, call it `t1`.
  ((c.d)
        // Even though we are in a cascade, and field promotions of unstable targets
        // are allowed inside a cascade, the promotion above is not retained,
        // because there's no guarantee that `t0` and `t1` refer to the same
        // instance of `D`.
        .._e.expectStaticType<Exactly<E?>>()
        // However, a new promotion can still be done:
        .._e!.f()
        // And now the new promotion is in effect.
        .._e.expectStaticType<Exactly<E>>())
      ._e
      .expectStaticType<Exactly<E>>();
}

main() {
  test(C());
}
