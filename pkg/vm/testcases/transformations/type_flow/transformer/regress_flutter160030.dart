// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/160030.
// Verifies the result of tree shaking of mixin application when mixin
// has members with entry-point pragma.

mixin M {
  @pragma('vm:entry-point')
  static void foo() {
    print('hi');
  }
}

class Y with M {}

mixin M2 {
  @pragma('vm:entry-point')
  void bar() {
    print('hi');
  }
}

class Z with M2 {}

void main() {}
