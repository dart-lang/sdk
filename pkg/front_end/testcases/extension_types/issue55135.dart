// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B implements A {
  final int x = 1;
}
abstract class A {
  int get x;
  factory A() = B;
}

extension type C._(A point) implements A {
  C() : point = A(); // << initializer is redirecting factory
}

void main() {
  expectEquals(A().x, 1);
  expectEquals(C().x, 1);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected equal values, got '${x}' and '${y}'.";
  }
}
