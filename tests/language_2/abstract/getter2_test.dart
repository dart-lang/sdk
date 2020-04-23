// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int get x => 100;
}

abstract class B extends A {
  int _x;

  int get x;
  set x(int v) {
    _x = v;
  }
}

class C extends B {
  int get x => super.x;
}

class GetterConcrete {
  var _foo;

  get foo => _foo;
  set foo(x) => _foo = x;

  var _bar;

  get bar => _bar;
  set bar(x) => _bar = x;
}

class AbstractGetterOverride1 extends GetterConcrete {
  get foo;
  set bar(x);
}

class AbstractGetterOverride2 extends Object with GetterConcrete {
  get foo;
  set bar(x);
}

void main() {
  B b = new C();
  b.x = 42;
  Expect.equals(b._x, 42);
  Expect.equals(b.x, 100);

  /// Tests that overriding either the getter or setter with an abstract member
  /// has no effect.
  /// Regression test for https://github.com/dart-lang/sdk/issues/29914
  var c1 = AbstractGetterOverride1()
    ..foo = 123
    ..bar = 456;
  Expect.equals(c1.foo, 123);
  Expect.equals(c1.bar, 456);

  var c2 = AbstractGetterOverride2()
    ..foo = 123
    ..bar = 456;
  Expect.equals(c2.foo, 123);
  Expect.equals(c2.bar, 456);
}
