// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors" show reflect;
import "native_testing.dart";

class GetName {
  foo(x, y) => "foo";
  baz(x, y, z) => "baz";
}

String getName(im) => reflect(new GetName()).delegate(im);

@Native("A")
class A {
  bar() => 42;
  noSuchMethod(x) => "native(${getName(x)}:${x.positionalArguments})";
}

@Native("B")
class B {
  baz() => 42;
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
  Expect.equals("native(foo:[1, 2])", a.foo(1, 2));
  Expect.equals("native(baz:[3, 4, 5])", a.baz(3, 4, 5));
}
