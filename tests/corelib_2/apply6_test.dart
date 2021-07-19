// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

// Test that the List of positional arguments to [Function.apply] is not
// modified.

import "package:expect/expect.dart";

class A {
  foo([
    a = 10,
    b = 20,
    c = 30,
    d = 40,
    e = 50,
    f = 60,
    g = 70,
    h = 80,
    i = 90,
  ]) =>
      '$a $b $c $d $e $f $g $h $i';
}

String static1(a, b, {c = 30, d = 40}) => '$a $b $c $d';

void test(String expected, Function function, List positional,
    [Map<Symbol, dynamic> named = null]) {
  final original = List.of(positional);

  Expect.equals(expected, Function.apply(function, positional, named));
  Expect.listEquals(original, positional);

  // Test again so there are multiple call sites for `Function.apply`.
  Expect.equals(expected, Function.apply(function, positional, named));
  Expect.listEquals(original, positional);
}

main() {
  var a = A();

  test('10 20 30 40 50 60 70 80 90', a.foo, []);
  test('11 20 30 40 50 60 70 80 90', a.foo, [11]);
  test('11 22 30 40 50 60 70 80 90', a.foo, [11, 22]);
  test('11 22 33 40 50 60 70 80 90', a.foo, [11, 22, 33]);
  test('11 22 33 44 50 60 70 80 90', a.foo, [11, 22, 33, 44]);
  test('11 22 33 44 55 60 70 80 90', a.foo, [11, 22, 33, 44, 55]);
  test('11 22 33 44 55 66 70 80 90', a.foo, [11, 22, 33, 44, 55, 66]);
  test('11 22 33 44 55 66 77 80 90', a.foo, [11, 22, 33, 44, 55, 66, 77]);
  test('11 22 33 44 55 66 77 88 90', a.foo, [11, 22, 33, 44, 55, 66, 77, 88]);
  test('11 22 33 44 55 66 77 88 99', a.foo,
      [11, 22, 33, 44, 55, 66, 77, 88, 99]);

  // Some unmodifiable Lists. An attempt to modify the argument would fail.
  test('11 22 33 44 55 66 77 80 90', a.foo, const [11, 22, 33, 44, 55, 66, 77]);
  test('65 66 67 68 69 70 71 80 90', a.foo, 'ABCDEFG'.codeUnits);

  test('11 22 30 40', static1, [11, 22]);
  test('11 22 30 40', static1, [11, 22], {});
  test('11 22 33 40', static1, [11, 22], {#c: 33});
  test('11 22 30 44', static1, [11, 22], {#d: 44});
  test('11 22 66 55', static1, [11, 22], {#d: 55, #c: 66});

  test('11 22 88 77', static1, const [11, 22], {#d: 77, #c: 88});
  test('65 66 11 22', static1, 'AB'.codeUnits, {#d: 22, #c: 11});
}
