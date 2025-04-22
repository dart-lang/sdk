// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of null aware accesses (expressions involving `?.`)
// when `sound-flow-analysis` is disabled.

// @dart = 3.8

// ignore_for_file: invalid_null_aware_operator

import '../static_type_helper.dart';

// `<nonNullable>?.bitLength.gcd(<expr>)` is not known to invoke <expr>.
testProperty({required int intValue, required int Function() intFunction}) {
  {
    // <var>?.bitLength.gcd(<expr>)
    int? shouldNotBePromoted;
    intValue?.bitLength.gcd(shouldNotBePromoted = 0);
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr>?.bitLength.gcd(<expr>)
    int? shouldNotBePromoted;
    intFunction()?.bitLength.gcd(shouldNotBePromoted = 0);
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable>?.gcd(<expr>)` is not known to invoke <expr>.
testCall({required int intValue, required int Function() intFunction}) {
  {
    // <var>?.gcd(<expr>)
    int? shouldNotBePromoted;
    intValue?.gcd(shouldNotBePromoted = 0);
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr>?.gcd(<expr>)
    int? shouldNotBePromoted;
    intFunction()?.gcd(shouldNotBePromoted = 0);
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable>?[<expr>]` is not known to invoke <expr>.
testIndexGet({
  required List<int> listOfIntValue,
  required List<int> Function() listOfIntFunction,
}) {
  {
    // <var>?[<expr>]
    int? shouldNotBePromoted;
    listOfIntValue?[shouldNotBePromoted = 0];
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr>?[<expr>]
    int? shouldNotBePromoted;
    listOfIntFunction()?[shouldNotBePromoted = 0];
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable>?[<expr>] = 0` is not known to invoke <expr>.
testIndexSet({
  required List<int> listOfIntValue,
  required List<int> Function() listOfIntFunction,
}) {
  {
    // <var>?[<expr>] = 0
    int? shouldNotBePromoted;
    listOfIntValue?[shouldNotBePromoted = 0] = 0;
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr>?[<expr>] = 0
    int? shouldNotBePromoted;
    listOfIntFunction()?[shouldNotBePromoted = 0] = 0;
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable>?..bitLength.gcd(<expr>)` is not known to invoke <expr>.
testCascadedProperty({
  required int intValue,
  required int Function() intFunction,
}) {
  {
    // <var>?..bitLength.gcd(<expr>)
    int? shouldNotBePromoted;
    intValue?..bitLength.gcd(shouldNotBePromoted = 0);
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr>?..bitLength.gcd(<expr>)
    int? shouldNotBePromoted;
    intFunction()?..bitLength.gcd(shouldNotBePromoted = 0);
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable>?..gcd(<expr>)` is not known to invoke <expr>.
testCascadedCall({required int intValue, required int Function() intFunction}) {
  {
    // <var>?..gcd(<expr>)
    int? shouldNotBePromoted;
    intValue?..gcd(shouldNotBePromoted = 0);
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr>?..gcd(<expr>)
    int? shouldNotBePromoted;
    intFunction()?..gcd(shouldNotBePromoted = 0);
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable>?..[<expr>]` is not known to invoke <expr>.
testCascadedIndexGet({
  required List<int> listOfIntValue,
  required List<int> Function() listOfIntFunction,
}) {
  {
    // <var>?..[<expr>]
    int? shouldNotBePromoted;
    listOfIntValue?..[shouldNotBePromoted = 0];
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr>?..[<expr>]
    int? shouldNotBePromoted;
    listOfIntFunction()?..[shouldNotBePromoted = 0];
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable>?..[<expr>] = 0` is not known to invoke <expr>.
testCascadedIndexSet({
  required List<int> listOfIntValue,
  required List<int> Function() listOfIntFunction,
}) {
  {
    // <var>?..[<expr>] = 0
    int? shouldNotBePromoted;
    listOfIntValue?..[shouldNotBePromoted = 0] = 0;
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr>?..[<expr>] = 0
    int? shouldNotBePromoted;
    listOfIntFunction()?..[shouldNotBePromoted = 0] = 0;
    shouldNotBePromoted.expectStaticType<Exactly<int?>>();
  }
}

main() {
  testProperty(intValue: 0, intFunction: () => 0);
  testCall(intValue: 0, intFunction: () => 0);
  testIndexGet(listOfIntValue: [0], listOfIntFunction: () => [0]);
  testIndexSet(listOfIntValue: [0], listOfIntFunction: () => [0]);
  testCascadedProperty(intValue: 0, intFunction: () => 0);
  testCascadedCall(intValue: 0, intFunction: () => 0);
  testCascadedIndexGet(listOfIntValue: [0], listOfIntFunction: () => [0]);
  testCascadedIndexSet(listOfIntValue: [0], listOfIntFunction: () => [0]);
}
