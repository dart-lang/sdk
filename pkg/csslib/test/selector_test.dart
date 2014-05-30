// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library selector_test;

import 'package:unittest/unittest.dart';
import 'testing.dart';
import 'package:csslib/parser.dart';

void testSelectorSuccesses() {
  var errors = [];
  var selectorAst = selector('#div .foo', errors: errors);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect('#div .foo', compactOuptut(selectorAst));

  // Valid selectors for class names.
  selectorAst = selector('.foo', errors: errors..clear());
  expect(errors.isEmpty, true, reason: errors.toString());
  expect('.foo', compactOuptut(selectorAst));

  selectorAst = selector('.foobar .xyzzy', errors: errors..clear());
  expect(errors.isEmpty, true, reason: errors.toString());
  expect('.foobar .xyzzy', compactOuptut(selectorAst));

  selectorAst = selector('.foobar .a-story .xyzzy', errors: errors..clear());
  expect(errors.isEmpty, true, reason: errors.toString());
  expect('.foobar .a-story .xyzzy', compactOuptut(selectorAst));

  selectorAst = selector('.foobar .xyzzy .a-story .b-story',
      errors: errors..clear());
  expect(errors.isEmpty, true, reason: errors.toString());
  expect('.foobar .xyzzy .a-story .b-story', compactOuptut(selectorAst));

  // Valid selectors for element IDs.
  selectorAst = selector('#id1', errors: errors..clear());
  expect(errors.isEmpty, true, reason: errors.toString());
  expect('#id1', compactOuptut(selectorAst));

  selectorAst = selector('#id-number-3', errors: errors..clear());
  expect(errors.isEmpty, true, reason: errors.toString());
  expect('#id-number-3', compactOuptut(selectorAst));

  selectorAst = selector('#_privateId', errors: errors..clear());
  expect(errors.isEmpty, true, reason: errors.toString());
  expect('#_privateId', compactOuptut(selectorAst));
}

// TODO(terry): Move this failure case to a failure_test.dart when the analyzer
//              and validator exit then they'll be a bunch more checks.
void testSelectorFailures() {
  var errors = [];

  // Test for invalid class name (can't start with number).
  var selectorAst = selector('.foobar .1a-story .xyzzy', errors: errors);
  expect(errors.isEmpty, false);
  expect(errors[0].toString(),
      'error on line 1, column 9: name must start with a alpha character, but '
        'found a number\n'
      '.foobar .1a-story .xyzzy\n'
      '        ^^');
}

main() {
  test('Valid Selectors', testSelectorSuccesses);
  test('Invalid Selectors', testSelectorFailures);
}
