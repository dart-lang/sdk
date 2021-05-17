// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Test that private names exported via public typedefs can be used for casts

import "package:expect/expect.dart";

import "private_name_library.dart";

class Derived1 extends PublicClass {}

class Derived2 implements PublicClass {
  noSuchMethod(_) {}
}

void test1() {
  // Test casts from a derived subclass.
  var d1 = Derived1();
  Expect.equals(d1, d1 as Derived1);
  Expect.equals(d1, d1 as PublicClass);
  Expect.equals(d1, d1 as AlsoPublicClass);
  Expect.throws(() => d1 as Derived2);

  // Test casts from a derived implementation
  var d2 = Derived2();
  Expect.throws(() => d2 as Derived1);
  Expect.equals(d2, d2 as PublicClass);
  Expect.equals(d2, d2 as AlsoPublicClass);
  Expect.equals(d2, d2 as Derived2);

  // Test casts from the exported private subclass.
  var p = PublicClass();
  Expect.throws(() => p as Derived1);
  Expect.equals(p, p as PublicClass);
  Expect.equals(p, p as AlsoPublicClass);
  Expect.throws(() => p as Derived2);
}

void main() {
  test1();
}
