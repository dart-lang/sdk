// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of matcher;

/**
 * Returns a matcher that matches empty strings, maps or collections.
 */
const Matcher isEmpty = const _Empty();

class _Empty extends BaseMatcher {
  const _Empty();
  bool matches(item, MatchState matchState) {
    if (item is Map || item is Collection) {
      return item.isEmpty;
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
const Matcher isNull = const _IsNull();

/** A matcher that matches any non-null value. */
const Matcher isNotNull = const _IsNotNull();

class _IsNull extends BaseMatcher {
  const _IsNull();
  bool matches(item, MatchState matchState) => item == null;
  Description describe(Description description) =>
      description.add('null');
}

class _IsNotNull extends BaseMatcher {
  const _IsNotNull();
  bool matches(item, MatchState matchState) => item != null;
  Description describe(Description description) =>
      description.add('not null');
}

/** A matcher that matches the Boolean value true. */
const Matcher isTrue = const _IsTrue();

/** A matcher that matches anything except the Boolean value true. */
const Matcher isFalse = const _IsFalse();

class _IsTrue extends BaseMatcher {
  const _IsTrue();
  bool matches(item, MatchState matchState) => item == true;
  Description describe(Description description) =>
      description.add('true');
}

class _IsFalse extends BaseMatcher {
  const _IsFalse();
  bool matches(item, MatchState matchState) => item == false;
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
  bool matches(item, MatchState matchState) => identical(item, _expected);
  // If all types were hashable we could show a hash here.
  Description describe(Description description) =>
      description.add('same instance as ').addDescriptionOf(_expected);
}

/**
 * Returns a matcher that does a deep recursive match. This only works
 * with scalars, Maps and Iterables. To handle cyclic structures a
 * recursion depth [limit] can be provided. The default limit is 100.
 */
Matcher equals(expected, [limit=100]) =>
    new _DeepMatcher(expected, limit);

class _DeepMatcher extends BaseMatcher {
  final _expected;
  final int _limit;
  var count;

  _DeepMatcher(this._expected, [limit = 1000]) : this._limit = limit;

  String _compareIterables(expected, actual, matcher, depth) {
    if (actual is !Iterable) {
      return 'is not Iterable';
    }
    var expectedIterator = expected.iterator();
    var actualIterator = actual.iterator();
    var position = 0;
    String reason = null;
    while (reason == null) {
      if (expectedIterator.hasNext) {
        if (actualIterator.hasNext) {
          Description r = matcher(expectedIterator.next(),
                           actualIterator.next(),
                           'mismatch at position ${position}',
                           depth);
          if (r != null) reason = r.toString();
          ++position;
        } else {
          reason = 'shorter than expected';
        }
      } else if (actualIterator.hasNext) {
        reason = 'longer than expected';
      } else {
        return null;
      }
    }
    return reason;
  }

  Description _recursiveMatch(expected, actual, String location, int depth) {
    Description reason = null;
    // If _limit is 1 we can only recurse one level into object.
    bool canRecurse = depth == 0 || _limit > 1;
    if (expected == actual) {
      // Do nothing.
    } else if (depth > _limit) {
      reason = new StringDescription('recursion depth limit exceeded');
    } else {
      if (expected is Iterable && canRecurse) {
        String r = _compareIterables(expected, actual,
          _recursiveMatch, depth+1);
        if (r != null) reason = new StringDescription(r);
      } else if (expected is Map && canRecurse) {
        if (actual is !Map) {
          reason = new StringDescription('expected a map');
        } else if (expected.length != actual.length) {
          reason = new StringDescription('different map lengths');
        } else {
          for (var key in expected.keys) {
            if (!actual.containsKey(key)) {
              reason = new StringDescription('missing map key ');
              reason.addDescriptionOf(key);
              break;
            }
            reason = _recursiveMatch(expected[key], actual[key],
                'with key <${key}> ${location}', depth+1);
            if (reason != null) {
              break;
            }
          }
        }
      } else {
        // If we have recursed, show the expected value too; if not,
        // expect() will show it for us.
        reason = new StringDescription();
        if (depth > 1) {
          reason.add('expected ').addDescriptionOf(expected).add(' but was ').
              addDescriptionOf(actual);
        } else {
          reason.add('was ').addDescriptionOf(actual);
        }
      }
    }
    if (reason != null && location.length > 0) {
      reason.add(' ').add(location);
    }
    return reason;
  }

  String _match(expected, actual) {
    Description reason = _recursiveMatch(expected, actual, '', 0);
    return reason == null ? null : reason.toString();
  }

  // TODO(gram) - see if we can make use of matchState here to avoid
  // recursing again in describeMismatch.
  bool matches(item, MatchState matchState) => _match(_expected, item) == null;

  Description describe(Description description) =>
    description.addDescriptionOf(_expected);

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) =>
    mismatchDescription.add(_match(_expected, item));
}

/** A matcher that matches any value. */
const Matcher anything = const _IsAnything();

class _IsAnything extends BaseMatcher {
  const _IsAnything();
  bool matches(item, MatchState matchState) => true;
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
 *
 * Note that this does not currently work in dart2js; it will
 * match any type, and isNot(new isInstanceof<T>()) will always
 * fail. This is because dart2js currently ignores template type
 * parameters.
 */
class isInstanceOf<T> extends BaseMatcher {
  final String _name;
  const isInstanceOf([name = 'specified type']) : this._name = name;
  bool matches(obj, MatchState matchState) => obj is T;
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
 *     the one you want to test.
 *
 *   * A [Future] that completes with an exception. Note that this creates an
 *     asynchronous expectation. The call to `expect()` that includes this will
 *     return immediately and execution will continue. Later, when the future
 *     completes, the actual expectation will run.
 */
const Matcher throws = const Throws();

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
Matcher throwsA(matcher) => new Throws(wrapMatcher(matcher));

/**
 * A matcher that matches a function call against no exception.
 * The function will be called once. Any exceptions will be silently swallowed.
 * The value passed to expect() should be a reference to the function.
 * Note that the function cannot take arguments; to handle this
 * a wrapper will have to be created.
 */
const Matcher returnsNormally = const _ReturnsNormally();

class Throws extends BaseMatcher {
  final Matcher _matcher;

  const Throws([Matcher matcher]) :
    this._matcher = matcher;

  bool matches(item, MatchState matchState) {
    if (item is Future) {
      // Queue up an asynchronous expectation that validates when the future
      // completes.
      item.onComplete(wrapAsync((future) {
        if (future.hasValue) {
          expect(false, isTrue, reason:
              "Expected future to fail, but succeeded with '${future.value}'.");
        } else if (_matcher != null) {
          var reason;
          if (future.stackTrace != null) {
            var stackTrace = future.stackTrace.toString();
            stackTrace = "  ${stackTrace.replaceAll("\n", "\n  ")}";
            reason = "Actual exception trace:\n$stackTrace";
          }
          expect(future.exception, _matcher, reason: reason);
        }
      }));

      // It hasn't failed yet.
      return true;
    }

    try {
      item();
      return false;
    } catch (e, s) {
      if (_matcher == null ||_matcher.matches(e, matchState)) {
        return true;
      } else {
        matchState.state = {
            'exception' :e,
            'stack': s
        };
        return false;
      }
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

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState,
                               bool verbose) {
    if (_matcher == null ||  matchState.state == null) {
      return mismatchDescription.add(' no exception');
    } else {
      mismatchDescription.
          add(' exception ').addDescriptionOf(matchState.state['exception']);
      if (verbose) {
          mismatchDescription.add(' at ').
          add(matchState.state['stack'].toString());
      }
       mismatchDescription.add(' does not match ').addDescriptionOf(_matcher);
       return mismatchDescription;
    }
  }
}

class _ReturnsNormally extends BaseMatcher {
  const _ReturnsNormally();

  bool matches(f, MatchState matchState) {
    try {
      f();
      return true;
    } catch (e, s) {
      matchState.state = {
          'exception' : e,
          'stack': s
      };
      return false;
    }
  }

  Description describe(Description description) =>
      description.add("return normally");

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState,
                               bool verbose) {
      mismatchDescription.add(' threw ').
          addDescriptionOf(matchState.state['exception']);
      if (verbose) {
        mismatchDescription.add(' at ').
        add(matchState.state['stack'].toString());
      }
      return mismatchDescription;
  }
}

/*
 * Matchers for different exception types. Ideally we should just be able to
 * use something like:
 *
 * final Matcher throwsException =
 *     const _Throws(const isInstanceOf<Exception>());
 *
 * Unfortunately instanceOf is not working with dart2js.
 *
 * Alternatively, if static functions could be used in const expressions,
 * we could use:
 *
 * bool _isException(x) => x is Exception;
 * final Matcher isException = const _Predicate(_isException, "Exception");
 * final Matcher throwsException = const _Throws(isException);
 *
 * But currently using static functions in const expressions is not supported.
 * For now the only solution for all platforms seems to be separate classes
 * for each exception type.
 */

abstract class TypeMatcher extends BaseMatcher {
  final String _name;
  const TypeMatcher(this._name);
  Description describe(Description description) =>
      description.add(_name);
}

/** A matcher for FormatExceptions. */
const isFormatException = const _FormatException();

/** A matcher for functions that throw FormatException. */
const Matcher throwsFormatException =
    const Throws(isFormatException);

class _FormatException extends TypeMatcher {
  const _FormatException() : super("FormatException");
  bool matches(item, MatchState matchState) => item is FormatException;
}

/** A matcher for Exceptions. */
const isException = const _Exception();

/** A matcher for functions that throw Exception. */
const Matcher throwsException = const Throws(isException);

class _Exception extends TypeMatcher {
  const _Exception() : super("Exception");
  bool matches(item, MatchState matchState) => item is Exception;
}

/** A matcher for ArgumentErrors. */
const isArgumentError = const _ArgumentError();

/** A matcher for functions that throw ArgumentError. */
const Matcher throwsArgumentError =
    const Throws(isArgumentError);

class _ArgumentError extends TypeMatcher {
  const _ArgumentError() : super("ArgumentError");
  bool matches(item, MatchState matchState) => item is ArgumentError;
}

/** A matcher for IllegalJSRegExpExceptions. */
const isIllegalJSRegExpException = const _IllegalJSRegExpException();

/** A matcher for functions that throw IllegalJSRegExpException. */
const Matcher throwsIllegalJSRegExpException =
    const Throws(isIllegalJSRegExpException);

class _IllegalJSRegExpException extends TypeMatcher {
  const _IllegalJSRegExpException() : super("IllegalJSRegExpException");
  bool matches(item, MatchState matchState) => item is IllegalJSRegExpException;
}

/** A matcher for RangeErrors. */
const isRangeError = const _RangeError();

/** A matcher for functions that throw RangeError. */
const Matcher throwsRangeError =
    const Throws(isRangeError);

class _RangeError extends TypeMatcher {
  const _RangeError() : super("RangeError");
  bool matches(item, MatchState matchState) => item is RangeError;
}

/** A matcher for NoSuchMethodErrors. */
const isNoSuchMethodError = const _NoSuchMethodError();

/** A matcher for functions that throw NoSuchMethodError. */
const Matcher throwsNoSuchMethodError =
    const Throws(isNoSuchMethodError);

class _NoSuchMethodError extends TypeMatcher {
  const _NoSuchMethodError() : super("NoSuchMethodError");
  bool matches(item, MatchState matchState) => item is NoSuchMethodError;
}

/** A matcher for UnimplementedErrors. */
const isUnimplementedError = const _UnimplementedError();

/** A matcher for functions that throw Exception. */
const Matcher throwsUnimplementedError =
    const Throws(isUnimplementedError);

class _UnimplementedError extends TypeMatcher {
  const _UnimplementedError() : super("UnimplementedError");
  bool matches(item, MatchState matchState) => item is UnimplementedError;
}

/** A matcher for UnsupportedError. */
const isUnsupportedError = const _UnsupportedError();

/** A matcher for functions that throw UnsupportedError. */
const Matcher throwsUnsupportedError = const Throws(isUnsupportedError);

class _UnsupportedError extends TypeMatcher {
  const _UnsupportedError() :
      super("UnsupportedError");
  bool matches(item, MatchState matchState) => item is UnsupportedError;
}

/** A matcher for Map types. */
const isMap = const _IsMap();

class _IsMap extends TypeMatcher {
  const _IsMap() : super("Map");
  bool matches(item, MatchState matchState) => item is Map;
}

/** A matcher for List types. */
const isList = const _IsList();

class _IsList extends TypeMatcher {
  const _IsList() : super("List");
  bool matches(item, MatchState matchState) => item is List;
}

/**
 * Returns a matcher that matches if an object has a length property
 * that matches [matcher].
 */
Matcher hasLength(matcher) =>
    new _HasLength(wrapMatcher(matcher));

class _HasLength extends BaseMatcher {
  final Matcher _matcher;
  const _HasLength([Matcher matcher = null]) : this._matcher = matcher;

  bool matches(item, MatchState matchState) {
    return _matcher.matches(item.length, matchState);
  }

  Description describe(Description description) =>
    description.add('an object with length of ').
        addDescriptionOf(_matcher);

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) {
    super.describeMismatch(item, mismatchDescription, matchState, verbose);
    try {
      // We want to generate a different description if there is no length
      // property. This is harmless code that will throw if no length property
      // but subtle enough that an optimizer shouldn't strip it out.
      if (item.length * item.length >= 0) {
        return mismatchDescription.add(' with length of ').
            addDescriptionOf(item.length);
      }
    } catch (e) {
      return mismatchDescription.add(' has no length property');
    }
  }
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

  bool matches(item, MatchState matchState) {
    if (item is String) {
      return item.indexOf(_expected) >= 0;
    } else if (item is Collection) {
      if (_expected is Matcher) {
        return item.some((e) => _expected.matches(e, matchState));
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

/**
 * Returns a matcher that matches if the match argument is in
 * the expected value. This is the converse of [contains].
 */
Matcher isIn(expected) => new _In(expected);

class _In extends BaseMatcher {

  final _expected;

  const _In(this._expected);

  bool matches(item, MatchState matchState) {
    if (_expected is String) {
      return _expected.indexOf(item) >= 0;
    } else if (_expected is Collection) {
      return _expected.some((e) => e == item);
    } else if (_expected is Map) {
      return _expected.containsKey(item);
    }
    return false;
  }

  Description describe(Description description) =>
      description.add('is in ').addDescriptionOf(_expected);
}

/**
 * Returns a matcher that uses an arbitrary function that returns
 * true or false for the actual value.
 */
Matcher predicate(f, [description ='satisfies function']) =>
    new _Predicate(f, description);

class _Predicate extends BaseMatcher {

  final _matcher;
  final String _description;

  const _Predicate(this._matcher, this._description);

  bool matches(item, MatchState matchState) => _matcher(item);

  Description describe(Description description) =>
      description.add(_description);
}

/**
 * A useful utility class for implementing other matchers through inheritance.
 * Derived classes should call the base constructor with a feature name and
 * description, and an instance matcher, and should implement the
 * [featureValueOf] abstract method.
 *
 * The feature description will typically describe the item and the feature,
 * while the feature name will just name the feature. For example, we may
 * have a Widget class where each Widget has a price; we could make a
 * FeatureMatcher that can make assertions about prices with:
 *
 *     class HasPrice extends FeatureMatcher {
 *       const HasPrice(matcher) :
 *           super("Widget with price that is", "price", matcher);
 *       featureValueOf(actual) => actual.price;
 *     }
 *
 * and then use this for example like:
 *
 *      expect(inventoryItem, new HasPrice(greaterThan(0)));
 */
class CustomMatcher extends BaseMatcher {
  final String _featureDescription;
  final String _featureName;
  final Matcher _matcher;

  const CustomMatcher(this._featureDescription, this._featureName,
      this._matcher);

  /** Override this to extract the interesting feature.*/
  featureValueOf(actual) => actual;

  bool matches(item, MatchState matchState) {
    var f = featureValueOf(item);
    if (_matcher.matches(f, matchState)) return true;
    matchState.state = { 'innerState': matchState.state, 'feature': f };
    return false;
  }

  Description describe(Description description) =>
      description.add(_featureDescription).add(' ').addDescriptionOf(_matcher);

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) {
    mismatchDescription.add(_featureName).add(' ');
    _matcher.describeMismatch(matchState.state['feature'], mismatchDescription,
        matchState.state['innerState'], verbose);
    return mismatchDescription;
  }
}
