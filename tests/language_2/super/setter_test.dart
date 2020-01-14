// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing super setters and getters.

import "package:expect/expect.dart";

class Base {
  Base() {}
  String value_;

  String get value { return value_; }
  String set value(String newValue) { //# static warning
    value_ = 'Base:$newValue';
  }
}


class Derived extends Base {
  Derived() : super() {}

  String set value(String newValue) { //# static warning
    super.value = 'Derived:$newValue';
  }
  String get value { return super.value; }
}


class SuperSetterTest {
  static void testMain() {
    final b = new Derived();
    b.value = "foo";
    Expect.equals("Base:Derived:foo", b.value);
  }
}

main() {
  SuperSetterTest.testMain();
}
