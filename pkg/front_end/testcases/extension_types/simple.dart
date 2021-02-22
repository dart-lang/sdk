// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo<X> {}
class Bar<X, Y> {}

extension A1 on dynamic {}
A1 foo1(A1 a) => throw 42;

extension A2<X> on Foo<X> {}
A2 foo2(A2<int> a, A2 ai) => throw 42;

extension A3<X, Y extends Function(X)> on Bar<X, Y> {}
A3 foo3(A3<int, Function(num)> a, A3 ai) => throw 42;

extension A4<X, Y extends Function(X)> on Foo<Y> {}
A4 foo4(A4<int, Function(num)> a, A4 ai) => throw 42;

bar() {
  A1 a1;
  A2<int> a2;
  A2 a2i;
  A3<int, Function(num)> a3;
  A3 a3i;
  A4<int, Function(num)> a4;
  A4 a4i;
}

main() {}
