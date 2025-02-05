// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that promotion of a field makes it possible to access methods, getters,
// and operators in an extension that doesn't apply to the unpromoted type.

import 'package:expect/static_type_helper.dart';

class A {}

class B extends A {
  final int Function(int) field;

  B(this.field);
}

extension on B {
  int Function(int) get getter => field;
  int method(int value) => 0;
  int call(int value) => 0;
  int operator [](int index) => 0;
  operator []=(int index, int value) {}
  int operator +(int other) => 0;
}

class C {
  final A _a;

  C(this._a);

  void testThisAccess() {
    if (_a is B) {
      _a.field.expectStaticType<Exactly<int Function(int)>>();
      _a
          .field(contextType(0)..expectStaticType<Exactly<int>>())
          .expectStaticType<Exactly<int>>();
      _a.getter.expectStaticType<Exactly<int Function(int)>>();
      _a
          .getter(contextType(0)..expectStaticType<Exactly<int>>())
          .expectStaticType<Exactly<int>>();
      _a.method.expectStaticType<Exactly<int Function(int)>>();
      _a
          .method(contextType(0)..expectStaticType<Exactly<int>>())
          .expectStaticType<Exactly<int>>();
      _a(contextType(0)..expectStaticType<Exactly<int>>())
          .expectStaticType<Exactly<int>>();
      _a[contextType(0)..expectStaticType<Exactly<int>>()]
          .expectStaticType<Exactly<int>>();
      _a[contextType(0)..expectStaticType<Exactly<int>>()] = contextType(0)
        ..expectStaticType<Exactly<int>>();
      (_a + (contextType(0)..expectStaticType<Exactly<int>>()))
          .expectStaticType<Exactly<int>>();
    }
  }
}

class D extends C {
  D(super._a);

  void testSuperAccess() {
    if (super._a is B) {
      super._a.field.expectStaticType<Exactly<int Function(int)>>();
      super
          ._a
          .field(contextType(0)..expectStaticType<Exactly<int>>())
          .expectStaticType<Exactly<int>>();
      super._a.getter.expectStaticType<Exactly<int Function(int)>>();
      super
          ._a
          .getter(contextType(0)..expectStaticType<Exactly<int>>())
          .expectStaticType<Exactly<int>>();
      super._a.method.expectStaticType<Exactly<int Function(int)>>();
      super
          ._a
          .method(contextType(0)..expectStaticType<Exactly<int>>())
          .expectStaticType<Exactly<int>>();
      super
          ._a(contextType(0)..expectStaticType<Exactly<int>>())
          .expectStaticType<Exactly<int>>();
      super
          ._a[contextType(0)..expectStaticType<Exactly<int>>()]
          .expectStaticType<Exactly<int>>();
      super._a[contextType(0)..expectStaticType<Exactly<int>>()] =
          contextType(0)..expectStaticType<Exactly<int>>();
      (super._a + (contextType(0)..expectStaticType<Exactly<int>>()))
          .expectStaticType<Exactly<int>>();
    }
  }
}

void testPrefixedIdentifier(C c) {
  if (c._a is B) {
    c._a.field.expectStaticType<Exactly<int Function(int)>>();
    c._a
        .field(contextType(0)..expectStaticType<Exactly<int>>())
        .expectStaticType<Exactly<int>>();
    c._a.getter.expectStaticType<Exactly<int Function(int)>>();
    c._a
        .getter(contextType(0)..expectStaticType<Exactly<int>>())
        .expectStaticType<Exactly<int>>();
    c._a.method.expectStaticType<Exactly<int Function(int)>>();
    c._a
        .method(contextType(0)..expectStaticType<Exactly<int>>())
        .expectStaticType<Exactly<int>>();
    c
        ._a(contextType(0)..expectStaticType<Exactly<int>>())
        .expectStaticType<Exactly<int>>();
    c._a[contextType(0)..expectStaticType<Exactly<int>>()]
        .expectStaticType<Exactly<int>>();
    c._a[contextType(0)..expectStaticType<Exactly<int>>()] = contextType(0)
      ..expectStaticType<Exactly<int>>();
    (c._a + (contextType(0)..expectStaticType<Exactly<int>>()))
        .expectStaticType<Exactly<int>>();
  }
}

void testGeneralPropertyAccess(C c) {
  // The analyzer uses a special data structure for `IDENTIFIER.IDENTIFIER`, so
  // we need to test the general case of property accesses as well.
  if ((c)._a is B) {
    (c)._a.field.expectStaticType<Exactly<int Function(int)>>();
    (c)
        ._a
        .field(contextType(0)..expectStaticType<Exactly<int>>())
        .expectStaticType<Exactly<int>>();
    (c)._a.getter.expectStaticType<Exactly<int Function(int)>>();
    (c)
        ._a
        .getter(contextType(0)..expectStaticType<Exactly<int>>())
        .expectStaticType<Exactly<int>>();
    (c)._a.method.expectStaticType<Exactly<int Function(int)>>();
    (c)
        ._a
        .method(contextType(0)..expectStaticType<Exactly<int>>())
        .expectStaticType<Exactly<int>>();
    (c)
        ._a(contextType(0)..expectStaticType<Exactly<int>>())
        .expectStaticType<Exactly<int>>();
    (c)
        ._a[contextType(0)..expectStaticType<Exactly<int>>()]
        .expectStaticType<Exactly<int>>();
    (c)._a[contextType(0)..expectStaticType<Exactly<int>>()] = contextType(0)
      ..expectStaticType<Exactly<int>>();
    ((c)._a + (contextType(0)..expectStaticType<Exactly<int>>()))
        .expectStaticType<Exactly<int>>();
  }
}

main() {
  var d = D(B((_) => 0));
  d.testThisAccess();
  d.testSuperAccess();
  testPrefixedIdentifier(d);
  testGeneralPropertyAccess(d);
}
