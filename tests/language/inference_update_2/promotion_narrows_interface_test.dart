// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that promotion of a field narrows the types of methods, getters,
// and operators that are also exposed from the unpromoted type.

import 'package:expect/static_type_helper.dart';

class A {
  Object get getter => 0;
  num method(int value) => 0;
  num call(int value) => 0;
  num operator [](int index) => 0;
  operator []=(int index, int value) {}
  num operator +(int other) => 0;
}

class B extends A {
  int Function(num) get getter => (_) => 0;
  int method(num value) => 0;
  int call(num value) => 0;
  int operator [](num index) => 0;
  operator []=(num index, num value) {}
  int operator +(num other) => 0;
}

class C {
  final A _a;

  C(this._a);

  void testThisAccess() {
    if (_a is B) {
      _a.getter.expectStaticType<Exactly<int Function(num)>>();
      _a
          .getter(contextType(0)..expectStaticType<Exactly<num>>())
          .expectStaticType<Exactly<int>>();
      _a.method.expectStaticType<Exactly<int Function(num)>>();
      _a
          .method(contextType(0)..expectStaticType<Exactly<num>>())
          .expectStaticType<Exactly<int>>();
      _a(contextType(0)..expectStaticType<Exactly<num>>())
          .expectStaticType<Exactly<int>>();
      _a[contextType(0)..expectStaticType<Exactly<num>>()]
          .expectStaticType<Exactly<int>>();
      _a[contextType(0)..expectStaticType<Exactly<num>>()] = contextType(0)
        ..expectStaticType<Exactly<num>>();
      (_a + (contextType(0)..expectStaticType<Exactly<num>>()))
          .expectStaticType<Exactly<int>>();
    }
  }
}

class D extends C {
  D(super._a);

  void testSuperAccess() {
    if (super._a is B) {
      super._a.getter.expectStaticType<Exactly<int Function(num)>>();
      super
          ._a
          .getter(contextType(0)..expectStaticType<Exactly<num>>())
          .expectStaticType<Exactly<int>>();
      super._a.method.expectStaticType<Exactly<int Function(num)>>();
      super
          ._a
          .method(contextType(0)..expectStaticType<Exactly<num>>())
          .expectStaticType<Exactly<int>>();
      super
          ._a(contextType(0)..expectStaticType<Exactly<num>>())
          .expectStaticType<Exactly<int>>();
      super
          ._a[contextType(0)..expectStaticType<Exactly<num>>()]
          .expectStaticType<Exactly<int>>();
      super._a[contextType(0)..expectStaticType<Exactly<num>>()] =
          contextType(0)..expectStaticType<Exactly<num>>();
      (super._a + (contextType(0)..expectStaticType<Exactly<num>>()))
          .expectStaticType<Exactly<int>>();
    }
  }
}

void testPrefixedIdentifier(C c) {
  if (c._a is B) {
    c._a.getter.expectStaticType<Exactly<int Function(num)>>();
    c._a
        .getter(contextType(0)..expectStaticType<Exactly<num>>())
        .expectStaticType<Exactly<int>>();
    c._a.method.expectStaticType<Exactly<int Function(num)>>();
    c._a
        .method(contextType(0)..expectStaticType<Exactly<num>>())
        .expectStaticType<Exactly<int>>();
    c
        ._a(contextType(0)..expectStaticType<Exactly<num>>())
        .expectStaticType<Exactly<int>>();
    c._a[contextType(0)..expectStaticType<Exactly<num>>()]
        .expectStaticType<Exactly<int>>();
    c._a[contextType(0)..expectStaticType<Exactly<num>>()] = contextType(0)
      ..expectStaticType<Exactly<num>>();
    (c._a + (contextType(0)..expectStaticType<Exactly<num>>()))
        .expectStaticType<Exactly<int>>();
  }
}

void testGeneralPropertyAccess(C c) {
  // The analyzer uses a special data structure for `IDENTIFIER.IDENTIFIER`, so
  // we need to test the general case of property accesses as well.
  if ((c)._a is B) {
    (c)._a.getter.expectStaticType<Exactly<int Function(num)>>();
    (c)
        ._a
        .getter(contextType(0)..expectStaticType<Exactly<num>>())
        .expectStaticType<Exactly<int>>();
    (c)._a.method.expectStaticType<Exactly<int Function(num)>>();
    (c)
        ._a
        .method(contextType(0)..expectStaticType<Exactly<num>>())
        .expectStaticType<Exactly<int>>();
    (c)
        ._a(contextType(0)..expectStaticType<Exactly<num>>())
        .expectStaticType<Exactly<int>>();
    (c)
        ._a[contextType(0)..expectStaticType<Exactly<num>>()]
        .expectStaticType<Exactly<int>>();
    (c)._a[contextType(0)..expectStaticType<Exactly<num>>()] = contextType(0)
      ..expectStaticType<Exactly<num>>();
    ((c)._a + (contextType(0)..expectStaticType<Exactly<num>>()))
        .expectStaticType<Exactly<int>>();
  }
}

main() {
  var d = D(B());
  d.testThisAccess();
  d.testSuperAccess();
  testPrefixedIdentifier(d);
  testGeneralPropertyAccess(d);
}
