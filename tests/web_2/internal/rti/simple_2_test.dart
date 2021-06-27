// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

void checkToString(String expected, Object rti1) {
  String result = rti.testingRtiToString(rti1);
  if (expected == result) return;
  Expect.equals(expected, result.replaceAll('minified:', ''));
}

testDynamic() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, '@');
  var rti2 = rti.testingUniverseEval(universe, ',,@,,');

  Expect.isTrue(identical(rti1, rti2), 'dynamic should be identical');
  Expect.isFalse(rti1 is String);
  checkToString('dynamic', rti1);
}

testVoid() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, '~');
  var rti2 = rti.testingUniverseEval(universe, ',,~,,');

  Expect.isTrue(identical(rti1, rti2), 'void should be identical');
  Expect.isFalse(rti1 is String);
  checkToString('void', rti1);
}

testNever() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, '0&');
  var rti2 = rti.testingUniverseEval(universe, '0&');

  Expect.isTrue(identical(rti1, rti2), 'Never should be identical');
  Expect.isFalse(rti1 is String);
  checkToString('Never', rti1);
}

testAny() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, '1&');
  var rti2 = rti.testingUniverseEval(universe, '1&');

  Expect.isTrue(identical(rti1, rti2), "'any' should be identical");
  Expect.isFalse(rti1 is String);
  checkToString('any', rti1);
}

testTerminal() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, '@');
  var rti2 = rti.testingUniverseEval(universe, '~');
  var rti3 = rti.testingUniverseEval(universe, '0&');
  var rti4 = rti.testingUniverseEval(universe, '1&');

  Expect.isFalse(identical(rti1, rti2));
  Expect.isFalse(identical(rti1, rti3));
  Expect.isFalse(identical(rti1, rti4));
  Expect.isFalse(identical(rti2, rti3));
  Expect.isFalse(identical(rti2, rti4));
  Expect.isFalse(identical(rti3, rti4));
}

testInterface1() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, 'int');
  var rti2 = rti.testingUniverseEval(universe, ',,int,,');

  Expect.isTrue(identical(rti1, rti2));
  Expect.isFalse(rti1 is String);
  checkToString('int', rti1);
}

testInterface2() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, 'Foo<int,bool>');
  var rti2 = rti.testingUniverseEval(universe, 'Foo<int,bool>');

  Expect.isTrue(identical(rti1, rti2));
  Expect.isFalse(rti1 is String);
  checkToString('Foo<int, bool>', rti1);
}

testInterface3() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, 'Foo<Bar<int>,Bar<bool>>');
  var rti2 = rti.testingUniverseEval(universe, 'Foo<Bar<int>,Bar<bool>>');

  Expect.isTrue(identical(rti1, rti2));
  Expect.isFalse(rti1 is String);
  checkToString('Foo<Bar<int>, Bar<bool>>', rti1);
}

testInterface4() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, 'Foo<Foo<Foo<Foo<int>>>>');
  var rti2 = rti.testingUniverseEval(universe, 'Foo<Foo<Foo<Foo<int>>>>');

  Expect.isTrue(identical(rti1, rti2));
  Expect.isFalse(rti1 is String);
  checkToString('Foo<Foo<Foo<Foo<int>>>>', rti1);
}

main() {
  testDynamic();
  testVoid();
  testNever();
  testAny();
  testTerminal();
  testInterface1();
  testInterface2();
  testInterface3();
  testInterface4();
}
