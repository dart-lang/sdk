// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:_rti' as rti;
import "package:expect/expect.dart";

final universe = rti.testingCreateUniverse();

main() {
  test('@', '@');
  test('~', '~');
  test('0&', '0&');
  test('1&', '1&');
  test('int', 'int');
  test('int/', 'int/');
  test('List<int>', 'List<int>');
  test('Foo<bool,Bar<int,double>>', 'Foo<bool,Bar<int,double>>');
  test('@;<int,bool>', '@<int><bool>');
}

String canonicalize(String recipe) {
  var t = rti.testingUniverseEval(universe, recipe);
  return rti.testingCanonicalRecipe(t);
}

void test(String expected, String recipe) =>
    Expect.equals(expected, canonicalize(recipe));
