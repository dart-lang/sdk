// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--reify-generic-functions --optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Test that noSuchMethod dispatching and auto-closurization work correctly
// with generic functions.

class A {
  noSuchMethod(m) {
    return 123;
  }

  bar<U, V>(x) => x + 1;
}

class B extends A {}

class C {
  C(this.typeArgs, this.posArgs, this.namedArgs);
  List typeArgs;
  List posArgs;
  Map namedArgs;
  noSuchMethod(m) {
    Expect.equals(typeArgs.length, m.typeArguments.length);
    for (var i = 0; i < typeArgs.length; ++i) {
      Expect.equals(typeArgs[i], m.typeArguments[i]);
    }
    Expect.equals(posArgs.length, m.positionalArguments.length);
    for (var i = 0; i < posArgs.length; ++i) {
      Expect.equals(posArgs[i], m.positionalArguments[i]);
    }
    Expect.equals(namedArgs.length, m.namedArguments.length);
    for (var k in namedArgs.keys) {
      Expect.equals(namedArgs[k], m.namedArguments[new Symbol(k)]);
    }
    return 123;
  }
}

main() {
  var a = new A();
  for (var i = 0; i < 20; ++i) Expect.equals(123, a.foo<int, A>());
  Expect.throws(() => (a.foo)());
  Expect.throws(() => (a.foo)<int, A>());
  Expect.equals("123", (a.foo).toString());

  var b = new B();
  for (var i = 0; i < 20; ++i) {
    Expect.equals(2, b.bar<int, A>(1));
    Expect.equals(2, b.bar(1));
    Expect.equals(123, b.bar<int, A>());
    Expect.equals(3, b.bar<int, A>(2));
    Expect.equals(123, b.bar<int>(1));
  }

  for (var i = 0; i < 20; ++i) {
    Expect.equals(123, b.bar<int, A>(1, 2, 3));
    Expect.equals(123, b.bar<int, A>(1, 2, foo: 3));
    Expect.equals(123, b.bar<int>(1));
  }

  // Test type, named, and positional arguments.
  var c = new C([int, A], [100], {"n1": 101, "n2": 102});
  for (var i = 0; i < 20; ++i) {
    Expect.equals(123, c.bar<int, A>(100, n1: 101, n2: 102));
    Expect.equals(123, c.bar<int, A>(100, n2: 102, n1: 101));
  }
}
