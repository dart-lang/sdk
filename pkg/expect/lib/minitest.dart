// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A minimal, dependency-free emulation layer for a subset of the
/// unittest/test API used by the language and core library (especially HTML)
/// tests.
///
/// A number of our language and core library tests were written against the
/// unittest package, which is now deprecated in favor of the new test package.
/// The latter is much better feature-wise, but is also quite complex and has
/// many dependencies. For low-level language and core library tests, we don't
/// want to have to pull in a large number of dependencies and be able to run
/// them correctly in order to run a test, so we want to test them against
/// something simpler.
///
/// When possible, we just use the tiny expect library. But to avoid rewriting
/// all of the existing tests that use unittest, they can instead use this,
/// which shims the unittest API with as little code as possible and calls into
/// expect.
///
/// Eventually, it would be good to refactor those tests to use the expect
/// package directly and remove this.
import 'dart:async';

import 'package:expect/expect.dart';

typedef dynamic _Action();
typedef void _ExpectationFunction(dynamic actual);

final List<_Group> _groups = [new _Group()];

final Object isFalse = new _Expectation(Expect.isFalse);
final Object isNotNull = new _Expectation(Expect.isNotNull);
final Object isNull = new _Expectation(Expect.isNull);
final Object isTrue = new _Expectation(Expect.isTrue);

final Object returnsNormally = new _Expectation((actual) {
  try {
    (actual as _Action)();
  } catch (error) {
    Expect.fail("Expected function to return normally, but threw:\n$error");
  }
});

final Object throws = new _Expectation((actual) {
  Expect.throws(actual as _Action);
});

final Object throwsArgumentError = new _Expectation((actual) {
  Expect.throws(actual as _Action, (error) => error is ArgumentError);
});

final Object throwsNoSuchMethodError = new _Expectation((actual) {
  Expect.throws(actual as _Action, (error) => error is NoSuchMethodError);
});

final Object throwsRangeError = new _Expectation((actual) {
  Expect.throws(actual as _Action, (error) => error is RangeError);
});

final Object throwsStateError = new _Expectation((actual) {
  Expect.throws(actual as _Action, (error) => error is StateError);
});

final Object throwsUnsupportedError = new _Expectation((actual) {
  Expect.throws(actual as _Action, (error) => error is UnsupportedError);
});

/// The test runner should call this once after running a test file.
void finishTests() {
  _groups.clear();
  _groups.add(new _Group());
}

void group(String description, body()) {
  // TODO(rnystrom): Do something useful with the description.
  _groups.add(new _Group());

  try {
    var result = body();
    if (result is Future) {
      Expect.testError("group() does not support asynchronous functions.");
    }
  } finally {
    _groups.removeLast();
  }
}

void test(String description, body()) {
  // TODO(rnystrom): Do something useful with the description.
  for (var group in _groups) {
    var result = group.setUpFunction();
    if (result is Future) {
      Expect.testError("setUp() does not support asynchronous functions.");
    }
  }

  try {
    var result = body();
    if (result is Future) {
      Expect.testError("test() does not support asynchronous functions.");
    }
  } finally {
    for (var i = _groups.length - 1; i >= 0; i--) {
      var group = _groups[i];
      var result = group.tearDownFunction();
      if (result is Future) {
        Expect.testError("tearDown() does not support asynchronous functions.");
      }
    }
  }
}

void setUp(body()) {
  // Can't define multiple setUps at the same level.
  assert(_groups.last.setUpFunction == _defaultAction);
  _groups.last.setUpFunction = body;
}

void tearDown(body()) {
  // Can't define multiple tearDowns at the same level.
  assert(_groups.last.tearDownFunction == _defaultAction);
  _groups.last.tearDownFunction = body;
}

void expect(dynamic actual, dynamic expected, {String reason = ""}) {
  // TODO(rnystrom): Do something useful with reason.
  if (expected is! _Expectation) {
    expected = equals(expected);
  }

  var expectation = expected as _Expectation;
  expectation.function(actual);
}

void fail(String message) {
  Expect.fail(message);
}

Object equals(dynamic value) => new _Expectation((actual) {
      Expect.deepEquals(value, actual);
    });

Object notEquals(dynamic value) => new _Expectation((actual) {
      Expect.notEquals(value, actual);
    });

Object unorderedEquals(dynamic value) => new _Expectation((actual) {
      Expect.setEquals(value as Iterable, actual as Iterable);
    });

Object predicate(bool fn(dynamic value), [String description = ""]) =>
    new _Expectation((actual) {
      Expect.isTrue(fn(actual), description);
    });

Object inInclusiveRange(num min, num max) => new _Expectation((actual) {
      var actualNum = actual as num;
      if (actualNum < min || actualNum > max) {
        fail("Expected $actualNum to be in the inclusive range [$min, $max].");
      }
    });

Object greaterThan(num value) => new _Expectation((actual) {
      var actualNum = actual as num;
      if (actualNum <= value) {
        fail("Expected $actualNum to be greater than $value.");
      }
    });

Object same(dynamic value) => new _Expectation((actual) {
      Expect.identical(value, actual);
    });

Object closeTo(num value, num tolerance) => new _Expectation((actual) {
      Expect.approxEquals(value, actual as num, tolerance);
    });

/// Succeeds if the actual value is any of the given strings. Unlike matcher's
/// [anyOf], this only works with strings and requires an explicit list.
Object anyOf(List<String> expected) => new _Expectation((actual) {
      for (var string in expected) {
        if (actual == string) return;
      }

      fail("Expected $actual to be one of $expected.");
    });

_defaultAction() {}

/// One level of group() nesting to track an optional [setUp()] and [tearDown()]
/// function for the group.
///
/// There is also an implicit top level group.
class _Group {
  _Action setUpFunction = _defaultAction;
  _Action tearDownFunction = _defaultAction;
}

/// A wrapper around an expectation function.
///
/// This function is passed the actual value and should throw an
/// [ExpectException] if the value doesn't match the expectation.
class _Expectation {
  final _ExpectationFunction function;

  _Expectation(this.function);
}
