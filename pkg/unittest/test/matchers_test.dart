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
      shouldFail(false, isTrue, "Expected: true Actual: <false>");
    });

    test('isFalse', () {
      shouldPass(false, isFalse);
      shouldFail(10, isFalse, "Expected: false Actual: <10>");
      shouldFail(true, isFalse, "Expected: false Actual: <true>");
    });

    test('isNull', () {
      shouldPass(null, isNull);
      shouldFail(false, isNull, "Expected: null Actual: <false>");
    });

    test('isNotNull', () {
      shouldPass(false, isNotNull);
      shouldFail(null, isNotNull, "Expected: not null Actual: <null>");
    });

    test('same', () {
      var a = new Map();
      var b = new Map();
      shouldPass(a, same(a));
      shouldFail(b, same(a), "Expected: same instance as {} Actual: {}");
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
      shouldFail(a, isNot(anything), "Expected: not anything Actual: {}");
    });

    test('throws', () {
      shouldFail(doesNotThrow, throws,
          matches(
              r"Expected: throws"
              r"  Actual: <Closure(: \(\) => dynamic "
              r"from Function 'doesNotThrow': static\.)?>"
              r"   Which: did not throw"));
      shouldPass(doesThrow, throws);
      shouldFail(true, throws,
          "Expected: throws"
          "  Actual: <true>"
          "   Which: is not a Function or Future");
    });

    test('throwsA', () {
      shouldPass(doesThrow, throwsA(equals('X')));
      shouldFail(doesThrow, throwsA(equals('Y')),
          matches(
              r"Expected: throws 'Y'"
              r"  Actual: <Closure(: \(\) => dynamic "
              r"from Function 'doesThrow': static\.)?>"
              r"   Which: threw 'X'"));
    });

    test('returnsNormally', () {
      shouldPass(doesNotThrow, returnsNormally);
      shouldFail(doesThrow, returnsNormally,
          matches(
              r"Expected: return normally"
              r"  Actual: <Closure(: \(\) => dynamic "
              r"from Function 'doesThrow': static\.)?>"
              r"   Which: threw 'X'"));
    });


    test('hasLength', () {
      var a = new Map();
      var b = new List();
      shouldPass(a, hasLength(0));
      shouldPass(b, hasLength(0));
      shouldPass('a', hasLength(1));
      shouldFail(0, hasLength(0), new PrefixMatcher(
          "Expected: an object with length of <0> "
          "Actual: <0> "
          "Which: has no length property"));

      b.add(0);
      shouldPass(b, hasLength(1));
      shouldFail(b, hasLength(2),
          "Expected: an object with length of <2> "
          "Actual: [0] "
          "Which: has length of <1>");

      b.add(0);
      shouldFail(b, hasLength(1),
          "Expected: an object with length of <1> "
          "Actual: [0, 0] "
          "Which: has length of <2>");
      shouldPass(b, hasLength(2));
    });

    test('scalar type mismatch', () {
      shouldFail('error', equals(5.1),
          "Expected: <5.1> "
          "Actual: 'error'");
    });

    test('nested type mismatch', () {
      shouldFail(['error'], equals([5.1]),
          "Expected: [5.1] "
          "Actual: ['error'] "
          "Which: was 'error' instead of <5.1> at location [0]");
    });

    test('doubly-nested type mismatch', () {
      shouldFail([['error']], equals([[5.1]]),
          "Expected: [[5.1]] "
          "Actual: [['error']] "
          "Which: was 'error' instead of <5.1> at location [0][0]");
    });

    test('doubly nested inequality', () {
      var actual1 = [['foo', 'bar'], ['foo'], 3, []];
      var expected1 = [['foo', 'bar'], ['foo'], 4, []];
      var reason1 = "Expected: [['foo', 'bar'], ['foo'], 4, []] "
          "Actual: [['foo', 'bar'], ['foo'], 3, []] "
          "Which: was <3> instead of <4> at location [2]";

      var actual2 = [['foo', 'barry'], ['foo'], 4, []];
      var expected2 = [['foo', 'bar'], ['foo'], 4, []];
      var reason2 = "Expected: [['foo', 'bar'], ['foo'], 4, []] "
          "Actual: [['foo', 'barry'], ['foo'], 4, []] "
          "Which: was 'barry' instead of 'bar' at location [0][1]";

      var actual3 = [['foo', 'bar'], ['foo'], 4, {'foo':'bar'}];
      var expected3 = [['foo', 'bar'], ['foo'], 4, {'foo':'barry'}];
      var reason3 = "Expected: [['foo', 'bar'], ['foo'], 4, {'foo': 'barry'}] "
          "Actual: [['foo', 'bar'], ['foo'], 4, {'foo': 'bar'}] "
          "Which: was 'bar' instead of 'barry' at location [3]['foo']";

      shouldFail(actual1, equals(expected1), reason1);
      shouldFail(actual2, equals(expected2), reason2);
      shouldFail(actual3, equals(expected3), reason3);
    });
  });

  group('Numeric Matchers', () {

    test('greaterThan', () {
      shouldPass(10, greaterThan(9));
      shouldFail(9, greaterThan(10),
        "Expected: a value greater than <10> "
        "Actual: <9> "
        "Which: is not a value greater than <10>");
    });

    test('greaterThanOrEqualTo', () {
      shouldPass(10, greaterThanOrEqualTo(10));
      shouldFail(9, greaterThanOrEqualTo(10),
        "Expected: a value greater than or equal to <10> "
        "Actual: <9> "
        "Which: is not a value greater than or equal to <10>");
    });

    test('lessThan', () {
      shouldFail(10, lessThan(9),
          "Expected: a value less than <9> "
          "Actual: <10> "
          "Which: is not a value less than <9>");
      shouldPass(9, lessThan(10));
    });

    test('lessThanOrEqualTo', () {
      shouldPass(10, lessThanOrEqualTo(10));
      shouldFail(11, lessThanOrEqualTo(10),
        "Expected: a value less than or equal to <10> "
        "Actual: <11> "
        "Which: is not a value less than or equal to <10>");
    });

    test('isZero', () {
      shouldPass(0, isZero);
      shouldFail(1, isZero, 
          "Expected: a value equal to <0> "
          "Actual: <1> "
          "Which: is not a value equal to <0>");
    });

    test('isNonZero', () {
      shouldFail(0, isNonZero,
          "Expected: a value not equal to <0> "
          "Actual: <0> "
          "Which: is not a value not equal to <0>");
      shouldPass(1, isNonZero);
    });

    test('isPositive', () {
      shouldFail(-1, isPositive,
          "Expected: a positive value "
          "Actual: <-1> "
          "Which: is not a positive value");
      shouldFail(0, isPositive, 
          "Expected: a positive value "
          "Actual: <0> "
          "Which: is not a positive value");
      shouldPass(1, isPositive);
    });

    test('isNegative', () {
      shouldPass(-1, isNegative);
      shouldFail(0, isNegative,
          "Expected: a negative value "
          "Actual: <0> "
          "Which: is not a negative value");
    });

    test('isNonPositive', () {
      shouldPass(-1, isNonPositive);
      shouldPass(0, isNonPositive);
      shouldFail(1, isNonPositive,
          "Expected: a non-positive value "
          "Actual: <1> "
          "Which: is not a non-positive value");
    });

    test('isNonNegative', () {
      shouldPass(1, isNonNegative);
      shouldPass(0, isNonNegative);
      shouldFail(-1, isNonNegative,
        "Expected: a non-negative value "
        "Actual: <-1> "
        "Which: is not a non-negative value");
    });

    test('closeTo', () {
      shouldPass(0, closeTo(0, 1));
      shouldPass(-1, closeTo(0, 1));
      shouldPass(1, closeTo(0, 1));
      shouldFail(1.001, closeTo(0, 1),
          "Expected: a numeric value within <1> of <0> "
          "Actual: <1.001> "
          "Which: differs by <1.001>");
      shouldFail(-1.001, closeTo(0, 1),
          "Expected: a numeric value within <1> of <0> "
          "Actual: <-1.001> "
          "Which: differs by <1.001>");
    });

    test('inInclusiveRange', () {
      shouldFail(-1, inInclusiveRange(0,2),
          "Expected: be in range from 0 (inclusive) to 2 (inclusive) "
          "Actual: <-1>");
      shouldPass(0, inInclusiveRange(0,2));
      shouldPass(1, inInclusiveRange(0,2));
      shouldPass(2, inInclusiveRange(0,2));
      shouldFail(3, inInclusiveRange(0,2),
          "Expected: be in range from 0 (inclusive) to 2 (inclusive) "
          "Actual: <3>");
    });

    test('inExclusiveRange', () {
      shouldFail(0, inExclusiveRange(0,2),
          "Expected: be in range from 0 (exclusive) to 2 (exclusive) "
          "Actual: <0>");
      shouldPass(1, inExclusiveRange(0,2));
      shouldFail(2, inExclusiveRange(0,2),
          "Expected: be in range from 0 (exclusive) to 2 (exclusive) "
          "Actual: <2>");
    });

    test('inOpenClosedRange', () {
      shouldFail(0, inOpenClosedRange(0,2),
          "Expected: be in range from 0 (exclusive) to 2 (inclusive) "
          "Actual: <0>");
      shouldPass(1, inOpenClosedRange(0,2));
      shouldPass(2, inOpenClosedRange(0,2));
    });

    test('inClosedOpenRange', () {
      shouldPass(0, inClosedOpenRange(0,2));
      shouldPass(1, inClosedOpenRange(0,2));
      shouldFail(2, inClosedOpenRange(0,2),
          "Expected: be in range from 0 (inclusive) to 2 (exclusive) "
          "Actual: <2>");
    });
  });

  group('String Matchers', () {

    test('isEmpty', () {
      shouldPass('', isEmpty);
      shouldFail(null, isEmpty,
          "Expected: empty Actual: <null>");
      shouldFail(0, isEmpty,
          "Expected: empty Actual: <0>");
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
  });

  group('Iterable Matchers', () {

    test('isEmpty', () {
      shouldPass([], isEmpty);
      shouldFail([1], isEmpty, "Expected: empty Actual: [1]");
    });

    test('contains', () {
      var d = [1, 2];
      shouldPass(d, contains(1));
      shouldFail(d, contains(0), "Expected: contains <0> "
          "Actual: [1, 2]");
    });

    test('isIn', () {
      var d = [1, 2];
      shouldPass(1, isIn(d));
      shouldFail(0, isIn(d), "Expected: is in [1, 2] Actual: <0>");
    });

    test('everyElement', () {
      var d = [1, 2];
      var e = [1, 1, 1];
      shouldFail(d, everyElement(1),
          "Expected: every element(<1>) "
          "Actual: [1, 2] "
          "Which: has value <2> which doesn't match <1> at index 1");
      shouldPass(e, everyElement(1));
    });

    test('nested everyElement', () {
      var d = [['foo', 'bar'], ['foo'], []];
      var e = [['foo', 'bar'], ['foo'], 3, []];
      shouldPass(d, everyElement(anyOf(isEmpty, contains('foo'))));
      shouldFail(d, everyElement(everyElement(equals('foo'))),
          "Expected: every element(every element('foo')) "
          "Actual: [['foo', 'bar'], ['foo'], []] "
          "Which: has value ['foo', 'bar'] which has value 'bar' "
          "which is different. Expected: foo Actual: bar ^ "
          "Differ at offset 0 at index 1 at index 0");
      shouldFail(d, everyElement(allOf(hasLength(greaterThan(0)), 
          contains('foo'))),
           "Expected: every element((an object with length of a value "
           "greater than <0> and contains 'foo')) "
           "Actual: [['foo', 'bar'], ['foo'], []] "
           "Which: has value [] which has length of <0> at index 2");
      shouldFail(d, everyElement(allOf(contains('foo'),
          hasLength(greaterThan(0)))),
          "Expected: every element((contains 'foo' and "
          "an object with length of a value greater than <0>)) "
          "Actual: [['foo', 'bar'], ['foo'], []] "
          "Which: has value [] which doesn't match (contains 'foo' and "
          "an object with length of a value greater than <0>) at index 2");
      shouldFail(e, everyElement(allOf(contains('foo'),
          hasLength(greaterThan(0)))),
          "Expected: every element((contains 'foo' and an object with "
          "length of a value greater than <0>)) "
          "Actual: [['foo', 'bar'], ['foo'], 3, []] "
          "Which: has value <3> which is not a string, map or iterable "
          "at index 2");
    });

    test('someElement', () {
      var d = [1, 2];
      var e = [1, 1, 1];
      shouldPass(d, someElement(2));
      shouldFail(e, someElement(2),
          "Expected: some element <2> Actual: [1, 1, 1]");
    });

    test('orderedEquals', () {
      shouldPass([null], orderedEquals([null]));
      var d = [1, 2];
      shouldPass(d, orderedEquals([1, 2]));
      shouldFail(d, orderedEquals([2, 1]),
          "Expected: equals [2, 1] ordered "
          "Actual: [1, 2] "
          "Which: was <1> instead of <2> at location [0]");
    });

    test('unorderedEquals', () {
      var d = [1, 2];
      shouldPass(d, unorderedEquals([2, 1]));
      shouldFail(d, unorderedEquals([1]),
          "Expected: equals [1] unordered "
          "Actual: [1, 2] "
          "Which: has too many elements (2 > 1)");
      shouldFail(d, unorderedEquals([3, 2, 1]),
          "Expected: equals [3, 2, 1] unordered "
          "Actual: [1, 2] "
          "Which: has too few elements (2 < 3)");
      shouldFail(d, unorderedEquals([3, 1]),
          "Expected: equals [3, 1] unordered "
          "Actual: [1, 2] "
          "Which: has no match for element <3> at index 0");
    });

    test('pairwise compare', () {
      var c = [1, 2];
      var d = [1, 2, 3];
      var e = [1, 4, 9];
      shouldFail('x', pairwiseCompare(e, (e,a) => a <= e,
          "less than or equal"),
          "Expected: pairwise less than or equal [1, 4, 9] "
          "Actual: 'x' "
          "Which: is not an Iterable");
      shouldFail(c, pairwiseCompare(e, (e,a) => a <= e, "less than or equal"),
          "Expected: pairwise less than or equal [1, 4, 9] "
          "Actual: [1, 2] "
          "Which: has length 2 instead of 3");
      shouldPass(d, pairwiseCompare(e, (e,a) => a <= e, "less than or equal"));
      shouldFail(d, pairwiseCompare(e, (e,a) => a < e, "less than"),
          "Expected: pairwise less than [1, 4, 9] "
          "Actual: [1, 2, 3] "
          "Which: has <1> which is not less than <1> at index 0");
      shouldPass(d, pairwiseCompare(e, (e,a) => a * a == e, "square root of"));
      shouldFail(d, pairwiseCompare(e, (e,a) => a + a == e, "double"),
          "Expected: pairwise double [1, 4, 9] "
          "Actual: [1, 2, 3] "
          "Which: has <1> which is not double <1> at index 0");
    });
  });

  group('Map Matchers', () {

    test('isEmpty', () {
      var a = new Map();
      shouldPass({}, isEmpty);
      shouldPass(a, isEmpty);
      a['foo'] = 'bar';
      shouldFail(a, isEmpty, "Expected: empty "
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
          "Expected: {'bar': 'foo'} "
          "Actual: {'foo': 'bar'} "
          "Which: is missing map key 'bar'");
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
          "Actual: {'foo': 'bar'} "
          "Which: has different length and is missing map key 'bar'");
      shouldFail(b, equals(a),
          "Expected: {'foo': 'bar'} "
          "Actual: {'foo': 'bar', 'bar': 'foo'} "
          "Which: has different length and has extra map key 'bar'");
      shouldFail(b, equals(c),
          "Expected: {'bar': 'foo', 'barrista': 'caffeine'} "
          "Actual: {'foo': 'bar', 'bar': 'foo'} "
          "Which: is missing map key 'barrista'");
      shouldFail(c, equals(b),
          "Expected: {'foo': 'bar', 'bar': 'foo'} "
          "Actual: {'bar': 'foo', 'barrista': 'caffeine'} "
          "Which: is missing map key 'foo'");
      shouldFail(a, equals(c),
          "Expected: {'bar': 'foo', 'barrista': 'caffeine'} "
          "Actual: {'foo': 'bar'} "
          "Which: has different length and is missing map key 'bar'");
      shouldFail(c, equals(a),
          "Expected: {'foo': 'bar'} "
          "Actual: {'bar': 'foo', 'barrista': 'caffeine'} "
          "Which: has different length and is missing map key 'foo'");
    });

    test('contains', () {
      var a = new Map();
      a['foo'] = 'bar';
      var b = new Map();
      shouldPass(a, contains('foo'));
      shouldFail(b, contains('foo'),
          "Expected: contains 'foo' Actual: {}");
      shouldFail(10, contains('foo'),
          "Expected: contains 'foo' Actual: <10> "
          "Which: is not a string, map or iterable");
    });

    test('containsValue', () {
      var a = new Map();
      a['foo'] = 'bar';
      shouldPass(a, containsValue('bar'));
      shouldFail(a, containsValue('ba'),
          "Expected: contains value 'ba' "
          "Actual: {'foo': 'bar'}");
    });

    test('containsPair', () {
      var a = new Map();
      a['foo'] = 'bar';
      shouldPass(a, containsPair('foo', 'bar'));
      shouldFail(a, containsPair('foo', 'ba'),
          "Expected: contains pair 'foo' => 'ba' "
          "Actual: {'foo': 'bar'} "
          "Which: is different. Both strings start the same, but "
          "the given value also has the following trailing characters: r");
      shouldFail(a, containsPair('fo', 'bar'),
          "Expected: contains pair 'fo' => 'bar' "
          "Actual: {'foo': 'bar'} "
          "Which: doesn't contain key 'fo'");
    });

    test('hasLength', () {
      var a = new Map();
      a['foo'] = 'bar';
      var b = new Map();
      shouldPass(a, hasLength(1));
      shouldFail(b, hasLength(1),
          "Expected: an object with length of <1> "
          "Actual: {} "
          "Which: has length of <0>");
    });
  });

  group('Operator Matchers', () {

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
          "Expected: 'Y' Actual: 'X' "
          "Which: is different. "
          "Expected: Y Actual: X ^ Differ at offset 0",
          isAsync: true);
    });
  });

  group('Predicate Matchers', () {
    test('isInstanceOf', () {
      shouldFail(0, predicate((x) => x is String, "an instance of String"),
          "Expected: an instance of String Actual: <0>");
      shouldPass('cow', predicate((x) => x is String, "an instance of String"));
    });
  });
}

