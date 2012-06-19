// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/**
 * Returns a matcher that matches empty strings, maps or collections.
 */
final Matcher isEmpty = const _Empty();

class _Empty extends BaseMatcher {
  const _Empty();
  bool matches(item) {
    if (item is Map || item is Collection) {
      return item.isEmpty();
    } else if (item is String) {
      return item.length == 0;
    } else {
      return false;
    }
  }
  Description describe(Description description) =>
      description.add('empty');
}

/** A matcher that matches any null value. */
final Matcher isNull = const _IsNull();

/** A matcher that matches any non-null value. */
final Matcher isNotNull = const _IsNotNull();

class _IsNull extends BaseMatcher {
  const _IsNull();
  bool matches(item) => item == null;
  Description describe(Description description) =>
      description.add('null');
}

class _IsNotNull extends BaseMatcher {
  const _IsNotNull();
  bool matches(item) => item != null;
  Description describe(Description description) =>
      description.add('not null');
}

/** A matcher that matches the Boolean value true. */
final Matcher isTrue = const _IsTrue();

/** A matcher that matches anything except the Boolean value true. */
final Matcher isFalse = const _IsFalse();

class _IsTrue extends BaseMatcher {
  const _IsTrue();
  bool matches(item) => item == true;
  Description describe(Description description) =>
      description.add('true');
}

class _IsFalse extends BaseMatcher {
  const _IsFalse();
  bool matches(item) => item != true;
  Description describe(Description description) =>
      description.add('false');
}

/**
 * Returns a matches that matches if the value is the same instance
 * as [object] (`===`).
 */
Matcher same(expected) => new _IsSameAs(expected);

class _IsSameAs extends BaseMatcher {
  final _expected;
  const _IsSameAs(this._expected);
  bool matches(item) => item === _expected;
  // If all types were hashable we could show a hash here.
  Description describe(Description description) =>
      description.add('same instance as ').addDescriptionOf(_expected);
}

/** Returns a matcher that matches if two objects are equal (==). */
Matcher equals(expected) => new _IsEqual(expected);

class _IsEqual extends BaseMatcher {
  final _expected;
  const _IsEqual(this._expected);
  bool matches(item) => item == _expected;
  Description describe(Description description) =>
      description.addDescriptionOf(_expected);
}

/** A matcher that matches any value. */
final Matcher anything = const _IsAnything();

class _IsAnything extends BaseMatcher {
  const _IsAnything();
  bool matches(item) => true;
  Description describe(Description description) =>
      description.add('anything');
}

/**
 * Returns a matcher that matches if an object is an instance
 * of [type] (or a subtype).
 *
 * As types are not first class objects in Dart we can only
 * approximate this test by using a generic wrapper class.
 *
 * For example, to test whether 'bar' is an instance of type
 * 'Foo', we would write:
 *
 *     expect(bar, new isInstanceOf<Foo>());
 *
 * To get better error message, supply a name when creating the
 * Type wrapper; e.g.:
 *
 *     expect(bar, new isInstanceOf<Foo>('Foo'));
 */
class isInstanceOf<T> extends BaseMatcher {
  final String _name;
  const isInstanceOf([name = 'specified type']) : this._name = name;
  bool matches(obj) => obj is T;
  // The description here is lame :-(
  Description describe(Description description) =>
      description.add('an instance of ${_name}');
}

/**
 * This can be used to match two kinds of objects:
 *
 *   * A [Function] that throws an exception when called. The function cannot
 *     take any arguments. If you want to test that a function expecting
 *     arguments throws, wrap it in another zero-argument function that calls
 *     the one you want to test. The function will be called once upon success,
 *     or twice upon failure (the second time to get the failure description).
 *
 *   * A [Future] that completes with an exception. Note that this creates an
 *     asynchronous expectation. The call to `expect()` that includes this will
 *     return immediately and execution will continue. Later, when the future
 *     completes, the actual expectation will run.
 */
final Matcher throws = const _Throws();

