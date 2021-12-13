// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for https://github.com/dart-lang/sdk/issues/47698.

// Exposes a class field.
class A {
  int i;
  A(this.i);
}

// Exposes a getter/setter pair.
class B {
  int _j;
  int get j => _j;
  set j(int x) => _j = x;
  B(this._j);
}

// A super class field used in constructor as getter and setter.
class C extends A {
  C(int val) : super(val) {
    var x = super.i + 10; // Getter is used first.
    super.i = x + 100; // Boom! Missing setter.
  }
}

class D extends A {
  D(int val) : super(val) {
    super.i = 100; // Setter is used first.
    super.i = super.i + 10 + val; // Boom! Missing getter.
  }
}

// Actual super getter and setter used in constructor
class E extends B {
  E(int val) : super(val) {
    var x = super.j + 10; // Getter is used first.
    super.j = x + 100; // Boom! Missing setter.
  }
}

class F extends B {
  F(int val) : super(val) {
    super.j = 100; // Setter is used first.
    super.j = super.j + 10 + val; // Boom! Missing getter.
  }
}

void main() {
  var c = C(1);
  Expect.equals(c.i, 111);
  var d = D(1);
  Expect.equals(d.i, 111);
  var e = E(1);
  Expect.equals(e.j, 111);
  var f = F(1);
  Expect.equals(f.j, 111);
}
