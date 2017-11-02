// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void testCallsToGenericFn() {
  T f<T>(T a, T b) => ((a as dynamic) + b) as T;

  var x = (f as dynamic)<int>(40, 2);
  Expect.equals(x, 42);

  var y = (f as dynamic)<String>('hi', '!');
  Expect.equals(y, 'hi!');

  var dd2d = (x, y) => x;
  dd2d = f; // implicit <dynamic>
  x = (dd2d as dynamic)(40, 2);
  Expect.equals(x, 42);
  y = (dd2d as dynamic)('hi', '!');
  Expect.equals(y, 'hi!');
}

void testGenericFnAsArg() {
  h<T>(a) => a as T;
  Object foo(f(Object a), Object a) => f(a);
  Expect.throws(() => foo(h as dynamic, 42));

  var int2int = (int x) => x;
  T bar<T>(x) => x as T;
  dynamic list = <Object>[1, 2, 3];
  Expect.throws(() => list.map(bar));
  int2int = bar;
  Expect.listEquals(list.map(int2int).toList(), [1, 2, 3]);
}

typedef T2T = T Function<T>(T t);
void testGenericFnAsGenericFnArg() {
  h<T>(a) => a as T;
  S foo<S>(T2T f, S a) => f<S>(a);
  Expect.equals(foo<int>(h, 42), 42);
  Expect.equals(foo<dynamic>(h, 42), 42);
  Expect.equals(foo<int>(h as dynamic, 42), 42);
  Expect.equals(foo<dynamic>(h as dynamic, 42), 42);
}

void testGenericFnTypeToString() {
  T f<T>(T a) => a;
  Expect.equals(f.runtimeType.toString(), "<T>(T) => T");
}

main() {
  testCallsToGenericFn();
  testGenericFnAsArg();
  testGenericFnAsGenericFnArg();
  testGenericFnTypeToString();
}
