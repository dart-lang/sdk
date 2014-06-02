// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.operator_matchers_test;

import 'package:matcher/matcher.dart';
import 'package:unittest/unittest.dart' show test, group;

import 'test_utils.dart';

void main() {
  initUtils();

  test('anyOf', () {
    shouldFail(0, anyOf([equals(1), equals(2)]),
        "Expected: (<1> or <2>) Actual: <0>");
    shouldPass(1, anyOf([equals(1), equals(2)]));
  });

  test('allOf', () {
    shouldPass(1, allOf([lessThan(10), greaterThan(0)]));
    shouldFail(-1, allOf([lessThan(10), greaterThan(0)]),
        "Expected: (a value less than <10> and a value greater than <0>) "
        "Actual: <-1> "
        "Which: is not a value greater than <0>");
  });
}
