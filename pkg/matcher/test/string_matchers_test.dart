// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.string_matchers_test;

import 'package:matcher/matcher.dart';
import 'package:unittest/unittest.dart' show test, group;

import 'test_utils.dart';

void main() {
  initUtils();

  test('collapseWhitespace', () {
    var source = '\t\r\n hello\t\r\n world\r\t \n';
    expect(collapseWhitespace(source), 'hello world');
  });

  test('isEmpty', () {
    shouldPass('', isEmpty);
    shouldFail(null, isEmpty, "Expected: empty Actual: <null>");
    shouldFail(0, isEmpty, "Expected: empty Actual: <0>");
    shouldFail('a', isEmpty, "Expected: empty Actual: 'a'");
  });

  test('equalsIgnoringCase', () {
    shouldPass('hello', equalsIgnoringCase('HELLO'));
    shouldFail('hi', equalsIgnoringCase('HELLO'),
        "Expected: 'HELLO' ignoring case Actual: 'hi'");
  });

  test('equalsIgnoringWhitespace', () {
    shouldPass(' hello   world  ', equalsIgnoringWhitespace('hello world'));
    shouldFail(' helloworld  ', equalsIgnoringWhitespace('hello world'),
        "Expected: 'hello world' ignoring whitespace "
        "Actual: ' helloworld ' "
        "Which: is 'helloworld' with whitespace compressed");
  });

  test('startsWith', () {
    shouldPass('hello', startsWith(''));
    shouldPass('hello', startsWith('hell'));
    shouldPass('hello', startsWith('hello'));
    shouldFail('hello', startsWith('hello '),
        "Expected: a string starting with 'hello ' "
        "Actual: 'hello'");
  });

  test('endsWith', () {
    shouldPass('hello', endsWith(''));
    shouldPass('hello', endsWith('lo'));
    shouldPass('hello', endsWith('hello'));
    shouldFail('hello', endsWith(' hello'),
        "Expected: a string ending with ' hello' "
        "Actual: 'hello'");
  });

  test('contains', () {
    shouldPass('hello', contains(''));
    shouldPass('hello', contains('h'));
    shouldPass('hello', contains('o'));
    shouldPass('hello', contains('hell'));
    shouldPass('hello', contains('hello'));
    shouldFail('hello', contains(' '),
        "Expected: contains ' ' Actual: 'hello'");
  });

  test('stringContainsInOrder', () {
    shouldPass('goodbye cruel world', stringContainsInOrder(['']));
    shouldPass('goodbye cruel world', stringContainsInOrder(['goodbye']));
    shouldPass('goodbye cruel world', stringContainsInOrder(['cruel']));
    shouldPass('goodbye cruel world', stringContainsInOrder(['world']));
    shouldPass('goodbye cruel world',
               stringContainsInOrder(['good', 'bye', 'world']));
    shouldPass('goodbye cruel world',
               stringContainsInOrder(['goodbye', 'cruel']));
    shouldPass('goodbye cruel world',
               stringContainsInOrder(['cruel', 'world']));
    shouldPass('goodbye cruel world',
      stringContainsInOrder(['goodbye', 'cruel', 'world']));
    shouldFail('goodbye cruel world',
      stringContainsInOrder(['goo', 'cruel', 'bye']),
      "Expected: a string containing 'goo', 'cruel', 'bye' in order "
      "Actual: 'goodbye cruel world'");
  });

  test('matches', () {
    shouldPass('c0d', matches('[a-z][0-9][a-z]'));
    shouldPass('c0d', matches(new RegExp('[a-z][0-9][a-z]')));
    shouldFail('cOd', matches('[a-z][0-9][a-z]'),
        "Expected: match '[a-z][0-9][a-z]' Actual: 'cOd'");
  });
}
