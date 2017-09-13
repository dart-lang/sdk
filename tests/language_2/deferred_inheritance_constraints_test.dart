// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "deferred_inheritance_constraints_lib.dart" deferred as lib;

class Foo {}

class Foo2 extends D {}

class A extends
  lib. //# extends: compile-time error
    Foo {}

class B
    implements
  lib. //# implements: compile-time error
        Foo {}

class C1 {}

class C = C1
    with
  lib. //# mixin: compile-time error
        Foo;

class D {
  D();
  factory D.factory() =
    lib. //# redirecting_constructor: compile-time error
      Foo2;
}

void main() {
  new A();
  new B();
  new C();
  new D.factory();
}
