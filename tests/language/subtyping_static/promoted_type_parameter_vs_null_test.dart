// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a promoted type parameter type whose promoted bound is `Never`
// is a subtype of `Null` (and of everything else).
//
// For example, if `x` has type `X`, then after `x is Null`, `x` has type
// `X & Null`, and `x!` has type `X & Never`. Similarly, if `X extends Null`,
// then `x!` has type `X & Never`.
//
// See https://github.com/dart-lang/sdk/issues/64786.

// Used so that the calls to `use` aren't dead code, and so that the code
// that follows them isn't either.
bool get alwaysFalse => false;

void use<T>(T value) {}

void promotedViaIsNull<X>(X x) {
  if (x is Null) {
    // `x!` has type `X & Never`.
    if (alwaysFalse) use<Null>(x!);
    if (alwaysFalse) use<X>(x!);
    if (alwaysFalse) use<int>(x!);
    if (alwaysFalse) use<Never>(x!);
  }
}

void boundedByNull<X extends Null>(X x) {
  // `x!` has type `X & Never`.
  if (alwaysFalse) use<Null>(x!);
  if (alwaysFalse) use<X>(x!);
  if (alwaysFalse) use<int>(x!);
  if (alwaysFalse) use<Never>(x!);
}

void main() {
  promotedViaIsNull<int?>(null);
  promotedViaIsNull<Object?>(null);
  boundedByNull<Null>(null);
}
