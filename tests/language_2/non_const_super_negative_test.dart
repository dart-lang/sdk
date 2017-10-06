// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check fails because const class extends from non const class.

class Base {
  Base() {}
}

class Sub extends Base {
  const Sub(a) : a_ = a;
  final a_;
}

class NonConstSuperNegativeTest {
  static testMain() {
    var a = new Sub();
  }
}

main() {
  NonConstSuperNegativeTest.testMain();
}
