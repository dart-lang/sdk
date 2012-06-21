// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is the main assertion function. It asserts that [actual]
 * matches the [matcher]. [reason] is optional and is typically
 * not supplied, as a reason can be generated from the matcher.
 * If [reason] is included it is appended to the reason generated
 * by the matcher.
 *
 * If the assertion fails, then the default behavior is to throw an
 * [ExpectException], but this behavior can be changed by calling
 * [configureExpectHandler] and providing an alternative handler that
 * implements the [IFailureHandler] interface.
 *
 * [expect] allows an alternative call format, providing a Boolean
 * predicate as the first argument and an optional reason as a named
 * second argument. This supports brevity at the expense of detailed
 * error messages. For example, these are equivalent, but the first
 * form will give a detailed error message, while the second form will
 * just give a generic assertion failed message:
 *
 *     expect(foo, isLessThanOrEqual(bar));
 *     expect(foo <= bar);
 *
 * A better way of doing the second form is:
 *
 *     expect(foo <= bar, reason: "foo not less than or equal to bar");
 *
 * expect() is a 3rd generation assertion mechanism, drawing
 * inspiration from [Hamcrest] and Ladislav Thon's [dart-matchers]
 * library.
 *
 * See [Hamcrest] http://en.wikipedia.org/wiki/Hamcrest
 *     [Hamcrest] http://http://code.google.com/p/hamcrest/
 *     [dart-matchers] https://github.com/Ladicek/dart-matchers
 */
void expect(actual, [matcher = null, String reason = null]) {
  if (matcher == null) {
    // Treat this as an assert(predicate, [reason]).
    if (!actual) {
      if (reason == null) {
        reason = 'Assertion failed';
      }
      // Make sure we have a failure handler configured.
      configureExpectHandler(_assertFailureHandler);
      _assertFailureHandler.fail(reason);
    }
  } else {
    // Treat this as an expect(value, [matcher], [reason]).
    matcher = wrapMatcher(matcher);
    var doesMatch;
    try {
      doesMatch = matcher.matches(actual);
    } catch (var e, var trace) {
      doesMatch = false;
      if (reason == null) {
        reason = '${(e is String) ? e : e.toString()} at $trace';
      }
    }
    if (!doesMatch) {
      // Make sure we have a failure handler configured.
      configureExpectHandler(_assertFailureHandler);
      _assertFailureHandler.failMatch(actual, matcher, reason);
    }
  }
}

/**
 * Takes an argument and returns an equivalent matcher.
 * If the argument is already a matcher this does nothing, else it
 * generates an equals matcher for the argument.
 */
Matcher wrapMatcher(x) => ((x is Matcher) ? x : equals(x));

// The handler for failed asserts.
FailureHandler _assertFailureHandler = null;

// The default failure handler that throws ExpectExceptions.
class DefaultFailureHandler implements FailureHandler {
  DefaultFailureHandler() {
    if (_assertErrorFormatter == null) {
      _assertErrorFormatter = _defaultErrorFormatter;
    }
  }
  void fail(String reason) {
    throw new ExpectException(reason);
  }
  void failMatch(actual, Matcher matcher, String reason) {
    fail(_assertErrorFormatter(actual, matcher, reason));
  }
}

/**
 * Changes or resets to the default the failure handler for expect()
 * [handler] is a reference to the new handler; if this is omitted
 * or null then the failure handler is reset to the default, which
 * throws [ExpectExceptions] on [expect] assertion failures.
 */
void configureExpectHandler([FailureHandler handler = null]) {
  if (handler == null) {
    handler = new DefaultFailureHandler();
  }
  _assertFailureHandler = handler;
}

// The error message formatter for failed asserts.
ErrorFormatter _assertErrorFormatter = null;

// The default error formatter implementation.
String _defaultErrorFormatter(actual, Matcher matcher, String reason) {
  var description = new StringDescription();
  description.add('Expected: ').addDescriptionOf(matcher).
      add('\n     but: ');
  matcher.describeMismatch(actual, description);
  if (reason != null) {
    description.add('\n').add(reason).add('\n');
  }
  return description.toString();
}

/**
 * Changes or resets to default the failure message formatter for expect().
 * [formatter] is a reference to the new formatter; if this is omitted or
 * null then the failure formatter is reset to the default. The new
 * formatter is returned; this allows custom expect handlers to easily
 * get a reference to the default formatter.
 */
ErrorFormatter configureExpectFormatter([ErrorFormatter formatter = null]) {
  if (formatter == null) {
    formatter = _defaultErrorFormatter;
  }
  return _assertErrorFormatter = formatter;
}

