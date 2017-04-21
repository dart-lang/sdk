// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors" show reflect;
import "native_testing.dart";

class GetName {
  foo(x, y, [z]) => "foo";
}

String getName(im) => reflect(new GetName()).delegate(im);

@Native("A")
class A {
  bar() => 42;
}

@Native("B")
class B {
  foo() => 42;
}

class C {
  static create() => new C();
  noSuchMethod(x) => "${getName(x)}:${x.positionalArguments}";
}

makeA() native;

setup() native """
  function A() {}
  makeA = function() { return new A; }

  self.nativeConstructor(A);
""";

main() {
  nativeTesting();
  setup();
  var a = makeA();
  a.bar();
  var exception;
  try {
    a.foo();
  } on NoSuchMethodError catch (e) {
    exception = e;
  }
  Expect.isNotNull(exception);
  var c = C.create();
  Expect.equals("foo:[1, 2]", c.foo(1, 2));
  Expect.equals("foo:[3, 4, 5]", c.foo(3, 4, 5));
}
