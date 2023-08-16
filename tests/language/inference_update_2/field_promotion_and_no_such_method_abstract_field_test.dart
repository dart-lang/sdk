// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that non-inherited abstract fields are properly accounted for when
// deciding whether a `noSuchMethod` suppresses field promotion.

// SharedOptions=--enable-experiment=inference-update-2

import "../static_type_helper.dart";

class A {
  final int? _f1;
  final int? _f2;
  final int? _f3;
  final int? _f4;
  final int? _f5;

  A(int? i)
      : _f1 = i,
        _f2 = i,
        _f3 = i,
        _f4 = i,
        _f5 = i;
}

abstract class B1 {
  abstract final int? _f1;
}

abstract mixin class B2 {
  abstract final int? _f2;
}

abstract mixin class B3 {
  abstract final int? _f3;
}

abstract class B4 {
  abstract final int? _f4;
}

class C extends B1 with B2 {
  @override
  noSuchMethod(_) => null;
}

class D = C with B3 implements B4;

testAbstractFieldFromTargetClass(A a) {
  if (a._f1 != null) {
    a._f1.expectStaticType<Exactly<int?>>;
  }
}

testAbstractFieldFromMixin(A a) {
  if (a._f2 != null) {
    a._f2.expectStaticType<Exactly<int?>>;
  }
}

testAbstractFieldFromTargetClassOfClassAlias(A a) {
  if (a._f3 != null) {
    a._f3.expectStaticType<Exactly<int?>>;
  }
}

testAbstractFieldFromMixinOfClassAlias(A a) {
  if (a._f4 != null) {
    a._f4.expectStaticType<Exactly<int?>>;
  }
}

testBasicPromotion(A a) {
  // Since all of the above tests check that field promotion *fails*, if we've
  // made a mistake causing field promotion to be completely disabled in this
  // file, all the tests will continue to pass. So to verify that we haven't
  // made such a mistake, verify that field promotion works under ordinary
  // circumstances.
  if (a._f5 != null) {
    a._f5.expectStaticType<Exactly<int>>;
  }
}

main() {
  for (var a in [A(null), A(0)]) {
    testAbstractFieldFromTargetClass(a);
    testAbstractFieldFromMixin(a);
    testAbstractFieldFromTargetClassOfClassAlias(a);
    testAbstractFieldFromMixinOfClassAlias(a);
    testBasicPromotion(a);
  }
}
