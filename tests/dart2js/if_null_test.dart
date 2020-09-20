// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

main(args) {
  dynamic x = new A();
  var y;

  // Checks that inference doesn't incorrectly treat this as a normal
  // assignment (where only B is a possible value after the assignment).
  dynamic c = x ??= new B();
  var z = x;
  Expect.equals('a', x.m());
  Expect.equals('a', z.m());
  Expect.equals('a', c.m());
  if (confuse(true)) y = x;
  Expect.equals('a', y.m());

  // Similar test, within fields.
  new C();
  new D();
}

class A {
  m() => 'a';
}

class B {
  m() => 'b';
}

class C {
  var y;
  C() {
    y = new A();
    var c = y ??= new B();
    Expect.equals('a', y.m());
    Expect.equals('a', c.m());
  }
}

class D {
  var y;
  D() {
    this.y = new A();
    var c = this.y ??= new B();
    Expect.equals('a', y.m());
    Expect.equals('a', c.m());
  }
}
