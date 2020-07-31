// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

typedef MapFunc<S1, S2> = void Function(Map<S1, S2>? arg);

class A<P> {
  final List barTypeArguments = [];

  void foo<Q, Q1 extends P, Q2 extends Q, Q3 extends P, Q4 extends Q>() {
    void bar<T1 extends P, T2 extends Q>(Map<T1, T2>? arg) {
      barTypeArguments..add(T1)..add(T2);
    }

    // Call with explicit type arguments.
    bar<Q1, Q2>(null);

    // No explicit type arguments - should be instantiated to bounds.
    bar(null);

    // Partial tear-off instantiation.
    MapFunc<Q3, Q4> instantiated = bar;
    instantiated(null);
  }
}

abstract class MyIterable implements Iterable {}

main() {
  final a = new A<num>();
  a.foo<Iterable, int, List, double, MyIterable>();
  Expect.listEquals(
      [int, List, num, Iterable, double, MyIterable], a.barTypeArguments);

  // Test instantiation to bounds in the enclosing method.
  dynamic b = new A<int>();
  b.foo();
  Expect.listEquals(
      [int, dynamic, int, dynamic, int, dynamic], b.barTypeArguments);
}
