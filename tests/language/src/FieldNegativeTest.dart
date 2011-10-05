// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch that we do not override fields.

class A {
  var a_;
  var b_;
}

class B extends A {
  var b_;
  var c_;
}

class FieldNegativeTest {
  static testMain() {
  }
}

main() {
  FieldNegativeTest.testMain();
}
