// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that invocation of a promoted field works properly when the feature is
// enabled.
//
// This is an important special case to test because an invocation of a field is
// initially parsed as a method invocation, and then later re-interpreted as an
// invocation of a field get.  We need to make sure the re-interpretation logic
// properly accounts for the promotion.

import 'package:expect/static_type_helper.dart';

class C {
  final void Function()? _nullablePrivateFunction;
  final int? Function() _privateFunctionWithNullableReturnType;

  C(this._nullablePrivateFunction, this._privateFunctionWithNullableReturnType);

  void testNullablePrivateFunctionThisAccess() {
    if (_nullablePrivateFunction != null) {
      // `_nullablePrivateFunction` has been shown to be non-null so this is ok.
      _nullablePrivateFunction();
    }
  }

  void testPrivateFunctionWithNullableReturnTypeThisAccess() {
    if (_privateFunctionWithNullableReturnType is int Function()) {
      _privateFunctionWithNullableReturnType().expectStaticType<Exactly<int>>();
    }
  }
}

class D extends C {
  D(super._nullablePrivateFunction,
      super._privateFunctionWithNullableReturnType);

  void testNullablePrivateFunctionSuperAccess() {
    if (super._nullablePrivateFunction != null) {
      // `super._nullablePrivateFunction` has been shown to be non-null so this
      // is ok.
      super._nullablePrivateFunction();
    }
  }

  void testPrivateFunctionWithNullableReturnTypeSuperAccess() {
    if (super._privateFunctionWithNullableReturnType is int Function()) {
      super
          ._privateFunctionWithNullableReturnType()
          .expectStaticType<Exactly<int>>();
    }
  }
}

void testNullablePrivateFunction(C c) {
  if (c._nullablePrivateFunction != null) {
    // `c._nullablePrivateFunction` has been shown to be non-null so this is ok.
    c._nullablePrivateFunction();
  }
}

void testPrivateFunctionWithNullableReturnType(C c) {
  if (c._privateFunctionWithNullableReturnType is int Function()) {
    c._privateFunctionWithNullableReturnType().expectStaticType<Exactly<int>>();
  }
}

void testNullablePrivateFunctionGeneralPropertyAccess(C c) {
  // The analyzer uses a special data structure for `IDENTIFIER.IDENTIFIER`, so
  // we need to test the general case of property accesses as well.
  if ((c)._nullablePrivateFunction != null) {
    // `(c)._nullablePrivateFunction` has been shown to be non-null so this is
    // ok.
    (c)._nullablePrivateFunction();
  }
}

void testPrivateFunctionWithNullableReturnTypeGeneralPropertyAccess(C c) {
  // The analyzer uses a special data structure for `IDENTIFIER.IDENTIFIER`, so
  // we need to test the general case of property accesses as well.
  if ((c)._privateFunctionWithNullableReturnType is int Function()) {
    (c)
        ._privateFunctionWithNullableReturnType()
        .expectStaticType<Exactly<int>>();
  }
}

main() {
  void functionReturningVoid() {}
  int functionReturningInt() => 0;
  var d = D(functionReturningVoid, functionReturningInt);
  d.testNullablePrivateFunctionThisAccess();
  d.testPrivateFunctionWithNullableReturnTypeThisAccess();
  d.testNullablePrivateFunctionSuperAccess();
  d.testPrivateFunctionWithNullableReturnTypeSuperAccess();
  testNullablePrivateFunction(d);
  testPrivateFunctionWithNullableReturnType(d);
  testNullablePrivateFunctionGeneralPropertyAccess(d);
  testPrivateFunctionWithNullableReturnTypeGeneralPropertyAccess(d);
}
