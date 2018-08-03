// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class InstanceofTest {
  InstanceofTest() {}

  static void testBasicTypes() {
    Expect.equals(true, 0 is int);
    Expect.equals(false, (0 is bool));
    Expect.equals(false, (0 is String));
    Expect.equals(true, 1 is int);
    Expect.equals(false, (1 is bool));
    Expect.equals(false, (1 is String));

    Expect.equals(false, (true is int));
    Expect.equals(true, true is bool);
    Expect.equals(false, (true is String));
    Expect.equals(false, (false is int));
    Expect.equals(true, false is bool);
    Expect.equals(false, (false is String));

    Expect.equals(false, ("a" is int));
    Expect.equals(false, ("a" is bool));
    Expect.equals(true, "a" is String);

    Expect.equals(false, ("" is int));
    Expect.equals(false, ("" is bool));
    Expect.equals(true, "" is String);
  }

  static void testInterfaces() {
    // Simple Cases with interfaces.
    var a = new A();
    Expect.equals(true, a is I);
    Expect.equals(true, a is A);
    Expect.equals(false, (a is String));
    Expect.equals(false, (a is int));
    Expect.equals(false, (a is bool));
    Expect.equals(false, (a is B));
    Expect.equals(false, (a is J));

    // Interfaces with parent
    var c = new C();
    Expect.equals(true, c is I);
    Expect.equals(true, c is J);
    Expect.equals(true, c is K);

    var d = new D();
    Expect.equals(true, d is I);
    Expect.equals(true, d is J);
    Expect.equals(true, d is K);

    Expect.equals(true, [] is List);
    Expect.equals(true, [1, 2, 3] is List);
    Expect.equals(false, (d is List));
    Expect.equals(false, (null is List));
    Expect.equals(false, (null is D));
  }

  static void testnum() {
    Expect.equals(true, 0 is num);
    Expect.equals(true, 123 is num);
    Expect.equals(true, 123.34 is num);
    Expect.equals(false, ("123" is num));
    Expect.equals(false, (null is num));
    Expect.equals(false, (true is num));
    Expect.equals(false, (false is num));
    var a = new A();
    Expect.equals(false, (a is num));
  }

  static void testTypeOfInstanceOf() {
    var a = new A();
    // Interfaces with parent
    var c = new C();
    var d = new D();

    Expect.equals(true, (null is int) is bool);
    Expect.equals(true, (null is bool) is bool);
    Expect.equals(true, (null is String) is bool);
    Expect.equals(true, (null is A) is bool);
    Expect.equals(true, (null is B) is bool);
    Expect.equals(true, (null is I) is bool);
    Expect.equals(true, (null is J) is bool);

    Expect.equals(true, (0 is int) is bool);
    Expect.equals(true, (0 is bool) is bool);
    Expect.equals(true, (0 is String) is bool);
    Expect.equals(true, (0 is A) is bool);
    Expect.equals(true, (0 is B) is bool);
    Expect.equals(true, (0 is I) is bool);
    Expect.equals(true, (0 is J) is bool);

    Expect.equals(true, (1 is int) is bool);
    Expect.equals(true, (1 is bool) is bool);
    Expect.equals(true, (1 is String) is bool);
    Expect.equals(true, (1 is A) is bool);
    Expect.equals(true, (1 is B) is bool);
    Expect.equals(true, (1 is I) is bool);
    Expect.equals(true, (1 is J) is bool);

    Expect.equals(true, (true is int) is bool);
    Expect.equals(true, (true is bool) is bool);
    Expect.equals(true, (true is String) is bool);
    Expect.equals(true, (true is A) is bool);
    Expect.equals(true, (true is B) is bool);
    Expect.equals(true, (true is I) is bool);
    Expect.equals(true, (true is J) is bool);

    Expect.equals(true, (false is int) is bool);
    Expect.equals(true, (false is bool) is bool);
    Expect.equals(true, (false is String) is bool);
    Expect.equals(true, (false is A) is bool);
    Expect.equals(true, (false is B) is bool);
    Expect.equals(true, (false is I) is bool);
    Expect.equals(true, (false is J) is bool);

    Expect.equals(true, ("a" is int) is bool);
    Expect.equals(true, ("a" is bool) is bool);
    Expect.equals(true, ("a" is String) is bool);
    Expect.equals(true, ("a" is A) is bool);
    Expect.equals(true, ("a" is B) is bool);
    Expect.equals(true, ("a" is I) is bool);
    Expect.equals(true, ("a" is J) is bool);

    Expect.equals(true, ("" is int) is bool);
    Expect.equals(true, ("" is bool) is bool);
    Expect.equals(true, ("" is String) is bool);
    Expect.equals(true, ("" is A) is bool);
    Expect.equals(true, ("" is B) is bool);
    Expect.equals(true, ("" is I) is bool);
    Expect.equals(true, ("" is J) is bool);

    Expect.equals(true, (a is int) is bool);
    Expect.equals(true, (a is bool) is bool);
    Expect.equals(true, (a is String) is bool);
    Expect.equals(true, (a is A) is bool);
    Expect.equals(true, (a is B) is bool);
    Expect.equals(true, (a is I) is bool);
    Expect.equals(true, (a is J) is bool);

    Expect.equals(true, (c is int) is bool);
    Expect.equals(true, (c is bool) is bool);
    Expect.equals(true, (c is String) is bool);
    Expect.equals(true, (c is A) is bool);
    Expect.equals(true, (c is B) is bool);
    Expect.equals(true, (c is I) is bool);
    Expect.equals(true, (c is J) is bool);

    Expect.equals(true, (d is int) is bool);
    Expect.equals(true, (d is bool) is bool);
    Expect.equals(true, (d is String) is bool);
    Expect.equals(true, (d is A) is bool);
    Expect.equals(true, (d is B) is bool);
    Expect.equals(true, (d is I) is bool);
    Expect.equals(true, (d is J) is bool);
  }

  static void testMain() {
    testBasicTypes();
    // TODO(sra): enable after fixing b/4604295
    // testnum();
    testInterfaces();
    testTypeOfInstanceOf();
  }
}

abstract class I {}

class A implements I {
  A() {}
}

class B {
  B() {}
}

abstract class J {}

abstract class K implements J {}

class C implements I, K {
  C() {}
}

class D extends C {
  D() : super() {}
}

main() {
  // Repeat type checks so that inlined tests can be tested as well.
  for (int i = 0; i < 5; i++) {
    InstanceofTest.testMain();
  }
}
