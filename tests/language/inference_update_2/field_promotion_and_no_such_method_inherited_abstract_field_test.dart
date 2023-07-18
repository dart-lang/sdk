// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that inherited abstract fields are properly accounted for when deciding
// whether a `noSuchMethod` suppresses field promotion.

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

abstract class B {
  abstract final int? _f1;
  abstract int? _f2;
}

abstract class C {
  abstract final int? _f3;
  abstract int? _f4;
}

class D extends C implements B {
  @override
  noSuchMethod(_) => 0;
}

testFinalAbstractFieldImpliesInterfaceGetter(A a) {
  // Class `D` has an `_f1` getter in its interface, inherited from `B`. `D` has
  // a non-default `noSuchMethod` method, but it neither inherits nor declares
  // any implementation of `_f1`. Because of that, `D` introduces an implicit
  // and concrete `noSuchMethod`-forwarding `_f1` getter implementation, and the
  // presence of an implicit forwarding concrete getter with the same name
  // inhibits promotion of `A._f1`.
  if (a._f1 != null) {
    a._f1.expectStaticType<Exactly<int?>>;
  }
}

testNonFinalAbstractFieldImpliesInterfaceGetter(A a) {
  // Class `D` has an `_f2` getter in its interface, inherited from `B`. `D` has
  // a non-default `noSuchMethod` method, but it neither inherits nor declares
  // any implementation of `_f2`. Because of that, `D` introduces an implicit
  // and concrete `noSuchMethod`-forwarding `_f2` getter implementation, and the
  // presence of an implicit forwarding concrete getter with the same name
  // inhibits promotion of `A._f2`.
  if (a._f2 != null) {
    a._f2.expectStaticType<Exactly<int?>>;
  }
}

testFinalAbstractFieldDoesNotImplyImplementationField(A a) {
  // Class `D` has an `_f3` getter in its interface, inherited from `C`. `D` has
  // a non-default `noSuchMethod` method, but it neither inherits nor declares
  // any implementation of `_f3`. Because of that, `D` introduces an implicit
  // and concrete `noSuchMethod`-forwarding `_f3` getter implementation, and the
  // presence of an implicit forwarding concrete getter with the same name
  // inhibits promotion of `A._f3`.
  if (a._f3 != null) {
    a._f3.expectStaticType<Exactly<int?>>;
  }
}

testNonFinalAbstractFieldDoesNotImplyImplementationField(A a) {
  // Class `D` has an `_f4` getter in its interface, inherited from `C`. `D` has
  // a non-default `noSuchMethod` method, but it neither inherits nor declares
  // any implementation of `_f4`.  Because of that, `D` introduces an implicit
  // and concrete `noSuchMethod`-forwarding `_f4` getter implementation, and the
  // presence of an implicit forwarding concrete getter with the same name
  // inhibits promotion of `A._f4`.
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
    testFinalAbstractFieldImpliesInterfaceGetter(a);
    testNonFinalAbstractFieldImpliesInterfaceGetter(a);
    testFinalAbstractFieldDoesNotImplyImplementationField(a);
    testNonFinalAbstractFieldDoesNotImplyImplementationField(a);
    testBasicPromotion(a);
  }
}
