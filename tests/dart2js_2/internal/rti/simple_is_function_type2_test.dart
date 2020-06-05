// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
//
// dart2jsOptions=--experiment-new-rti

import "package:expect/expect.dart";

int fnInt2Int(int x) => x;
int fnIntOptInt2Int(int x, [int y = 0]) => x + y;

make1<A, B>(A a) {
  return (B b) => a;
}

make2<A, B>(A a) {
  A foo(B b) => a;
  return foo;
}

class C<A> {
  final A a;
  C(this.a);
  make<B>() => (B b) => a;
  make2<B>() => (B b) => 'x';
}

main() {
  Expect.isTrue(make1<int, int>(1) is int Function(int));
  Expect.isTrue(make1<int, int>(1) is Object Function(int));
  Expect.isTrue(make1<int, int>(1) is! String Function(int));
  Expect.isTrue(make1<int, int>(1) is! int Function(String));

  Expect.isTrue(make2<int, int>(1) is int Function(int));
  Expect.isTrue(make2<int, int>(1) is Object Function(int));
  Expect.isTrue(make2<int, int>(1) is! String Function(int));
  Expect.isTrue(make2<int, int>(1) is! int Function(String));

  Expect.isTrue(C<int>(1).make<String>() is int Function(String));
  Expect.isTrue(C<int>(1).make<String>() is Object Function(String));
  Expect.isTrue(C<int>(1).make<String>() is! String Function(int));

  Expect.isTrue(C<int>(1).make2<int>() is String Function(int));
  Expect.isTrue(C<int>(1).make2<int>() is Object Function(int));
  Expect.isTrue(C<int>(1).make2<int>() is! int Function(String));
  Expect.isTrue(C<int>(1).make2<int>() is! int Function(int));
  Expect.isTrue(C<int>(1).make2<String>() is String Function(String));
  Expect.isTrue(C<int>(1).make2<String>() is Object Function(String));
  Expect.isTrue(C<int>(1).make2<String>() is! int Function(String));
  Expect.isTrue(C<int>(1).make2<String>() is! String Function(int));
}
