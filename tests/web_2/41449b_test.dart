// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// This test is the same as 41449a_test.dart without forcing `-O0`.
//
// Regression test for passing type parameters through call-through stub.
//
// We use an abstract class with two implementations to avoid the optimizer
// 'inlining' the call-through stub, so we are testing that the stub itself
// passes through the type parameters.

import 'package:expect/expect.dart';

abstract class AAA {
  dynamic get foo;
}

class B1 implements AAA {
  final dynamic foo;
  B1(this.foo);
}

class B2 implements AAA {
  final dynamic _arr;
  B2(foo) : _arr = [foo];
  dynamic get foo => _arr.first;
}

class B3 implements AAA {
  final dynamic __foo;
  B3(this.__foo);
  dynamic get _foo => __foo;
  dynamic get foo => _foo;
}

@pragma('dart2js:noInline')
test1<T>(AAA a, String expected) {
  // call-through getter 'foo' with one type argument.
  Expect.equals(expected, a.foo<T>());
}

@pragma('dart2js:noInline')
test2<U, V>(AAA a, String expected) {
  // call-through getter 'foo' with two type arguments.
  Expect.equals(expected, a.foo<U, V>());
}

main() {
  test1<int>(B1(<P>() => '$P'), 'int');
  test1<num>(B2(<Q>() => '$Q'), 'num');
  test1<double>(B3(<R>() => '$R'), 'double');

  test2<int, num>(B1(<A, B>() => '$A $B'), 'int num');
  test2<num, int>(B2(<X, Y>() => '$X $Y'), 'num int');
  test2<double, String>(B3(<C, D>() => '$C $D'), 'double String');
}
