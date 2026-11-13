// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/64912.
//
// The inliner used to inline a closure call with a known target even when
// the passed arguments didn't match the parameters of the target closure
// function. In dynamically unreachable code this resulted in instantiation
// of type parameters with a too short constant function type arguments
// vector, out-of-bounds reads of the arguments and incorrect binding of
// named arguments to positional parameters in the compiler.

// VMOptions=--optimization-counter-threshold=100 --no-background-compilation

import 'package:expect/expect.dart';

Object? sink;

// Wrong number of type arguments.

@pragma('vm:prefer-inline')
void foo1(Object f) {
  if (f is int Function<A>(int, [int])) {
    // Unreachable at runtime: f actually has 2 type parameters.
    sink = f<int>(1);
  }
}

@pragma('vm:never-inline')
int bar1() {
  final c = <A, B>(int x, [int y = 0]) {
    sink = <B>[];
    return x + y;
  };
  foo1(c);
  return c<int, String>(1);
}

// Too few positional arguments passed to a generic closure.

@pragma('vm:prefer-inline')
void foo2(Object f) {
  if (f is int Function<A>(int)) {
    // Unreachable at runtime: f actually has 2 required parameters.
    sink = f<int>(1);
  }
}

@pragma('vm:never-inline')
int bar2() {
  final c = <A>(int x, int y) {
    sink = <A>[];
    return x + y;
  };
  foo2(c);
  return c<String>(1, 2);
}

// Named argument passed to a closure without named parameters.

@pragma('vm:prefer-inline')
void foo3(Object f) {
  if (f is int Function(int, {int y})) {
    // Unreachable at runtime: f actually has no named parameters.
    sink = f(1, y: 2);
  }
}

@pragma('vm:never-inline')
int bar3() {
  final c = (int x, int z) {
    return x + z;
  };
  foo3(c);
  return c(1, 2);
}

void main() {
  for (int i = 0; i < 1000; i++) {
    Expect.equals(1, bar1());
    Expect.isTrue(sink is List<String>);
    Expect.equals(3, bar2());
    Expect.isTrue(sink is List<String>);
    Expect.equals(3, bar3());
  }
}