/**
 * This can be used to match two kinds of objects:
 *
 *   * A [Function] that throws an exception when called. The function cannot
 *     take any arguments. If you want to test that a function expecting
 *     arguments throws, wrap it in another zero-argument function that calls
 *     the one you want to test.
 *
 *   * A [Future] that completes with an exception. Note that this creates an
 *     asynchronous expectation. The call to `expect()` that includes this will
 *     return immediately and execution will continue. Later, when the future
 *     completes, the actual expectation will run.
 *
 * In both cases, when an exception is thrown, this will test that the exception
 * object matches [matcher]. If [matcher] is not an instance of [Matcher], it
 * will implicitly be treated as `equals(matcher)`.
 */
Matcher throwsA(matcher) => new _Throws(wrapMatcher(matcher));

/**
 * A matcher that matches a function call against no exception.
 * The function will be called once. Any exceptions will be silently swallowed.
 * The value passed to expect() should be a reference to the function.
 * Note that the function cannot take arguments; to handle this
 * a wrapper will have to be created.
 */
final Matcher returnsNormally = const _ReturnsNormally();

class _Throws extends BaseMatcher {
  final Matcher _matcher;

  const _Throws([Matcher matcher = null]) : this._matcher = matcher;

  bool matches(item) {
    if (item is Future) {
      // Queue up an asynchronous expectation that validates when the future
      // completes.
      item.onComplete(expectAsync1((future) {
        if (future.hasValue) {
          expect(false, reason:
              "Expected future to fail, but succeeded with '${future.value}'.");
        } else if (_matcher != null) {
          expect(future.exception, _matcher);
        }
      }));

      // It hasn't failed yet.
      return true;
    }

    try {
      item();
      return false;
    } catch (final e) {
      return _matcher == null || _matcher.matches(e);
    }
  }

  Description describe(Description description) {
    if (_matcher == null) {
      return description.add("throws an exception");
    } else {
      return description.add('throws an exception which matches ').
          addDescriptionOf(_matcher);
    }
  }

  Description describeMismatch(item, Description mismatchDescription) {
    if (_matcher == null) {
      return mismatchDescription.add(' no exception');
    } else {
      return mismatchDescription.
          add(' no exception or exception does not match ').
          addDescriptionOf(_matcher);
    }
  }
}

class _ReturnsNormally extends BaseMatcher {

  const _ReturnsNormally();

  bool matches(f) {
    try {
      f();
      return true;
    } catch (final e) {
      return false;
    }
  }

  Description describe(Description description) =>
      description.add("return normally");

  Description describeMismatch(item, Description mismatchDescription) {
      return mismatchDescription.add(' threw exception');
  }
}

/** A matcher for functions that throw BadNumberFormatException */
final Matcher throwsBadNumberFormatException =
    const _Throws(const isInstanceOf<BadNumberFormatException>());

/** A matcher for functions that throw an Exception */
final Matcher throwsException =
    const _Throws(const isInstanceOf<Exception>());

/** A matcher for functions that throw an IllegalArgumentException */
final Matcher throwsIllegalArgumentException =
    const _Throws(const isInstanceOf<IllegalArgumentException>());

/** A matcher for functions that throw an IllegalJSRegExpException */
final Matcher throwsIllegalJSRegExpException =
    const _Throws(const isInstanceOf<IllegalJSRegExpException>());

/** A matcher for functions that throw an IndexOutOfRangeException */
final Matcher throwsIndexOutOfRangeException =
    const _Throws(const isInstanceOf<IndexOutOfRangeException>());

/** A matcher for functions that throw a NoSuchMethodException */
final Matcher throwsNoSuchMethodException =
    const _Throws(const isInstanceOf<NoSuchMethodException>());

/** A matcher for functions that throw a NotImplementedException */
final Matcher throwsNotImplementedException =
    const _Throws(const isInstanceOf<NotImplementedException>());

/** A matcher for functions that throw a NullPointerException */
final Matcher throwsNullPointerException =
    const _Throws(const isInstanceOf<NullPointerException>());

/** A matcher for functions that throw an UnsupportedOperationException */
final Matcher throwsUnsupportedOperationException =
    const _Throws(const isInstanceOf<UnsupportedOperationException>());

/**
 * Returns a matcher that matches if an object has a length property
 * that matches [matcher].
 */
Matcher hasLength(matcher) =>
    new _HasLength(wrapMatcher(matcher));

class _HasLength extends BaseMatcher {
  final Matcher _matcher;
  const _HasLength([Matcher matcher = null]) : this._matcher = matcher;

