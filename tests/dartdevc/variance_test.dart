// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=variance

// Tests the emission of explicit variance modifiers.

import 'dart:_foreign_helper' show TYPE_REF;
import 'dart:_runtime' show getGenericArgVariances, Variance;

import 'package:expect/expect.dart';

class A<in T> {}

class B<out T> {}

class C<inout T> {}

class D<T> {}

class E<inout X, out Y, in Z> {}

mixin F<in T> {}

class G<inout T> = Object with F<T>;

List? getVariances(Object type) {
  // TODO(nshahan) Revisit when we decide if getGenericArgVariances will handle
  // legacy and nullable wrappers.
  return getGenericArgVariances(type);
}

main() {
  Expect.listEquals([Variance.contravariant], getVariances(TYPE_REF<A>())!);

  Expect.listEquals([Variance.covariant], getVariances(TYPE_REF<B>())!);

  Expect.listEquals([Variance.invariant], getVariances(TYPE_REF<C>())!);

  // Implicit variance is not emitted into the generated code.
  Expect.isNull(getVariances(TYPE_REF<D>()));

  Expect.listEquals(
      [Variance.invariant, Variance.covariant, Variance.contravariant],
      getVariances(TYPE_REF<E>())!);

  Expect.listEquals([Variance.contravariant], getVariances(TYPE_REF<F>())!);

  Expect.listEquals([Variance.invariant], getVariances(TYPE_REF<G>())!);
}
