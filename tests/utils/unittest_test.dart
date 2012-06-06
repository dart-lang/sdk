// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('unittestTest');

#import('../../lib/unittest/unittest.dart');


doesNotThrow() {}
doesThrow() { throw 'X'; }

int errorCount;
String errorString;
var testHandler;

class MyFailureHandler extends DefaultFailureHandler {
  void fail(String reason) {
    ++errorCount;
    errorString = reason;
  }
}

void shouldFail(var value, Matcher matcher, expected) {
  errorCount = 0;
  errorString = '';
  configureExpectHandler(testHandler);
  expect(value, matcher);
  configureExpectHandler(null);
  expect(errorCount, equals(1));
  if (expected is String)
    expect(errorString, equalsIgnoringWhitespace(expected));
  else
   expect(errorString, expected);
}

void shouldPass(var value, Matcher matcher) {
  errorCount = 0;
  errorString = '';
  configureExpectHandler(testHandler);
  expect(value, matcher);
  configureExpectHandler(null);
  expect(errorCount, equals(0));
}

class PrefixMatcher extends BaseMatcher {
  final String _prefix;
  const PrefixMatcher(this._prefix);
  bool matches(item) {
    return item is String &&
        (collapseWhitespace(item)).startsWith(collapseWhitespace(_prefix));
  }

  Description describe(Description description) =>
    description.add('a string starting with ').
        addDescriptionOf(collapseWhitespace(_prefix)).
        add(' ignoring whitespace');
}

