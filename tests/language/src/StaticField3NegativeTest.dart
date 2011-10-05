// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that an instance field cannot be read as a static field.

class Foo {
  Foo() {}
  var x;
}

class StaticField3NegativeTest {
  static testMain() {
    if (false) {
      var x = Foo.x;
    }
  }
}

main() {
  StaticField3NegativeTest.testMain();
}
