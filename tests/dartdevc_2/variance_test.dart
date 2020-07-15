// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// SharedOptions=--enable-experiment=variance

// Tests the emission of explicit variance modifiers.

import 'dart:_runtime'
    show getGenericArgVariances, Variance, legacyTypeRep;

import 'package:expect/expect.dart';

class A<in T> {}

class B<out T> {}

class C<inout T> {}

class D<T> {}

class E<inout X, out Y, in Z> {}

mixin F<in T> {}

class G<inout T> = Object with F<T>;

List getVariances(dynamic type) {
  // TODO(nshahan) Revisit when we decide if getGenericArgVariances will handle
  // legacy and nullable wrappers.
  return getGenericArgVariances(type.type);
}

main() {
  Expect.listEquals([Variance.contravariant], getVariances(legacyTypeRep<A>()));

  Expect.listEquals([Variance.covariant], getVariances(legacyTypeRep<B>()));

  Expect.listEquals([Variance.invariant], getVariances(legacyTypeRep<C>()));

  // Implicit variance is not emitted into the generated code.
  Expect.isNull(getVariances(legacyTypeRep<D>()));

  Expect.listEquals(
      [Variance.invariant, Variance.covariant, Variance.contravariant],
      getVariances(legacyTypeRep<E>()));

  Expect.listEquals([Variance.contravariant], getVariances(legacyTypeRep<F>()));

  Expect.listEquals([Variance.invariant], getVariances(legacyTypeRep<G>()));
}
