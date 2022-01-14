// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class I {
  void foo();
}

enum E1 implements I { // Ok.
  one,
  two;

  void foo() {}
}

enum E2 implements I { // Error.
  one,
  two
}

enum E3 implements I? { // Error.
  one,
  two;

  void foo() {}
}

enum E4 {
  one,
  two;

  void foo() {}
}

bar(I i) {}

test(E1 e1, E2 e2, E3 e3, E4 e4) {
  bar(e1); // Ok.
  bar(e2); // Ok.
  bar(e3); // Ok.
  bar(e4); // Error.
}

main() {}
