// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that an instance method cannot be set as a static field.

class Foo {
  Foo() {}
  void m() {}
}

class StaticField4aNegativeTest {
  static testMain() {
    if (false) {
      Foo.m = 1;
    }
  }
}

main() {
  StaticField4aNegativeTest.testMain();
}
