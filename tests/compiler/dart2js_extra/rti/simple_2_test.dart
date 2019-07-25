// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

testDynamic1() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, 'dynamic');
  var rti2 = rti.testingUniverseEval(universe, ',,dynamic,,');

  Expect.isTrue(identical(rti1, rti2), 'dynamic should be identical');
  Expect.isFalse(rti1 is String);
  Expect.equals('dynamic', rti.testingRtiToString(rti1));
}

testDynamic2() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, 'dynamic');
  var rti2 = rti.testingUniverseEval(universe, ',,@,,');

  Expect.isTrue(identical(rti1, rti2), 'dynamic should be identical');
  Expect.isFalse(rti1 is String);
  Expect.equals('dynamic', rti.testingRtiToString(rti1));
}

testVoid() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, '~');
  var rti2 = rti.testingUniverseEval(universe, ',,~,,');

  Expect.isTrue(identical(rti1, rti2), 'void should be identical');
  Expect.isFalse(rti1 is String);
  Expect.equals('void', rti.testingRtiToString(rti1));
}

testNever() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, '0&');
  var rti2 = rti.testingUniverseEval(universe, '0&');

  Expect.isTrue(identical(rti1, rti2), 'Never should be identical');
  Expect.isFalse(rti1 is String);
  Expect.equals('Never', rti.testingRtiToString(rti1));
}

testAny() {
  var universe = rti.testingCreateUniverse();

  var rti1 = rti.testingUniverseEval(universe, '1&');
  var rti2 = rti.testingUniverseEval(universe, '1&');

  Expect.isTrue(identical(rti1, rti2), "'any' should be identical");
  Expect.isFalse(rti1 is String);
  Expect.equals('any', rti.testingRtiToString(rti1));
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
  testVoid();
  testNever();
  testAny();
  testTerminal();
  testInterface1();
  testInterface2();
  testInterface3();
  testInterface4();
}
