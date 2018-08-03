// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing the instanceof operation.

import "package:expect/expect.dart";

abstract class I {}

abstract class AI implements I {}

class A implements AI {
  const A();
}

class B implements I {
  const B();
}

class C extends A {
  const C() : super();
}

class InstanceofTest {
  static testMain() {
    var a = new A();
    var b = new B();
    var c = new C();
    var n = null;

    Expect.equals(true, a is A);
    Expect.equals(true, b is B);
    Expect.equals(true, c is C);
    Expect.equals(true, c is A);

    Expect.equals(true, a is AI);
    Expect.equals(true, a is I);
    Expect.equals(false, b is AI);
    Expect.equals(true, b is I);
    Expect.equals(true, c is AI);
    Expect.equals(true, c is I);
    Expect.equals(false, n is AI);
    Expect.equals(false, n is I);

    Expect.equals(false, a is B);
    Expect.equals(false, a is C);
    Expect.equals(false, b is A);
    Expect.equals(false, b is C);
    Expect.equals(false, c is B);
    Expect.equals(false, n is A);

    Expect.equals(false, null is A);
    Expect.equals(false, null is B);
    Expect.equals(false, null is C);
    Expect.equals(false, null is AI);
    Expect.equals(false, null is I);

    {
      var a = new List(5);
      Expect.equals(true, a is List);
      Expect.equals(true, a is List<Object>);
      Expect.equals(false, a is List<int>);
      Expect.equals(false, a is List<num>);
      Expect.equals(false, a is List<String>);
    }
    {
      var a = new List<Object>(5);
      Expect.equals(true, a is List);
      Expect.equals(true, a is List<Object>);
      Expect.equals(false, a is List<int>);
      Expect.equals(false, a is List<num>);
      Expect.equals(false, a is List<String>);
    }
    {
      var a = new List<int>(5);
      Expect.equals(true, a is List);
      Expect.equals(true, a is List<Object>);
      Expect.equals(true, a is List<int>);
      Expect.equals(true, a is List<num>);
      Expect.equals(false, a is List<String>);
    }
    {
      var a = new List<num>(5);
      Expect.equals(true, a is List);
      Expect.equals(true, a is List<Object>);
      Expect.equals(false, a is List<int>);
      Expect.equals(true, a is List<num>);
      Expect.equals(false, a is List<String>);
    }
    {
      var a = new List<String>(5);
      Expect.equals(true, a is List);
      Expect.equals(true, a is List<Object>);
      Expect.equals(false, a is List<int>);
      Expect.equals(false, a is List<num>);
      Expect.equals(true, a is List<String>);
    }
  }
}

main() {
  // Repeat type checks so that inlined tests can be tested as well.
  for (int i = 0; i < 5; i++) {
    InstanceofTest.testMain();
  }
}
