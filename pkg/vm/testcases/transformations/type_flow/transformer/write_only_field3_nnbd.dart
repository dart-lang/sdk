// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for tree shaking of write-only late fields.

foo() {}

class A {
  // Should be replaced with setter.
  late int x;

  use() {
    x = 3;
  }
}

class B {
  // Should be retained.
  late final int x;

  use() {
    x = 3;
  }
}

class C {
  // Should be removed.
  late final int x = int.parse("1");
}

// Should be removed.
late int staticLateA;

// Should be retained.
late final int staticLateB;

// Should be removed.
late final int staticLateC = int.parse("2");

void main() {
  new A().use();
  new B().use();
  new C();

  staticLateA = 4;
  staticLateB = 4;
}
