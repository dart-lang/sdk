// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that an instance field cannot be set as a static field.

class Foo {
  Foo() {}
  var x;
}

class StaticField4NegativeTest {
  static testMain() {
    if (false) {
      Foo.x = 1;
    }
  }
}

main() {
  StaticField4NegativeTest.testMain();
}
