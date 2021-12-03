// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  static X foo<X>(X x) => x;
}

typedef D1<X> = A<X>;
typedef D2<X extends num> = A<X>;

test() {
  Y Function<Y>(Y) f1 = A.foo; // Ok.
  int Function(int) f2 = A.foo; // Ok.
  int Function(int) f3 = A.foo<int>; // Ok.
  int Function(int) f4 = A<int>.foo; // Error.
  var f5 = A<int>.foo; // Error.

  Y Function<Y>(Y) g1 = D1.foo; // Ok.
  int Function(int) g2 = D1.foo; // Ok.
  int Function(int) g3 = D1.foo<int>; // Ok.
  int Function(int) g4 = D1<int>.foo; // Error.
  var g5 = D1<int>.foo; // Error.

  Y Function<Y>(Y) h1 = D2.foo; // Ok.
  int Function(int) h2 = D2.foo; // Ok.
  int Function(int) h3 = D2.foo<int>; // Ok.
  int Function(int) h4 = D2<int>.foo; // Error.
  var h5 = D2<int>.foo; // Error.
}

main() {}
