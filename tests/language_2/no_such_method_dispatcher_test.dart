// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Test that noSuchMethod dispatching and auto-closurization work correctly.

class A {
  noSuchMethod(m) {
    return 123;
  }

  bar(x) => x + 1;
}

class B extends A {}

class C {
  C(this.pos, this.named, this.posArgs, this.namedArgs);
  var pos, named;
  noSuchMethod(m) {
    Expect.equals(pos, m.positionalArguments.length);
    Expect.equals(named, m.namedArguments.length);
    for (var i = 0; i < posArgs.length; ++i) {
      Expect.equals(posArgs[i], m.positionalArguments[i]);
    }
    for (var k in namedArgs.keys) {
      Expect.equals(namedArgs[k], m.namedArguments[new Symbol(k)]);
    }
    return 123;
  }

  List posArgs;
  Map namedArgs;
}

main() {
  var a = new A() as dynamic;
  for (var i = 0; i < 20; ++i) Expect.equals(123, a.foo());
  Expect.throws(() => (a.foo)());
  Expect.equals("123", (a.foo).toString());

  var b = new B() as dynamic;
  for (var i = 0; i < 20; ++i) {
    Expect.equals(2, b.bar(1));
    Expect.equals(123, b.bar());
    Expect.equals(2, b.bar(1));
  }

  for (var i = 0; i < 20; ++i) {
    Expect.equals(123, b.bar(1, 2, 3));
    Expect.equals(123, b.bar(1, 2, foo: 3));
  }

  // Test named and positional arguments.
  var c = new C(1, 2, [100], {"n1": 101, "n2": 102}) as dynamic;
  for (var i = 0; i < 20; ++i) {
    Expect.equals(123, c.bar(100, n1: 101, n2: 102));
    Expect.equals(123, c.bar(100, n2: 102, n1: 101));
  }
}
