// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

typedef MapFunc<S1, S2> = void Function(Map<S1, S2>? arg);

class A<P> {
  final List barTypeArguments = [];

  void foo<Q, Q1 extends P, Q2 extends Q, Q3 extends P, Q4 extends Q>() {
    void bar<T1 extends P, T2 extends Q>(Map<T1, T2>? arg) {
      barTypeArguments
        ..add(T1)
        ..add(T2);
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

class B<Z, P> {
  final List barTypeArguments = [];

  void foo<Q, Q1 extends P, Q2 extends Q1, Q3 extends Z>() {
    void bar<T1 extends Map<Q1, T2>, T2 extends List<Q1>, T3 extends Z,
        T4 extends Q>(Map<T1, T2>? arg) {
      barTypeArguments
        ..add(T1)
        ..add(T2)
        ..add(T3)
        ..add(T4);
    }

    // Call with explicit type arguments.
    bar<Map<Q1, List<Q2>>, List<Q1>, Q3, Q>(null);

    // Partial tear-off instantiation.
    MapFunc<Map<Q2, List<Q1>>, List<Q1>> instantiated = bar;
    instantiated(null);
  }
}

class C<P> {
  final List barTypeArguments = [];

  void foo<Q1>() {
    void bar<T1>(List<T1>? arg) {
      void bar2<T2 extends Map<Q1, T1>>(List<T2>? arg) {
        barTypeArguments..add(T2);
      }

      dynamic f = bar2;
      f(null);
    }

    // Call with explicit type arguments.
    bar<int>(null);
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

  final c = new B<String, num>();
  c.foo<Iterable, num, int, String>();
  Expect.listEquals([
    Map<num, List<int>>,
    List<num>,
    String,
    Iterable,
    Map<int, List<num>>,
    List<num>,
    String,
    Iterable,
  ], c.barTypeArguments);

  // Test instantiation to bounds in the enclosing method.
  dynamic d = new B<int, String>();
  d.foo();
  Expect.listEquals([
    Map<String, List<String>>,
    List<String>,
    int,
    dynamic,
    Map<String, List<String>>,
    List<String>,
    int,
    dynamic,
  ], d.barTypeArguments);

  final e = new C<int>();
  e.foo<num>();
  Expect.listEquals([Map<num, int>], e.barTypeArguments);
}
