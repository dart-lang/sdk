// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

import 'package:expect/expect.dart';

// This needs one-arg instantiation.
@pragma('dart2js:noInline')
T f1a<T>(T t) => t;

// This needs no instantiation because it is not closurized.
@pragma('dart2js:noInline')
T f1b<T>(T t1, T t2) => t1;

class Class {
  // This needs two-arg instantiation.
  @pragma('dart2js:noInline')
  bool f2a<T, S>(T t, S s) => t == s;

  // This needs no instantiation because it is not closurized.
  @pragma('dart2js:noInline')
  bool f2b<T, S>(T t, S s1, S s2) => t == s1;
}

@pragma('dart2js:noInline')
int method1(int i, int Function(int) f) => f(i);

@pragma('dart2js:noInline')
bool method2(int a, int b, bool Function(int, int) f) => f(a, b);

@pragma('dart2js:noInline')
int method3(int a, int b, int c, int Function(int, int, int) f) => f(a, b, c);

main() {
  // This needs three-arg instantiation.
  T local1<T, S, U>(T t, S s, U u) => t;

  // This needs no instantiation because but a local function is always
  // closurized so we assume it does.
  T local2<T, S, U>(T t, S s, U u1, U u2) => t;

  Expect.equals(42, method1(42, f1a));
  Expect.equals(f1b(42, 87), 42);

  Class c = new Class();
  Expect.isFalse(method2(0, 1, c.f2a));
  Expect.isFalse(c.f2b(42, 87, 123));

  Expect.equals(0, method3(0, 1, 2, local1));
  Expect.equals(42, local2(42, 87, 123, 256));
}
