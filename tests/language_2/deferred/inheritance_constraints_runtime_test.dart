// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "inheritance_constraints_lib.dart" deferred as lib;

class Foo {}

class Foo2 extends D {}

class A extends

    Foo {}

class B
    implements

        Foo {}

class C1 {}

class C = C1
    with

        Foo;

class D {
  D();
  factory D.factory() =

      Foo2;
}

void main() {
  new A();
  new B();
  new C();
  new D.factory();
}
