// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// SharedOptions=--enable-experiment=variance

// Tests the emission of explicit variance modifiers.

import 'dart:_runtime' as dart;

import 'package:expect/expect.dart';

class A<in T> {}

class B<out T> {}

class C<inout T> {}

class D<T> {}

class E<inout X, out Y, in Z> {}

mixin F<in T> {}

class G<inout T> = Object with F<T>;

List getVariances(Type typeWrapped) {
  var type = dart.unwrapType(typeWrapped);
  return dart.getGenericArgVariances(type);
}

main() {
  Expect.listEquals([dart.Variance.contravariant], getVariances(A));

  Expect.listEquals([dart.Variance.covariant], getVariances(B));

  Expect.listEquals([dart.Variance.invariant], getVariances(C));

  // Implicit variance is not emitted into the generated code.
  Expect.isNull(getVariances(D));

  Expect.listEquals([
    dart.Variance.invariant,
    dart.Variance.covariant,
    dart.Variance.contravariant
  ], getVariances(E));

  Expect.listEquals([dart.Variance.contravariant], getVariances(F));

  Expect.listEquals([dart.Variance.invariant], getVariances(G));
}
