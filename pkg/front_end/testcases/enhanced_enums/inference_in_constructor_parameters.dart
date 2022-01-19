// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

X foo<X>(X x) => x;

enum E1 {
  bar(foo);

  const E1(int Function(int) f);
}

enum E2<X> {
  bar(foo);

  const E2(X f);
}

enum E3<X extends num, Y extends String, Z extends Function(X, Y)> {
  element
}

main() {}
