// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler doesn't crash when compiling
// implicit getter with unboxed return value.
// Regression test for https://github.com/dart-lang/sdk/issues/52449.

abstract class A {
  (int, int) get foo;
}

class B implements A {
  (int, int) get foo => (1, 2);
}

class C implements A {
  final (int, int) foo;
  C(this.foo);
}

void main() {
  final list = [B(), C((3, 4))];
  for (var e in list) {
    print(e.foo);
  }
}
