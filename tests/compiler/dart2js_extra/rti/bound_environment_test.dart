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

test1() {
  var universe = rti.testingCreateUniverse();

  var env = rti.testingUniverseEval(universe, 'Foo<bool><int>');
  var rti1 = rti.testingUniverseEval(universe, 'int');
  var rti2 = rti.testingEnvironmentEval(universe, env, '1');

  Expect.equals('int', rti.testingRtiToString(rti1));
  Expect.equals('int', rti.testingRtiToString(rti2));
  checkRtiIdentical(rti1, rti2);

  var rti3 = rti.testingEnvironmentEval(universe, env, 'A<0,1,2>');
  Expect.equals('A<Foo<bool>, int, bool>', rti.testingRtiToString(rti3));
}

test2() {
  var universe = rti.testingCreateUniverse();

  // Generic class with one nested single-parameter function scope.
  //   vs.
  // Unparameterized class with two nested single-parameter function scopes.
  var env1 = rti.testingUniverseEval(universe, 'Foo<bool><int>');
  var env2 = rti.testingUniverseEval(universe, 'Foo;<bool><int>');

  var rti1 = rti.testingEnvironmentEval(universe, env1, 'A<0,1,2>');
  var rti2 = rti.testingEnvironmentEval(universe, env2, 'A<0,1,2>');
  Expect.equals('A<Foo<bool>, int, bool>', rti.testingRtiToString(rti1));
  Expect.equals('A<Foo, bool, int>', rti.testingRtiToString(rti2));
}

test3() {
  var universe = rti.testingCreateUniverse();
  var env = rti.testingUniverseEval(universe, 'C<aa,bb><cc,@>');
  var rti1 = rti.testingEnvironmentEval(universe, env, 'A<0,1,2,3,4>');
  Expect.equals(
      'A<C<aa, bb>, cc, dynamic, aa, bb>', rti.testingRtiToString(rti1));
}

test4() {
  var universe = rti.testingCreateUniverse();
  var env = rti.testingUniverseEval(universe, '@<aa,bb>');
  var rti1 = rti.testingEnvironmentEval(universe, env, 'A<0,1,2>');
  Expect.equals('A<dynamic, aa, bb>', rti.testingRtiToString(rti1));
}

test5() {
  var universe = rti.testingCreateUniverse();
  var env1 = rti.testingUniverseEval(universe, '@<aa><bb><cc>');
  var env2 = rti.testingUniverseEval(universe, '@;<aa><bb><cc>');
  var rti1 = rti.testingEnvironmentEval(universe, env1, 'A<0,1,2,3>');
  var rti2 = rti.testingEnvironmentEval(universe, env2, 'A<0,1,2,3>');
  Expect.equals('A<dynamic, aa, bb, cc>', rti.testingRtiToString(rti1));
  checkRtiIdentical(rti1, rti2);
}

main() {
  test1();
  test2();
  test3();
  test4();
  test5();
}