void main() {

  testHandler = new MyFailureHandler();

  var a = new Map();
  var b = new Map();
  var c = new List();

  // Core matchers

  group('Core matchers', () {
    test('isTrue', () {
      shouldPass(true, isTrue);
      shouldFail(false, isTrue, "Expected: true but: was <false>");
    });

    test('isFalse', () {
      shouldPass(false, isFalse);
      shouldFail(true, isFalse, "Expected: false but: was <true>");
    });

    test('isNull', () {
      shouldPass(null, isNull);
      shouldFail(false, isNull, "Expected: null but: was <false>");
    });

    test('isNotNull', () {
      shouldPass(false, isNotNull);
      shouldFail(null, isNotNull, "Expected: not null but: was <null>");
    });

    test('same', () {
      shouldPass(a, same(a));
      shouldFail(b, same(a), "Expected: same instance as <{}> but: was <{}>");
    });

    test('equals', () {
      shouldPass(a, equals(a));
      shouldFail(a, equals(b), "Expected: <{}> but: was <{}>");
    });

    test('anything', () {
      shouldPass(a, anything);
      shouldFail(a, isNot(anything), "Expected: not anything but: was <{}>");
    });

    test('throws', () {
      shouldFail(doesNotThrow, throws,
        "Expected: throws an exception but: no exception");
      shouldPass(doesThrow, throws);
    });

    test('throwsA', () {
      shouldPass(doesThrow, throwsA(equals('X')));
      shouldFail(doesThrow, throwsA(equals('Y')),
        "Expected: throws an exception which matches 'Y' "
        "but:  exception does not match 'Y'");
    });

    test('returnsNormally', () {
      shouldPass(doesNotThrow, returnsNormally);
      shouldFail(doesThrow, returnsNormally,
        "Expected: return normally but: threw exception");
    });

    test('isInstanceOf', () {
      shouldFail(0, new isInstanceOf<String>('String'),
        "Expected: an instance of String but: was <0>");
      shouldPass('cow', new isInstanceOf<String>('String'));
    });

    test('hasLength', () {
      shouldPass(c, hasLength(0));
      shouldPass(a, hasLength(0));
      shouldPass('a', hasLength(1));
      shouldFail(0, hasLength(0), new PrefixMatcher(
        "Expected: an object with length of <0> "
        "but: was <0> has no length property"));

      c.add(0);
      shouldPass(c, hasLength(1));
      shouldFail(c, hasLength(2),
        "Expected: an object with length of <2> "
        "but: was <[0]> with length of <1>");

      c.add(0);
      shouldFail(c, hasLength(1),
        "Expected: an object with length of <1> "
        "but: was <[0, 0]> with length of <2>");
      shouldPass(c, hasLength(2));
    });
  });

  group('Numeric Matchers', () {

    test('greaterThan', () {
      shouldPass(10, greaterThan(9));
      shouldFail(9, greaterThan(10),
        "Expected: a value greater than <10> but: was <9>");
    });

    test('greaterThanOrEqualTo', () {
      shouldPass(10, greaterThanOrEqualTo(10));
      shouldFail(9, greaterThanOrEqualTo(10),
        "Expected: a value greater than or equal to <10> but: was <9>");
    });

    test('lessThan', () {
      shouldFail(10, lessThan(9), "Expected: a value less than <9> "
          "but: was <10>");
      shouldPass(9, lessThan(10));
    });

    test('lessThanOrEqualTo', () {
      shouldPass(10, lessThanOrEqualTo(10));
      shouldFail(11, lessThanOrEqualTo(10),
        "Expected: a value less than or equal to <10> but: was <11>");
    });

    test('isZero', () {
      shouldPass(0, isZero);
      shouldFail(1, isZero, "Expected: a value equal to <0> but: was <1>");
    });

    test('isNonZero', () {
      shouldFail(0, isNonZero, "Expected: a value not equal to <0> "
          "but: was <0>");
      shouldPass(1, isNonZero);
    });

    test('isPositive', () {
      shouldFail(-1, isPositive, "Expected: a positive value "
          "but: was <-1>");
      shouldFail(0, isPositive, "Expected: a positive value "
          "but: was <0>");
      shouldPass(1, isPositive);
    });

    test('isNegative', () {
      shouldPass(-1, isNegative);
      shouldFail(0, isNegative,
          "Expected: a negative value but: was <0>");
    });

    test('isNonPositive', () {
      shouldPass(-1, isNonPositive);
      shouldPass(0, isNonPositive);
      shouldFail(1, isNonPositive,
          "Expected: a non-positive value but: was <1>");
    });

    test('isNonNegative', () {
      shouldPass(1, isNonNegative);
      shouldPass(0, isNonNegative);
      shouldFail(-1, isNonNegative,
        "Expected: a non-negative value but: was <-1>");
    });

    test('closeTo', () {
      shouldPass(0, closeTo(0, 1));
      shouldPass(-1, closeTo(0, 1));
      shouldPass(1, closeTo(0, 1));
      shouldFail(1.001, closeTo(0, 1),
          "Expected: a numeric value within <1> of <0> "
          "but: <1.001> differed by <1.001>");
      shouldFail(-1.001, closeTo(0, 1),
          "Expected: a numeric value within <1> of <0> "
          "but: <-1.001> differed by <1.001>");
    });

    test('inInclusiveRange', () {
      shouldFail(-1, inInclusiveRange(0,2),
          "Expected: be in range from 0 (inclusive) to 2 (inclusive) "
          "but: was <-1>");
      shouldPass(0, inInclusiveRange(0,2));
      shouldPass(1, inInclusiveRange(0,2));
      shouldPass(2, inInclusiveRange(0,2));
      shouldFail(3, inInclusiveRange(0,2),
          "Expected: be in range from 0 (inclusive) to 2 (inclusive) "
          "but: was <3>");
    });

    test('inExclusiveRange', () {
      shouldFail(0, inExclusiveRange(0,2),
          "Expected: be in range from 0 (exclusive) to 2 (exclusive) "
          "but: was <0>");
      shouldPass(1, inExclusiveRange(0,2));
      shouldFail(2, inExclusiveRange(0,2),
          "Expected: be in range from 0 (exclusive) to 2 (exclusive) "
          "but: was <2>");
    });

    test('inOpenClosedRange', () {
      shouldFail(0, inOpenClosedRange(0,2),
          "Expected: be in range from 0 (exclusive) to 2 (inclusive) "
          "but: was <0>");
      shouldPass(1, inOpenClosedRange(0,2));
      shouldPass(2, inOpenClosedRange(0,2));
    });

    test('inClosedOpenRange', () {
      shouldPass(0, inClosedOpenRange(0,2));
      shouldPass(1, inClosedOpenRange(0,2));
      shouldFail(2, inClosedOpenRange(0,2),
          "Expected: be in range from 0 (inclusive) to 2 (exclusive) "
          "but: was <2>");
    });
  });


  group('String Matchers', () {

    test('isEmpty', () {
      shouldPass('', isEmpty);
      shouldFail(null, isEmpty,
          "Expected: empty but: was <null>");
      shouldFail(0, isEmpty,
          "Expected: empty but: was <0>");
      shouldFail('a', isEmpty, "Expected: empty but: was 'a'");
    });

    test('equalsIgnoringCase', () {
      shouldPass('hello', equalsIgnoringCase('HELLO'));
      shouldFail('hi', equalsIgnoringCase('HELLO'),
          "Expected: 'HELLO' ignoring case but: was 'hi'");
    });

    test('equalsIgnoringWhitespace', () {
      shouldPass(' hello   world  ', equalsIgnoringWhitespace('hello world'));
      shouldFail(' helloworld  ', equalsIgnoringWhitespace('hello world'),
          "Expected: 'hello world' ignoring whitespace but: was 'helloworld'");
    });

    test('startsWith', () {
      shouldPass('hello', startsWith(''));
      shouldPass('hello', startsWith('hell'));
      shouldPass('hello', startsWith('hello'));
      shouldFail('hello', startsWith('hello '),
          "Expected: a string starting with 'hello ' but: was 'hello'");
    });

    test('endsWith', () {
      shouldPass('hello', endsWith(''));
      shouldPass('hello', endsWith('lo'));
      shouldPass('hello', endsWith('hello'));
      shouldFail('hello', endsWith(' hello'),
          "Expected: a string ending with ' hello' but: was 'hello'");
    });

    test('contains', () {
      shouldPass('hello', contains(''));
      shouldPass('hello', contains('h'));
      shouldPass('hello', contains('o'));
      shouldPass('hello', contains('hell'));
      shouldPass('hello', contains('hello'));
      shouldFail('hello', contains(' '),
          "Expected: contains ' ' but: was 'hello'");
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
        "but: was 'goodbye cruel world'");
    });

    test('matches', () {
      shouldPass('c0d', matches('[a-z][0-9][a-z]'));
      shouldPass('c0d', matches(new RegExp('[a-z][0-9][a-z]')));
      shouldFail('cOd', matches('[a-z][0-9][a-z]'),
          "Expected: match '[a-z][0-9][a-z]' but: was 'cOd'");
    });
  });

  group('Collection Matchers', () {

    test('isEmpty', () {
      shouldPass([], isEmpty);
      shouldFail([1], isEmpty, "Expected: empty but: was <[1]>");
    });

    var d = [1, 2];

    test('contains', () {
      shouldPass(d, contains(1));
      shouldFail(d, contains(0), "Expected: contains <0> but: was <[1, 2]>");
    });

    var e = [1, 1, 1];

    test('everyElement', () {
      shouldFail(d, everyElement(1),
          "Expected: every element <1> but: was <[1, 2]>");
      shouldPass(e, everyElement(1));
    });

    test('someElement', () {
      shouldPass(d, someElement(2));
      shouldFail(e, someElement(2),
          "Expected: some element <2> but: was <[1, 1, 1]>");
    });

    test('orderedEquals', () {
      shouldPass(d, orderedEquals([1, 2]));
      shouldFail(d, orderedEquals([2, 1]),
          "Expected: equals <[2, 1]> ordered "
          "but: mismatch at position 0");
    });

    test('unorderedEquals', () {
      shouldPass(d, unorderedEquals([2, 1]));
      shouldFail(d, unorderedEquals([1]),
          "Expected: equals <[1]> unordered "
          "but: has too many elements (2 > 1)");
      shouldFail(d, unorderedEquals([3, 2, 1]),
          "Expected: equals <[3, 2, 1]> unordered "
          "but: has too few elements (2 < 3)");
      shouldFail(d, unorderedEquals([3, 1]),
          "Expected: equals <[3, 1]> unordered "
          "but: has no match for element 3 at position 0");
    });
  });

  group('Map Matchers', () {

    test('isEmpty', () {
      shouldPass({}, isEmpty);
      shouldPass(a, isEmpty);
      a['foo'] = 'bar';
      shouldFail(a, isEmpty, "Expected: empty but: was <{foo: bar}>");
    });

    test('contains', () {
      shouldPass(a, contains('foo'));
      shouldFail(b, contains('foo'),
          "Expected: contains 'foo' but: was <{}>");
      shouldFail(10, contains('foo'),
          "Expected: contains 'foo' but: was <10>");
    });

    test('containsValue', () {
      shouldPass(a, containsValue('bar'));
      shouldFail(a, containsValue('ba'),
          "Expected: contains value 'ba' but: was <{foo: bar}>");
    });

    test('containsPair', () {
      shouldPass(a, containsPair('foo', 'bar'));
      shouldFail(a, containsPair('foo', 'ba'),
          "Expected: contains pair 'foo' => 'ba' "
          "but:  contains key 'foo' but with value ");
      shouldFail(a, containsPair('fo', 'bar'),
          "Expected: contains pair 'fo' => 'bar' "
          "but: <{foo: bar}>' doesn't contain key ''fo'");
    });

    test('hasLength', () {
      shouldPass(a, hasLength(1));
      shouldFail(b, hasLength(1),
          "Expected: an object with length of <1> "
          "but: was <{}> with length of <0>");
    });
  });

  group('Operator Matchers', () {

    test('anyOf', () {
      shouldFail(0, anyOf([equals(1), equals(2)]),
          "Expected: (<1> or <2>) but: was <0>");
      shouldPass(1, anyOf([equals(1), equals(2)]));
    });

    test('allOf', () {
      shouldPass(1, allOf([lessThan(10), greaterThan(0)]));
      shouldFail(-1, allOf([lessThan(10), greaterThan(0)]),
          "Expected: (a value less than <10> and a value greater than <0>) "
          "but: a value greater than <0> was <-1>");
    });
  });
}


