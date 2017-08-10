// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a parameter used in two different closures defined in a
// constructor initializer, is properly boxed.

import "package:expect/expect.dart";

class A {
  var f;
  var g;
  A(a)
      : f = (() => 42 + a),
        g = (() => ++a) {
    a = 4;
  }
}

class B extends A {
  B() : super(42);
}

class C extends A {
  var h;
  C(a)
      : h = (() => ++a),
        super(42);
}

main() {
  var a = new A(1);
  Expect.equals(46, a.f());
  Expect.equals(5, a.g());
  Expect.equals(47, a.f());

  a = new B();
  Expect.equals(46, a.f());
  Expect.equals(5, a.g());
  Expect.equals(47, a.f());

  a = new C(0);
  Expect.equals(46, a.f());
  Expect.equals(5, a.g());
  Expect.equals(47, a.f());
  Expect.equals(47, a.f());
  Expect.equals(6, a.g());
  Expect.equals(48, a.f());
}
