// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for tree shaking of write-only late fields.
// This test requires non-nullable experiment.

// @dart = 2.10

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

// Should be removed.
late int staticLateA;

// Should be retained.
late final int staticLateB;

void main() {
  new A().use();
  new B().use();

  staticLateA = 4;
  staticLateB = 4;
}
