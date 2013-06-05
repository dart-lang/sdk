// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:unittest/unittest.dart';

import 'test_common.dart';
import 'test_utils.dart';

void main() {

  initUtils();

  // Core matchers

  group('Core matchers', () {

    test('isTrue', () {
      shouldPass(true, isTrue);
      shouldFail(false, isTrue, "Expected: true But: was <false>. "
          "Actual: <false>");
    });

    test('isFalse', () {
      shouldPass(false, isFalse);
      shouldFail(10, isFalse, "Expected: false But: was <10>. "
          "Actual: <10>");
      shouldFail(true, isFalse, "Expected: false But: was <true>. "
          "Actual: <true>");
    });

    test('isNull', () {
      shouldPass(null, isNull);
      shouldFail(false, isNull, "Expected: null But: was <false>. "
          "Actual: <false>");
    });

    test('isNotNull', () {
      shouldPass(false, isNotNull);
      shouldFail(null, isNotNull, "Expected: not null But: was <null>. "
          "Actual: <null>");
    });

    test('same', () {
      var a = new Map();
      var b = new Map();
      shouldPass(a, same(a));
      shouldFail(b, same(a), "Expected: same instance as {} But: was {}. "
          "Actual: {}");
    });

    test('equals', () {
      var a = new Map();
      var b = new Map();
      shouldPass(a, equals(a));
      shouldPass(a, equals(b));
    });

    test('anything', () {
      var a = new Map();
      shouldPass(0, anything);
      shouldPass(null, anything);
      shouldPass(a, anything);
      shouldFail(a, isNot(anything), "Expected: not anything "
          "But: was {}. Actual: {}");
    });

    test('throws', () {
      shouldFail(doesNotThrow, throws,
          matches(
              r"Expected: throws an exception +But:  no exception\."
              r"Actual: <Closure(: \(dynamic\) => dynamic "
                  r"from Function 'doesNotThrow': static\.)?>"));
      shouldPass(doesThrow, throws);
      shouldFail(true, throws,
          "Expected: throws an exception But: not a Function or Future. "
          "Actual: <true>");
    });

    test('throwsA', () {
      shouldPass(doesThrow, throwsA(equals('X')));
      shouldFail(doesThrow, throwsA(equals('Y')),
          matches(
              r"Expected: throws an exception which matches 'Y' +"
              r"But:  exception 'X' does not match 'Y'\."
              r"Actual: <Closure(: \(dynamic\) => dynamic "
                  r"from Function 'doesThrow': static\.)?>"));
    });

    test('returnsNormally', () {
      shouldPass(doesNotThrow, returnsNormally);
      shouldFail(doesThrow, returnsNormally,
          matches(
              r"Expected: return normally +But:  threw 'X'\."
              r"Actual: <Closure(: \(dynamic\) => dynamic "
                  r"from Function 'doesThrow': static\.)?>"));
    });

    test('hasLength', () {
      var a = new Map();
      var b = new List();
      shouldPass(a, hasLength(0));
      shouldPass(b, hasLength(0));
      shouldPass('a', hasLength(1));
      shouldFail(0, hasLength(0), new PrefixMatcher(
          "Expected: an object with length of <0> "
          "But: had no length property."
          "Actual: <0>"));

      b.add(0);
      shouldPass(b, hasLength(1));
      shouldFail(b, hasLength(2),
          "Expected: an object with length of <2> "
          "But: had length of <1>. "
          "Actual: [0]");

      b.add(0);
      shouldFail(b, hasLength(1),
          "Expected: an object with length of <1> "
          "But: had length of <2>. "
          "Actual: [0, 0]");
      shouldPass(b, hasLength(2));
    });

    test('scalar type mismatch', () {
      shouldFail('error', equals(5.1),
          "Expected: <5.1> "
          "But: was 'error'. Actual: 'error'");
    });

    test('nested type mismatch', () {
      shouldFail(['error'], equals([5.1]),
          "Expected: [5.1] "
          "But: expected <5.1> but was 'error' mismatch at position 0. "
          "Actual: ['error']");
    });

    test('doubly-nested type mismatch', () {
      shouldFail([['error']], equals([[5.1]]),
          "Expected: [[5.1]] "
          "But: expected <5.1> but was 'error' "
          "mismatch at position 0 mismatch at position 0. "
          "Actual: [['error']]");
    });
  });

  group('Numeric Matchers', () {

    test('greaterThan', () {
      shouldPass(10, greaterThan(9));
      shouldFail(9, greaterThan(10),
        "Expected: a value greater than <10> But: was <9>. Actual: <9>");
    });

    test('greaterThanOrEqualTo', () {
      shouldPass(10, greaterThanOrEqualTo(10));
      shouldFail(9, greaterThanOrEqualTo(10),
        "Expected: a value greater than or equal to <10> But: was <9>. "
        "Actual: <9>");
    });

    test('lessThan', () {
      shouldFail(10, lessThan(9), "Expected: a value less than <9> "
          "But: was <10>. Actual: <10>");
      shouldPass(9, lessThan(10));
    });

    test('lessThanOrEqualTo', () {
      shouldPass(10, lessThanOrEqualTo(10));
      shouldFail(11, lessThanOrEqualTo(10),
        "Expected: a value less than or equal to <10> But: was <11>. "
        "Actual: <11>");
    });

    test('isZero', () {
      shouldPass(0, isZero);
      shouldFail(1, isZero, "Expected: a value equal to <0> But: was <1>."
          " Actual: <1>");
    });

    test('isNonZero', () {
      shouldFail(0, isNonZero, "Expected: a value not equal to <0> "
          "But: was <0>. Actual: <0>");
      shouldPass(1, isNonZero);
    });

    test('isPositive', () {
      shouldFail(-1, isPositive, "Expected: a positive value "
          "But: was <-1>. Actual: <-1>");
      shouldFail(0, isPositive, "Expected: a positive value "
          "But: was <0>. Actual: <0>");
      shouldPass(1, isPositive);
    });

    test('isNegative', () {
      shouldPass(-1, isNegative);
      shouldFail(0, isNegative,
          "Expected: a negative value But: was <0>. Actual: <0>");
    });

    test('isNonPositive', () {
      shouldPass(-1, isNonPositive);
      shouldPass(0, isNonPositive);
      shouldFail(1, isNonPositive,
          "Expected: a non-positive value But: was <1>. Actual: <1>");
    });

    test('isNonNegative', () {
      shouldPass(1, isNonNegative);
      shouldPass(0, isNonNegative);
      shouldFail(-1, isNonNegative,
        "Expected: a non-negative value But: was <-1>. Actual: <-1>");
    });

    test('closeTo', () {
      shouldPass(0, closeTo(0, 1));
      shouldPass(-1, closeTo(0, 1));
      shouldPass(1, closeTo(0, 1));
      shouldFail(1.001, closeTo(0, 1),
          "Expected: a numeric value within <1> of <0> "
          "But: differed by <1.001>. "
          "Actual: <1.001>");
      shouldFail(-1.001, closeTo(0, 1),
          "Expected: a numeric value within <1> of <0> "
          "But: differed by <1.001>. "
          "Actual: <-1.001>");
    });

    test('inInclusiveRange', () {
      shouldFail(-1, inInclusiveRange(0,2),
          "Expected: be in range from 0 (inclusive) to 2 (inclusive) "
          "But: was <-1>. Actual: <-1>");
      shouldPass(0, inInclusiveRange(0,2));
      shouldPass(1, inInclusiveRange(0,2));
      shouldPass(2, inInclusiveRange(0,2));
      shouldFail(3, inInclusiveRange(0,2),
          "Expected: be in range from 0 (inclusive) to 2 (inclusive) "
          "But: was <3>. Actual: <3>");
    });

    test('inExclusiveRange', () {
      shouldFail(0, inExclusiveRange(0,2),
          "Expected: be in range from 0 (exclusive) to 2 (exclusive) "
          "But: was <0>. Actual: <0>");
      shouldPass(1, inExclusiveRange(0,2));
      shouldFail(2, inExclusiveRange(0,2),
          "Expected: be in range from 0 (exclusive) to 2 (exclusive) "
          "But: was <2>. Actual: <2>");
    });

    test('inOpenClosedRange', () {
      shouldFail(0, inOpenClosedRange(0,2),
          "Expected: be in range from 0 (exclusive) to 2 (inclusive) "
          "But: was <0>. Actual: <0>");
      shouldPass(1, inOpenClosedRange(0,2));
      shouldPass(2, inOpenClosedRange(0,2));
    });

    test('inClosedOpenRange', () {
      shouldPass(0, inClosedOpenRange(0,2));
      shouldPass(1, inClosedOpenRange(0,2));
      shouldFail(2, inClosedOpenRange(0,2),
          "Expected: be in range from 0 (inclusive) to 2 (exclusive) "
          "But: was <2>. Actual: <2>");
    });
  });

  group('String Matchers', () {

    test('isEmpty', () {
      shouldPass('', isEmpty);
      shouldFail(null, isEmpty,
          "Expected: empty But: was <null>. Actual: <null>");
      shouldFail(0, isEmpty,
          "Expected: empty But: was <0>. Actual: <0>");
      shouldFail('a', isEmpty, "Expected: empty But: was 'a'. Actual: 'a'");
    });

    test('equalsIgnoringCase', () {
      shouldPass('hello', equalsIgnoringCase('HELLO'));
      shouldFail('hi', equalsIgnoringCase('HELLO'),
          "Expected: 'HELLO' ignoring case But: was 'hi'. Actual: 'hi'");
    });

    test('equalsIgnoringWhitespace', () {
      shouldPass(' hello   world  ', equalsIgnoringWhitespace('hello world'));
      shouldFail(' helloworld  ', equalsIgnoringWhitespace('hello world'),
          "Expected: 'hello world' ignoring whitespace "
          "But: was 'helloworld'. Actual: ' helloworld '");
    });

    test('startsWith', () {
      shouldPass('hello', startsWith(''));
      shouldPass('hello', startsWith('hell'));
      shouldPass('hello', startsWith('hello'));
      shouldFail('hello', startsWith('hello '),
          "Expected: a string starting with 'hello ' "
          "But: was 'hello'. Actual: 'hello'");
    });

    test('endsWith', () {
      shouldPass('hello', endsWith(''));
      shouldPass('hello', endsWith('lo'));
      shouldPass('hello', endsWith('hello'));
      shouldFail('hello', endsWith(' hello'),
          "Expected: a string ending with ' hello' "
          "But: was 'hello'. Actual: 'hello'");
    });

    test('contains', () {
      shouldPass('hello', contains(''));
      shouldPass('hello', contains('h'));
      shouldPass('hello', contains('o'));
      shouldPass('hello', contains('hell'));
      shouldPass('hello', contains('hello'));
      shouldFail('hello', contains(' '),
          "Expected: contains ' ' But: was 'hello'. Actual: 'hello'");
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
        "But: was 'goodbye cruel world'. Actual: 'goodbye cruel world'");
    });

    test('matches', () {
      shouldPass('c0d', matches('[a-z][0-9][a-z]'));
      shouldPass('c0d', matches(new RegExp('[a-z][0-9][a-z]')));
      shouldFail('cOd', matches('[a-z][0-9][a-z]'),
          "Expected: match '[a-z][0-9][a-z]' But: was 'cOd'. Actual: 'cOd'");
    });
  });

  group('Iterable Matchers', () {

    test('isEmpty', () {
      shouldPass([], isEmpty);
      shouldFail([1], isEmpty, "Expected: empty But: was [1]. Actual: [1]");
    });

    test('contains', () {
      var d = [1, 2];
      shouldPass(d, contains(1));
      shouldFail(d, contains(0), "Expected: contains <0> "
          "But: was [1, 2]. Actual: [1, 2]");
    });

    test('isIn', () {
      var d = [1, 2];
      shouldPass(1, isIn(d));
      shouldFail(0, isIn(d), "Expected: is in [1, 2] But: was <0>. Actual: <0>");
    });

    test('everyElement', () {
      var d = [1, 2];
      var e = [1, 1, 1];
      shouldFail(d, everyElement(1),
          "Expected: every element <1> But: position 1 was <2>. "
          "Actual: [1, 2]");
      shouldPass(e, everyElement(1));
    });

    test('someElement', () {
      var d = [1, 2];
      var e = [1, 1, 1];
      shouldPass(d, someElement(2));
      shouldFail(e, someElement(2),
          "Expected: some element <2> But: was [1, 1, 1]. Actual: [1, 1, 1]");
    });

    test('orderedEquals', () {
      shouldPass([null], orderedEquals([null]));
      var d = [1, 2];
      shouldPass(d, orderedEquals([1, 2]));
      shouldFail(d, orderedEquals([2, 1]),
          "Expected: equals [2, 1] ordered "
          "But: expected <2> but was <1> mismatch at position 0. "
          "Actual: [1, 2]");
    });

    test('unorderedEquals', () {
      var d = [1, 2];
      shouldPass(d, unorderedEquals([2, 1]));
      shouldFail(d, unorderedEquals([1]),
          "Expected: equals [1] unordered "
          "But: has too many elements (2 > 1). "
          "Actual: [1, 2]");
      shouldFail(d, unorderedEquals([3, 2, 1]),
          "Expected: equals [3, 2, 1] unordered "
          "But: has too few elements (2 < 3). "
          "Actual: [1, 2]");
      shouldFail(d, unorderedEquals([3, 1]),
          "Expected: equals [3, 1] unordered "
          "But: has no match for element <3> at position 0. "
          "Actual: [1, 2]");
    });

    test('pairwise compare', () {
      var c = [1, 2];
      var d = [1, 2, 3];
      var e = [1, 4, 9];
      shouldFail('x', pairwiseCompare(e, (e,a) => a <= e,
          "less than or equal"),
          "Expected: pairwise less than or equal [1, 4, 9] "
          "But: not an Iterable. "
          "Actual: 'x'");
      shouldFail(c, pairwiseCompare(e, (e,a) => a <= e, "less than or equal"),
          "Expected: pairwise less than or equal [1, 4, 9] "
          "But: length was 2 instead of 3. "
          "Actual: [1, 2]");
      shouldPass(d, pairwiseCompare(e, (e,a) => a <= e, "less than or equal"));
      shouldFail(d, pairwiseCompare(e, (e,a) => a < e, "less than"),
          "Expected: pairwise less than [1, 4, 9] "
          "But: <1> not less than <1> at position 0. "
          "Actual: [1, 2, 3]");
      shouldPass(d, pairwiseCompare(e, (e,a) => a * a == e, "square root of"));
      shouldFail(d, pairwiseCompare(e, (e,a) => a + a == e, "double"),
          "Expected: pairwise double [1, 4, 9] "
          "But: <1> not double <1> at position 0. "
          "Actual: [1, 2, 3]");
    });
  });

  group('Map Matchers', () {

    test('isEmpty', () {
      var a = new Map();
      shouldPass({}, isEmpty);
      shouldPass(a, isEmpty);
      a['foo'] = 'bar';
      shouldFail(a, isEmpty, "Expected: empty But: was {'foo': 'bar'}. "
          "Actual: {'foo': 'bar'}");
    });

    test('equals', () {
      var a = new Map();
      a['foo'] = 'bar';
      var b = new Map();
      b['foo'] = 'bar';
      var c = new Map();
      c['bar'] = 'foo';
      shouldPass(a, equals(b));
      shouldFail(b, equals(c),
          "Expected: {'bar': 'foo'} But: missing map key 'bar'. "
          "Actual: {'foo': 'bar'}");
    });

    test('equals with different lengths', () {
      var a = new LinkedHashMap();
      a['foo'] = 'bar';
      var b = new LinkedHashMap();
      b['foo'] = 'bar';
      b['bar'] = 'foo';
      var c = new LinkedHashMap();
      c['bar'] = 'foo';
      c['barrista'] = 'caffeine';
      shouldFail(a, equals(b),
          "Expected: {'foo': 'bar', 'bar': 'foo'} "
          "But: different map lengths; missing map key 'bar'. "
          "Actual: {'foo': 'bar'}");
      shouldFail(b, equals(a),
          "Expected: {'foo': 'bar'} "
          "But: different map lengths; extra map key 'bar'. "
          "Actual: {'foo': 'bar', 'bar': 'foo'}");
      shouldFail(b, equals(c),
          "Expected: {'bar': 'foo', 'barrista': 'caffeine'} "
          "But: missing map key 'barrista'. "
          "Actual: {'foo': 'bar', 'bar': 'foo'}");
      shouldFail(c, equals(b),
          "Expected: {'foo': 'bar', 'bar': 'foo'} "
          "But: missing map key 'foo'. "
          "Actual: {'bar': 'foo', 'barrista': 'caffeine'}");
      shouldFail(a, equals(c),
          "Expected: {'bar': 'foo', 'barrista': 'caffeine'} "
          "But: different map lengths; missing map key 'bar'. "
          "Actual: {'foo': 'bar'}");
      shouldFail(c, equals(a),
          "Expected: {'foo': 'bar'} "
          "But: different map lengths; missing map key 'foo'. "
          "Actual: {'bar': 'foo', 'barrista': 'caffeine'}");
    });

    test('contains', () {
      var a = new Map();
      a['foo'] = 'bar';
      var b = new Map();
      shouldPass(a, contains('foo'));
      shouldFail(b, contains('foo'),
          "Expected: contains 'foo' But: was {}. Actual: {}");
      shouldFail(10, contains('foo'),
          "Expected: contains 'foo' But: was <10>. Actual: <10>");
    });

    test('containsValue', () {
      var a = new Map();
      a['foo'] = 'bar';
      shouldPass(a, containsValue('bar'));
      shouldFail(a, containsValue('ba'),
          "Expected: contains value 'ba' But: was {'foo': 'bar'}. "
          "Actual: {'foo': 'bar'}");
    });

    test('containsPair', () {
      var a = new Map();
      a['foo'] = 'bar';
      shouldPass(a, containsPair('foo', 'bar'));
      shouldFail(a, containsPair('foo', 'ba'),
          "Expected: contains pair 'foo' => 'ba' "
          "But: Strings are not equal. Both strings start the same, "
          "but the given value also has the following trailing characters: r. "
          "Actual: {'foo': 'bar'}");
      shouldFail(a, containsPair('fo', 'bar'),
          "Expected: contains pair 'fo' => 'bar' "
          "But: doesn't contain key 'fo'. "
          "Actual: {'foo': 'bar'}");
    });

    test('hasLength', () {
      var a = new Map();
      a['foo'] = 'bar';
      var b = new Map();
      shouldPass(a, hasLength(1));
      shouldFail(b, hasLength(1),
          "Expected: an object with length of <1> "
          "But: had length of <0>. "
          "Actual: {}");
    });
  });

  group('Operator Matchers', () {

    test('anyOf', () {
      shouldFail(0, anyOf([equals(1), equals(2)]),
          "Expected: (<1> or <2>) But: was <0>. Actual: <0>");
      shouldPass(1, anyOf([equals(1), equals(2)]));
    });

    test('allOf', () {
      shouldPass(1, allOf([lessThan(10), greaterThan(0)]));
      shouldFail(-1, allOf([lessThan(10), greaterThan(0)]),
          "Expected: (a value less than <10> and a value greater than <0>) "
          "But: was <-1> (wasn't a value greater than <0>). Actual: <-1>");
    });
  });

  group('Future Matchers', () {

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
          "Expected: 'Y' But: Strings are not equal. "
          "Expected: Y Actual: X ^ Differ at position 0. Actual: 'X'",
          isAsync: true);
    });
  });

  group('Predicate Matchers', () {
    test('isInstanceOf', () {
      shouldFail(0, predicate((x) => x is String, "an instance of String"),
          "Expected: an instance of String But: was <0>. Actual: <0>");
      shouldPass('cow', predicate((x) => x is String, "an instance of String"));
    });
  });
}

