// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using conditional expressions.

/// Ensures a context type of `Iterable<T>` for the operand, or `Iterable<_>` if
/// no type argument is supplied.
Iterable<T> contextIterable<T>(Iterable<T> x) => x;

class A {}

class B1<T> implements A {}

class B2<T> implements A {}

class C1<T> implements B1<T>, B2<T> {}

class C2<T> implements B1<T>, B2<T> {}

/// Ensures a context type of `B1<T>` for the operand, or `B1<_>` if no type
/// argument is supplied.
B1<T> contextB1<T>(B1<T> x) => x;

test(int i) {
  var c1Int = C1<int>();
  var c2Double = C2<double>();
  contextB1(switch (i) { 0 => c1Int, _ => c2Double });

  var iterableInt = <int>[] as Iterable<int>;
  var listNum = <num>[];
  contextIterable<num>(switch (i) { 0 => iterableInt, _ => listNum });
}

main() {
  test(0);
  test(1);
  test(2);
}
