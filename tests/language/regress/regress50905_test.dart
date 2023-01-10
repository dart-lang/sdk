// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that constructor tear-off of a generic class
// has a correct type and can be called via Function.apply.
//
// Regression test for https://github.com/dart-lang/sdk/issues/50905.

import 'package:expect/expect.dart';

class A<T> {
  A({required T Function() x}) {
    Expect.equals(f1, x);
  }
}

class B<T> {
  B({required Map<S, T> Function<S>() x}) {
    Expect.equals(f2, x);
  }
}

int f1() => 0;
Map<U, int> f2<U>() => {};

A<V> t1<V>({required V Function() x}) => throw 'unused';
A<int> t2({required int Function() x}) => throw 'unused';
B<V> t3<V>({required Map<U, V> Function<U>() x}) => throw 'unused';
B<int> t4({required Map<U, int> Function<U>() x}) => throw 'unused';

void main() {
  Function c1 = A.new;
  Expect.equals(t1.runtimeType.toString(), c1.runtimeType.toString());

  Function c2 = A<int>.new;
  Expect.equals(t2.runtimeType.toString(), c2.runtimeType.toString());
  final o2 = Function.apply(c2, [], {#x: f1});
  Expect.isTrue(o2 is A<int>);

  Function c3 = B.new;
  Expect.equals(t3.runtimeType.toString(), c3.runtimeType.toString());

  Function c4 = B<int>.new;
  Expect.equals(t4.runtimeType.toString(), c4.runtimeType.toString());
  final o4 = Function.apply(c4, [], {#x: f2});
  Expect.isTrue(o4 is B<int>);
}