  bool matches(item) {
    return _matcher.matches(item.length);
  }

  Description describe(Description description) =>
    description.add('an object with length of ').
        addDescriptionOf(_matcher);

  Description describeMismatch(item, Description mismatchDescription) {
    super.describeMismatch(item, mismatchDescription);
    try {
      // We want to generate a different description if there is no length
      // property. This is harmless code that will throw if no length property
      // but subtle enough that an optimizer shouldn't strip it out.
      if (item.length * item.length >= 0) {
        return mismatchDescription.add(' with length of ').
            addDescriptionOf(item.length);
      }
    } catch (var e) {
      return mismatchDescription.add(' has no length property');
    }
  }
}

/**
 * Returns a matcher that does a deep recursive match. This only works
 * with scalars, Maps and Iterables. To handle cyclic structures an
 * item [limit] can be provided; if after [limit] items have been
 * compared and the process is not complete this will be treated as
 * a mismatch. The default limit is 1000.
 */
Matcher recursivelyMatches(expected, [limit=1000]) =>
    new _DeepMatcher(expected, limit);

// A utility function for comparing iterators

String _compareIterables(expected, actual, matcher) {
  if (actual is !Iterable) {
    return 'is not Iterable';
  }
  var expectedIterator = expected.iterator();
  var actualIterator = actual.iterator();
  var position = 0;
  String reason = null;
  while (reason == null) {
    if (expectedIterator.hasNext()) {
      if (actualIterator.hasNext()) {
        reason = matcher(expectedIterator.next(),
                         actualIterator.next(),
                         'mismatch at position ${position}');
        ++position;
      } else {
        reason = 'shorter than expected';
      }
    } else if (actualIterator.hasNext()) {
      reason = 'longer than expected';
    } else {
      return null;
    }
  }
  return reason;
}

class _DeepMatcher extends BaseMatcher {
  final _expected;
  final int _limit;
  var count;

  _DeepMatcher(this._expected, [limit = 1000]) : this._limit = limit;

  String _recursiveMatch(expected, actual, String location) {
    String reason = null;
    if (++count >= _limit) {
      reason =  'item comparison limit exceeded';
    } else if (expected is Iterable) {
      reason = _compareIterables(expected, actual, _recursiveMatch);
    } else if (expected is Map) {
      if (actual is !Map) {
        reason = 'expected a map';
      } else if (expected.length != actual.length) {
        reason = 'different map lengths';
      } else {
        for (var key in expected.getKeys()) {
          if (!actual.containsKey(key)) {
            reason = 'missing map key ${key}';
            break;
          }
          reason = _recursiveMatch(expected[key], actual[key],
              'with key ${key} ${location}');
          if (reason != null) {
            break;
          }
        }
      }
    } else if (expected != actual) {
      reason = 'expected ${expected} but got ${actual}';
    }
    if (reason == null) {
      return null;
    } else {
      return '${reason} ${location}';
    }
  }

  String _match(expected, actual) {
    count = 0;
    return _recursiveMatch(expected, actual, '');
  }

  bool matches(item) => _match(_expected, item) == null;

  Description describe(Description description) =>
    description.add('recursively matches ').addDescriptionOf(_expected);

  Description describeMismatch(item, Description mismatchDescription) =>
    mismatchDescription.add(_match(_expected, item));
}

/**
 * Returns a matcher that matches if the match argument contains
 * the expected value. For [String]s this means substring matching;
 * for [Map]s is means the map has the key, and for [Collection]s it
 * means the collection has a matching element. In the case of collections,
 * [expected] can itself be a matcher.
 */
Matcher contains(expected) => new _Contains(expected);

class _Contains extends BaseMatcher {

  final _expected;

  const _Contains(this._expected);

  bool matches(item) {
    if (item is String) {
      return item.indexOf(_expected) >= 0;
    } else if (item is Collection) {
      if (_expected is Matcher) {
        return item.some((e) => _expected.matches(e));
      } else {
        return item.some((e) => e == _expected);
      }
    } else if (item is Map) {
      return item.containsKey(_expected);
    }
    return false;
  }

  Description describe(Description description) =>
      description.add('contains ').addDescriptionOf(_expected);
}

