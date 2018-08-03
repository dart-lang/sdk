// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class Derived<T> implements Future<T> {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FixedPoint<T> implements Future<FixedPoint<T>> {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// TODO(vsm): Restore when https://github.com/dart-lang/sdk/issues/25611
// is fixed.
/*
class Divergent<T> implements Future<Divergent<Divergent<T>>> {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
*/

test() async {
  // flatten(Derived<int>) = int
  int x = await new Derived<int>(); //# 01: runtime error
  Future<int> f() async => new Derived<int>(); //# 02: ok
  Future<int> f() async { return new Derived<int>(); } //# 03: ok
  Future<int> x = (() async => new Derived<int>())(); //# 04: runtime error

  // TODO(vsm): Restore when https://github.com/dart-lang/sdk/issues/25611
  // is fixed.
  /*
  // flatten(FixedPoint<int>) = FixedPoint<int>
  FixedPoint<int> x = await new FixedPoint<int>(); //# 05: runtime error
  Future<FixedPoint<int>> f() async => new FixedPoint<int>(); //# 06: ok
  Future<FixedPoint<int>> f() async { return new FixedPoint<int>(); } //# 07: ok
  Future<FixedPoint<int>> x = (() async => new FixedPoint<int>())(); //# 08: runtime error

  // flatten(Divergent<int>) = Divergent<Divergent<int>>
  Divergent<Divergent<int>> x = await new Divergent<int>(); //# 09: runtime error
  Future<Divergent<Divergent<int>>> f() async => new Divergent<int>(); //# 10: ok
  Future<Divergent<Divergent<int>>> f() async { return new Divergent<int>(); } //# 11: ok
  Future<Divergent<Divergent<int>>> x = (() async => new Divergent<int>())(); //# 12: runtime error
  */
}

main() {
  test();
}
