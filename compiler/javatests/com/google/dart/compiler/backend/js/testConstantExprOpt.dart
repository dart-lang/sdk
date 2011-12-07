// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  const Foo();
}

class A {
  static final int C1 = 10 + C2 * 2; // 20
  static final int C2 = 5;
  static final Foo C3 = const Foo();
  static int foo() { return 1; }
}

class Main {
  static void main() {
    int _marker_0, _marker_1, _marker_2;
    Foo _marker_3;

    final int x = 50;

    _marker_0 = x * 2;

    _marker_1 = A.C1 + 5;

    _marker_2 = 5 + A.C2;

    _marker_3 = A.C3;
  }
}

main() {
  Main.main();
}
