// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that an instance method cannot be read as a static field.

class Foo {
  Foo() {}
  void m() {}
}

class StaticField3aNegativeTest {
  static testMain() {
    if (false) {
      var m = Foo.m;
    }
  }
}

main() {
  StaticField3aNegativeTest.testMain();
}
