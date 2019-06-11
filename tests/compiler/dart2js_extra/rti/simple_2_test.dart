// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

testDynamic1() {
  var universe = rti.testingCreateUniverse();

  var dynamicRti1 = rti.testingUniverseEval(universe, 'dynamic');
  var dynamicRti2 = rti.testingUniverseEval(universe, ',,dynamic,,');

  Expect.isTrue(
      identical(dynamicRti1, dynamicRti2), 'dynamic should be identical');
  Expect.isFalse(dynamicRti1 is String);
  Expect.equals('dynamic', rti.testingRtiToString(dynamicRti1));
}

testDynamic2() {
  var universe = rti.testingCreateUniverse();

  var dynamicRti1 = rti.testingUniverseEval(universe, 'dynamic');
  var dynamicRti2 = rti.testingUniverseEval(universe, ',,@,,');

  Expect.isTrue(
      identical(dynamicRti1, dynamicRti2), 'dynamic should be identical');
  Expect.isFalse(dynamicRti1 is String);
  Expect.equals('dynamic', rti.testingRtiToString(dynamicRti1));
}

testInterface1() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, 'int');
  var rti2 = rti.testingUniverseEval(universe, ',,int,,');

  Expect.isTrue(identical(rti1, rti2));
  Expect.isFalse(rti1 is String);
  Expect.equals('int', rti.testingRtiToString(rti1));
}

testInterface2() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, 'Foo<int,bool>');
  var rti2 = rti.testingUniverseEval(universe, 'Foo<int,bool>');

  Expect.isTrue(identical(rti1, rti2));
  Expect.isFalse(rti1 is String);
  Expect.equals('Foo<int, bool>', rti.testingRtiToString(rti1));
}

testInterface3() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, 'Foo<Bar<int>,Bar<bool>>');
  var rti2 = rti.testingUniverseEval(universe, 'Foo<Bar<int>,Bar<bool>>');

  Expect.isTrue(identical(rti1, rti2));
  Expect.isFalse(rti1 is String);
  Expect.equals('Foo<Bar<int>, Bar<bool>>', rti.testingRtiToString(rti1));
}

testInterface4() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, 'Foo<Foo<Foo<Foo<int>>>>');
  var rti2 = rti.testingUniverseEval(universe, 'Foo<Foo<Foo<Foo<int>>>>');

  Expect.isTrue(identical(rti1, rti2));
  Expect.isFalse(rti1 is String);
  Expect.equals('Foo<Foo<Foo<Foo<int>>>>', rti.testingRtiToString(rti1));
}

main() {
  testDynamic1();
  testDynamic2();
  testInterface1();
  testInterface2();
  testInterface3();
  testInterface4();
}
