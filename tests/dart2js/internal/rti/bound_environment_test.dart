// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

void checkRtiIdentical(rti.Rti rti1, rti.Rti rti2) {
  var format = rti.testingRtiToString;
  Expect.isTrue(
      identical(rti1, rti2), 'identical(${format(rti1)}, ${format(rti2)}');
}

void checkToString(String expected, rti.Rti rti1) {
  String result = rti.testingRtiToString(rti1);
  if (expected == result) return;
  Expect.equals(expected, result.replaceAll('minified:', ''));
}

test1() {
  var universe = rti.testingCreateUniverse();

  var env = rti.testingUniverseEval(universe, 'Foo<bool><int>');
  var rti1 = rti.testingUniverseEval(universe, 'int');
  var rti2 = rti.testingEnvironmentEval(universe, env, '1');

  checkToString('int', rti1);
  checkToString('int', rti2);
  checkRtiIdentical(rti1, rti2);

  var rti3 = rti.testingEnvironmentEval(universe, env, 'AAA<0,1,2>');
  checkToString('AAA<Foo<bool>, int, bool>', rti3);
}

test2() {
  var universe = rti.testingCreateUniverse();

  // Generic class with one nested single-parameter function scope.
  //   vs.
  // Unparameterized class with two nested single-parameter function scopes.
  var env1 = rti.testingUniverseEval(universe, 'Foo<bool><int>');
  var env2 = rti.testingUniverseEval(universe, 'Foo;<bool><int>');

  var rti1 = rti.testingEnvironmentEval(universe, env1, 'AAA<0,1,2>');
  var rti2 = rti.testingEnvironmentEval(universe, env2, 'AAA<0,1,2>');
  checkToString('AAA<Foo<bool>, int, bool>', rti1);
  checkToString('AAA<Foo, bool, int>', rti2);
}

test3() {
  var universe = rti.testingCreateUniverse();
  var env = rti.testingUniverseEval(universe, 'CCC<aaa,bbb><ccc,@>');
  var rti1 = rti.testingEnvironmentEval(universe, env, 'AAA<0,1,2,3,4>');
  checkToString('AAA<CCC<aaa, bbb>, ccc, dynamic, aaa, bbb>', rti1);
}

test4() {
  var universe = rti.testingCreateUniverse();
  var env = rti.testingUniverseEval(universe, '@<aaa,bbb>');
  var rti1 = rti.testingEnvironmentEval(universe, env, 'AAA<0,1,2>');
  checkToString('AAA<dynamic, aaa, bbb>', rti1);
}

test5() {
  var universe = rti.testingCreateUniverse();
  var env1 = rti.testingUniverseEval(universe, '@<aaa><bbb><ccc>');
  var env2 = rti.testingUniverseEval(universe, '@;<aaa><bbb><ccc>');
  var rti1 = rti.testingEnvironmentEval(universe, env1, 'AAA<0,1,2,3>');
  var rti2 = rti.testingEnvironmentEval(universe, env2, 'AAA<0,1,2,3>');
  checkToString('AAA<dynamic, aaa, bbb, ccc>', rti1);
  checkRtiIdentical(rti1, rti2);
}

main() {
  test1();
  test2();
  test3();
  test4();
  test5();
}
