// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that when the `promotion-chain-intersection-join` feature flag is
// disabled, promoting a property whose target has been promoted doesn't discard
// any types from the property's promotion chain. See
// https://github.com/dart-lang/sdk/issues/64799.

// @dart=3.14

import 'package:expect/static_type_helper.dart';

class C<T> {
  final T? _f;
  C(this._f);
}

abstract interface class A {}

abstract interface class B {}

class AB implements A, B {}

void unrelatedPromotionKeptAfterJoin(C<Object?> x) {
  if (x._f is! A) return;
  if (x is C<B> && x._f != null) {
    // The promotion chain is now `[A, B]`.
    x._f.expectStaticType<Exactly<B>>();
  }
  // Joining `[A, B]` with `[A]` produces `[A]`.
  x._f.expectStaticType<Exactly<A>>();
}

void main() {
  for (var x in [C<Object?>(null), C<Object?>(AB()), C<B>(AB())]) {
    unrelatedPromotionKeptAfterJoin(x);
  }
}
