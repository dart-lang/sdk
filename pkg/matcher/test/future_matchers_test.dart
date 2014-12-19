// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.future_matchers_test;

import 'dart:async';

import 'package:matcher/matcher.dart';
import 'package:unittest/unittest.dart' show test, group;

import 'test_utils.dart';

void main() {
  initUtils();

  test('completes - unexpected error', () {
    var completer = new Completer();
    completer.completeError('X');
    shouldFail(completer.future, completes,
        contains('Expected future to complete successfully, '
                 'but it failed with X'),
        isAsync: true);
  });

  test('completes - successfully', () {
    var completer = new Completer();
    completer.complete('1');
    shouldPass(completer.future, completes, isAsync: true);
  });

  test('throws - unexpected to see normal completion', () {
    var completer = new Completer();
    completer.complete('1');
    shouldFail(completer.future, throws,
      contains("Expected future to fail, but succeeded with '1'"),
      isAsync: true);
  });

  test('throws - expected to see exception', () {
    var completer = new Completer();
    completer.completeError('X');
    shouldPass(completer.future, throws, isAsync: true);
  });

  test('throws - expected to see exception thrown later on', () {
    var completer = new Completer();
    var chained = completer.future.then((_) { throw 'X'; });
    shouldPass(chained, throws, isAsync: true);
    completer.complete('1');
  });

  test('throwsA - unexpected normal completion', () {
    var completer = new Completer();
    completer.complete('1');
    shouldFail(completer.future, throwsA(equals('X')),
      contains("Expected future to fail, but succeeded with '1'"),
      isAsync: true);
  });

  test('throwsA - correct error', () {
    var completer = new Completer();
    completer.completeError('X');
    shouldPass(completer.future, throwsA(equals('X')), isAsync: true);
  });

  test('throwsA - wrong error', () {
    var completer = new Completer();
    completer.completeError('X');
    shouldFail(completer.future, throwsA(equals('Y')),
        "Expected: 'Y' Actual: 'X' "
        "Which: is different. "
        "Expected: Y Actual: X ^ Differ at offset 0",
        isAsync: true);
  });
}
