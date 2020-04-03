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

void checkVariances(List v1, List v2) {
  Expect.equals(v1.length, v2.length);
  for (int i = 0; i < v1.length; i++) {
    Expect.equals(v1[i], v2[i]);
  }
}

main() {
  checkVariances(getVariances(A), [dart.Variance.contravariant]);

  checkVariances(getVariances(B), [dart.Variance.covariant]);

  checkVariances(getVariances(C), [dart.Variance.invariant]);

  // Implicit variance is not emitted into the generated code.
  Expect.isNull(getVariances(D));

  checkVariances(getVariances(E), [dart.Variance.invariant, dart.Variance.covariant, dart.Variance.contravariant]);

  checkVariances(getVariances(F), [dart.Variance.contravariant]);

  checkVariances(getVariances(G), [dart.Variance.invariant]);
}
