// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

void checkRtiIdentical(Object rti1, Object rti2) {
  var format = rti.testingRtiToString;
  Expect.isTrue(
      identical(rti1, rti2), 'identical(${format(rti1)}, ${format(rti2)}');
}

testInterface1() {
  var universe = rti.testingCreateUniverse();

  var env = rti.testingUniverseEval(universe, 'Foo<int>');
  var rti1 = rti.testingUniverseEval(universe, 'int');
  var rti2 = rti.testingEnvironmentEval(universe, env, '1');

  Expect.equals('int', rti.testingRtiToString(rti1));
  Expect.equals('int', rti.testingRtiToString(rti2));
  checkRtiIdentical(rti1, rti2);
}

testInterface2() {
  var universe = rti.testingCreateUniverse();

  var env = rti.testingUniverseEval(universe, 'Foo<int,List<int>>');
  var rti1 = rti.testingUniverseEval(universe, 'List<int>');
  var rti2 = rti.testingEnvironmentEval(universe, env, '2');
  var rti3 = rti.testingEnvironmentEval(universe, env, 'List<1>');

  Expect.equals('List<int>', rti.testingRtiToString(rti1));
  Expect.equals('List<int>', rti.testingRtiToString(rti2));
  Expect.equals('List<int>', rti.testingRtiToString(rti3));
  checkRtiIdentical(rti1, rti2);
  checkRtiIdentical(rti1, rti3);
}

main() {
  testInterface1();
  testInterface2();
}
