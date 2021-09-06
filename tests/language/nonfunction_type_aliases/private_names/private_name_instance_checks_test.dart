// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Test that private names exported via public typedefs can be used for instance
// checks

import "package:expect/expect.dart";

import "private_name_library.dart";

class Derived1 extends PublicClass {}

class Derived2 implements PublicClass {
  // Dummy implementation for the class using noSuchMethod.
  noSuchMethod(_) {}
}

void test1() {
  var d1 = Derived1();
  Expect.isTrue(d1 is Derived1);
  Expect.isTrue(d1 is PublicClass);
  Expect.isTrue(d1 is AlsoPublicClass);
  Expect.isFalse(d1 is Derived2);

  var d2 = Derived2();
  Expect.isFalse(d2 is Derived1);
  Expect.isTrue(d2 is PublicClass);
  Expect.isTrue(d2 is AlsoPublicClass);
  Expect.isTrue(d2 is Derived2);

  var p = PublicClass();
  Expect.isFalse(p is Derived1);
  Expect.isTrue(p is PublicClass);
  Expect.isTrue(p is AlsoPublicClass);
  Expect.isFalse(p is Derived2);
}

void main() {
  test1();
}
