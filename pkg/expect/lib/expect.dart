// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library contains an Expect class with static methods that can be used
 * for simple unit-tests.
 */
library expect;

/**
 * Expect is used for tests that do not want to make use of the
 * Dart unit test library - for example, the core language tests.
 * Third parties are discouraged from using this, and should use
 * the expect() function in the unit test library instead for
 * test assertions.
 */
class Expect {
  /**
   * Return a slice of a string.
   *
   * The slice will contain at least the substring from [start] to the lower of
   * [end] and `start + length`.
   * If the result is no more than `length - 10` characters long,
   * context may be added by extending the range of the slice, by decreasing
   * [start] and increasing [end], up to at most length characters.
   * If the start or end of the slice are not matching the start or end of
   * the string, ellipses are added before or after the slice.
   * Characters other than printable ASCII are escaped.
   */
  static String _truncateString(String string, int start, int end, int length) {
    if (end - start > length) {
      end = start + length;
    } else if (end - start < length) {
      int overflow = length - (end - start);
      if (overflow > 10) overflow = 10;
      // Add context.
      start = start - ((overflow + 1) ~/ 2);
      end = end + (overflow ~/ 2);
      if (start < 0) start = 0;
      if (end > string.length) end = string.length;
    }
    StringBuffer buf = new StringBuffer();
    if (start > 0) buf.write("...");
    _escapeSubstring(buf, string, 0, string.length);
    if (end < string.length) buf.write("...");
    return buf.toString();
  }

  /// Return the string with characters that are not printable ASCII characters
  /// escaped as either "\xXX" codes or "\uXXXX" codes.
  static String _escapeString(String string) {
    StringBuffer buf = new StringBuffer();
    _escapeSubstring(buf, string, 0, string.length);
    return buf.toString();
  }

  static _escapeSubstring(StringBuffer buf, String string, int start, int end) {
    const hexDigits = "0123456789ABCDEF";
    for (int i = start; i < end; i++) {
      int code = string.codeUnitAt(i);
      if (0x20 <= code && code < 0x7F) {
        if (code == 0x5C) {
          buf.write(r"\\");
        } else {
          buf.writeCharCode(code);
        }
      } else if (code < 0x100) {
        buf.write(r"\x");
        buf.write(hexDigits[code >> 4]);
        buf.write(hexDigits[code & 15]);
      } else {
        buf.write(r"\u{");
        buf.write(code.toRadixString(16).toUpperCase());
        buf.write(r"}");
      }
    }
  }

  /**
   * Find the difference between two strings.
   *
   * This finds the first point where two strings differ, and returns
   * a text describing the difference.
   *
   * For small strings (length less than 20) nothing is done, and null is
   * returned. Small strings can be compared visually, but for longer strings
   * only a slice containing the first difference will be shown.
   */
  static String _stringDifference(String expected, String actual) {
    if (expected.length < 20 && actual.length < 20) return null;
    for (int i = 0; i < expected.length && i < actual.length; i++) {
      if (expected.codeUnitAt(i) != actual.codeUnitAt(i)) {
        int start = i;
        i++;
        while (i < expected.length && i < actual.length) {
          if (expected.codeUnitAt(i) == actual.codeUnitAt(i)) break;
          i++;
        }
        int end = i;
        var truncExpected = _truncateString(expected, start, end, 20);
        var truncActual = _truncateString(actual, start, end, 20);
        return "at index $start: Expected <$truncExpected>, "
            "Found: <$truncActual>";
      }
    }
    return null;
  }

  /**
   * Checks whether the expected and actual values are equal (using `==`).
   */
  static void equals(var expected, var actual, [String reason = null]) {
    if (expected == actual) return;
    String msg = _getMessage(reason);
    if (expected is String && actual is String) {
      String stringDifference = _stringDifference(expected, actual);
      if (stringDifference != null) {
        _fail("Expect.equals($stringDifference$msg) fails.");
      }
      _fail("Expect.equals(expected: <${_escapeString(expected)}>"
          ", actual: <${_escapeString(actual)}>$msg) fails.");
    }
    _fail("Expect.equals(expected: <$expected>, actual: <$actual>$msg) fails.");
  }

  /**
   * Checks whether the actual value is a bool and its value is true.
   */
  static void isTrue(var actual, [String reason = null]) {
    if (_identical(actual, true)) return;
    String msg = _getMessage(reason);
    _fail("Expect.isTrue($actual$msg) fails.");
  }

  /**
   * Checks whether the actual value is a bool and its value is false.
   */
  static void isFalse(var actual, [String reason = null]) {
    if (_identical(actual, false)) return;
    String msg = _getMessage(reason);
    _fail("Expect.isFalse($actual$msg) fails.");
  }

  /**
   * Checks whether [actual] is null.
   */
  static void isNull(actual, [String reason = null]) {
    if (null == actual) return;
    String msg = _getMessage(reason);
    _fail("Expect.isNull(actual: <$actual>$msg) fails.");
  }

  /**
   * Checks whether [actual] is not null.
   */
  static void isNotNull(actual, [String reason = null]) {
    if (null != actual) return;
    String msg = _getMessage(reason);
    _fail("Expect.isNotNull(actual: <$actual>$msg) fails.");
  }

  /**
   * Checks whether the expected and actual values are identical
   * (using `identical`).
   */
  static void identical(var expected, var actual, [String reason = null]) {
    if (_identical(expected, actual)) return;
    String msg = _getMessage(reason);
    if (expected is String && actual is String) {
      String note =
          (expected == actual) ? ' Strings equal but not identical.' : '';
      _fail("Expect.identical(expected: <${_escapeString(expected)}>"
          ", actual: <${_escapeString(actual)}>$msg) "
          "fails.$note");
    }
    _fail("Expect.identical(expected: <$expected>, actual: <$actual>$msg) "
        "fails.");
  }

  // Unconditional failure.
  static void fail(String msg) {
    _fail("Expect.fail('$msg')");
  }

  /**
   * Failure if the difference between expected and actual is greater than the
   * given tolerance. If no tolerance is given, tolerance is assumed to be the
   * value 4 significant digits smaller than the value given for expected.
   */
  static void approxEquals(num expected, num actual,
      [num tolerance = null, String reason = null]) {
    if (tolerance == null) {
      tolerance = (expected / 1e4).abs();
    }
    // Note: use !( <= ) rather than > so we fail on NaNs
    if ((expected - actual).abs() <= tolerance) return;

    String msg = _getMessage(reason);
    _fail('Expect.approxEquals(expected:<$expected>, actual:<$actual>, '
        'tolerance:<$tolerance>$msg) fails');
  }

  static void notEquals(unexpected, actual, [String reason = null]) {
    if (unexpected != actual) return;
    String msg = _getMessage(reason);
    _fail("Expect.notEquals(unexpected: <$unexpected>, actual:<$actual>$msg) "
        "fails.");
  }

  /**
   * Checks that all elements in [expected] and [actual] are equal `==`.
   * This is different than the typical check for identity equality `identical`
   * used by the standard list implementation.  It should also produce nicer
   * error messages than just calling `Expect.equals(expected, actual)`.
   */
  static void listEquals(List expected, List actual, [String reason = null]) {
    String msg = _getMessage(reason);
    int n = (expected.length < actual.length) ? expected.length : actual.length;
    for (int i = 0; i < n; i++) {
      if (expected[i] != actual[i]) {
        _fail('Expect.listEquals(at index $i, '
            'expected: <${expected[i]}>, actual: <${actual[i]}>$msg) fails');
      }
    }
    // We check on length at the end in order to provide better error
    // messages when an unexpected item is inserted in a list.
    if (expected.length != actual.length) {
      _fail('Expect.listEquals(list length, '
          'expected: <${expected.length}>, actual: <${actual.length}>$msg) '
          'fails: Next element <'
          '${expected.length > n ? expected[n] : actual[n]}>');
    }
  }

  /**
   * Checks that all [expected] and [actual] have the same set of keys (using
   * the semantics of [Map.containsKey] to determine what "same" means. For
   * each key, checks that the values in both maps are equal using `==`.
   */
  static void mapEquals(Map expected, Map actual, [String reason = null]) {
    String msg = _getMessage(reason);

    // Make sure all of the values are present in both and match.
    for (final key in expected.keys) {
      if (!actual.containsKey(key)) {
        _fail('Expect.mapEquals(missing expected key: <$key>$msg) fails');
      }

      Expect.equals(expected[key], actual[key]);
    }

    // Make sure the actual map doesn't have any extra keys.
    for (final key in actual.keys) {
      if (!expected.containsKey(key)) {
        _fail('Expect.mapEquals(unexpected key: <$key>$msg) fails');
      }
    }
  }

  /**
   * Specialized equality test for strings. When the strings don't match,
   * this method shows where the mismatch starts and ends.
   */
  static void stringEquals(String expected, String actual,
      [String reason = null]) {
    if (expected == actual) return;

    String msg = _getMessage(reason);
    String defaultMessage =
        'Expect.stringEquals(expected: <$expected>", <$actual>$msg) fails';

    if ((expected == null) || (actual == null)) {
      _fail('$defaultMessage');
    }

    // Scan from the left until we find the mismatch.
    int left = 0;
    int right = 0;
    int eLen = expected.length;
    int aLen = actual.length;

    while (true) {
      if (left == eLen || left == aLen || expected[left] != actual[left]) {
        break;
      }
      left++;
    }

    // Scan from the right until we find the mismatch.
    int eRem = eLen - left; // Remaining length ignoring left match.
    int aRem = aLen - left;
    while (true) {
      if (right == eRem ||
          right == aRem ||
          expected[eLen - right - 1] != actual[aLen - right - 1]) {
        break;
      }
      right++;
    }

    // First difference is at index `left`, last at `length - right - 1`
    // Make useful difference message.
    // Example:
    // Diff (1209..1209/1246):
    // ...,{"name":"[  ]FallThroug...
    // ...,{"name":"[ IndexError","kind":"class"},{"name":" ]FallThroug...
    // (colors would be great!)

    // Make snippets of up to ten characters before and after differences.

    String leftSnippet = expected.substring(left < 10 ? 0 : left - 10, left);
    int rightSnippetLength = right < 10 ? right : 10;
    String rightSnippet =
        expected.substring(eLen - right, eLen - right + rightSnippetLength);

    // Make snippets of the differences.
    String eSnippet = expected.substring(left, eLen - right);
    String aSnippet = actual.substring(left, aLen - right);

    // If snippets are long, elide the middle.
    if (eSnippet.length > 43) {
      eSnippet = eSnippet.substring(0, 20) +
          "..." +
          eSnippet.substring(eSnippet.length - 20);
    }
    if (aSnippet.length > 43) {
      aSnippet = aSnippet.substring(0, 20) +
          "..." +
          aSnippet.substring(aSnippet.length - 20);
    }
    // Add "..." before and after, unless the snippets reach the end.
    String leftLead = "...";
    String rightTail = "...";
    if (left <= 10) leftLead = "";
    if (right <= 10) rightTail = "";

    String diff = '\nDiff ($left..${eLen - right}/${aLen - right}):\n'
        '$leftLead$leftSnippet[ $eSnippet ]$rightSnippet$rightTail\n'
        '$leftLead$leftSnippet[ $aSnippet ]$rightSnippet$rightTail';
    _fail("$defaultMessage$diff");
  }

  /**
   * Checks that every element of [expected] is also in [actual], and that
   * every element of [actual] is also in [expected].
   */
  static void setEquals(Iterable expected, Iterable actual,
      [String reason = null]) {
    final missingSet = new Set.from(expected);
    missingSet.removeAll(actual);
    final extraSet = new Set.from(actual);
    extraSet.removeAll(expected);

    if (extraSet.isEmpty && missingSet.isEmpty) return;
    String msg = _getMessage(reason);

    StringBuffer sb = new StringBuffer("Expect.setEquals($msg) fails");
    // Report any missing items.
    if (!missingSet.isEmpty) {
      sb.write('\nExpected collection does not contain: ');
    }

    for (final val in missingSet) {
      sb.write('$val ');
    }

    // Report any extra items.
    if (!extraSet.isEmpty) {
      sb.write('\nExpected collection should not contain: ');
    }

    for (final val in extraSet) {
      sb.write('$val ');
    }
    _fail(sb.toString());
  }

  /**
   * Checks that [expected] is equivalent to [actual].
   *
   * If the objects are iterables or maps, recurses into them.
   */
  static void deepEquals(Object expected, Object actual) {
    // Early exit check for equality.
    if (expected == actual) return;

    if (expected is String && actual is String) {
      stringEquals(expected, actual);
    } else if (expected is Iterable && actual is Iterable) {
      var expectedLength = expected.length;
      var actualLength = actual.length;

      var length =
          expectedLength < actualLength ? expectedLength : actualLength;
      for (var i = 0; i < length; i++) {
        deepEquals(expected.elementAt(i), actual.elementAt(i));
      }

      // We check on length at the end in order to provide better error
      // messages when an unexpected item is inserted in a list.
      if (expectedLength != actualLength) {
        var nextElement =
            (expectedLength > length ? expected : actual).elementAt(length);
        _fail('Expect.deepEquals(list length, '
            'expected: <$expectedLength>, actual: <$actualLength>) '
            'fails: Next element <$nextElement>');
      }
    } else if (expected is Map && actual is Map) {
      // Make sure all of the values are present in both and match.
      for (final key in expected.keys) {
        if (!actual.containsKey(key)) {
          _fail('Expect.deepEquals(missing expected key: <$key>) fails');
        }

        Expect.deepEquals(expected[key], actual[key]);
      }

      // Make sure the actual map doesn't have any extra keys.
      for (final key in actual.keys) {
        if (!expected.containsKey(key)) {
          _fail('Expect.deepEquals(unexpected key: <$key>) fails');
        }
      }
    } else {
      _fail("Expect.deepEquals(expected: <$expected>, actual: <$actual>) "
          "fails.");
    }
  }

  /**
   * Calls the function [f] and verifies that it throws an exception.
   * The optional [check] function can provide additional validation
   * that the correct exception is being thrown.  For example, to check
   * the type of the exception you could write this:
   *
   *     Expect.throws(myThrowingFunction, (e) => e is MyException);
   */
  static void throws(void f(),
      [_CheckExceptionFn check = null, String reason = null]) {
    String msg = reason == null ? "" : "($reason)";
    if (f is! _Nullary) {
      // Only throws from executing the function body should count as throwing.
      // The failure to even call `f` should throw outside the try/catch.
      _fail("Expect.throws$msg: Function f not callable with zero arguments");
    }
    try {
      f();
    } catch (e, s) {
      if (check != null) {
        if (!check(e)) {
          _fail("Expect.throws$msg: Unexpected '$e'\n$s");
        }
      }
      return;
    }
    _fail('Expect.throws$msg fails: Did not throw');
  }

  static String _getMessage(String reason) =>
      (reason == null) ? "" : ", '$reason'";

  static void _fail(String message) {
    throw new ExpectException(message);
  }
}

bool _identical(a, b) => identical(a, b);

typedef bool _CheckExceptionFn(exception);
typedef _Nullary(); // Expect.throws argument must be this type.

class ExpectException implements Exception {
  ExpectException(this.message);
  String toString() => message;
  String message;
}

/// Annotation class for testing of dart2js. Use this as metadata on method
/// declarations to disable inlining of the annotated method.
class NoInline {
  const NoInline();
}

/// Annotation class for testing of dart2js. Use this as metadata on method
/// declarations to make the type inferrer trust the parameter and return types,
/// effectively asserting the runtime values will (at least) be subtypes of the
/// annotated types.
///
/// While the actually inferred type is guaranteed to be a subtype of the
/// annotation, it often is more precise. In particular, if a method is only
/// called with `null`, the inferrer will still infer null. To ensure that
/// the annotated type is also the inferred type, additionally use
/// [AssumeDynamic].
class TrustTypeAnnotations {
  const TrustTypeAnnotations();
}

/// Annotation class for testing of dart2js. Use this as metadata on method
/// declarations to disable closed world assumptions on parameters, effectively
/// assuming that the runtime arguments could be any value. Note that the
/// constraints due to [TrustTypeAnnotations] still apply.
class AssumeDynamic {
  const AssumeDynamic();
}

/// Is true iff type assertions are enabled.
final bool typeAssertionsEnabled = (() {
  try {
    dynamic i = 42;
    String s = i;
  } on TypeError catch (e) {
    return true;
  }
  return false;
})();

/// Is true iff `assert` statements are enabled.
final bool assertStatementsEnabled = (() {
  try {
    assert(false);
  } on AssertionError catch (e) {
    return true;
  }
  return false;
})();

/// Is true iff checked mode is enabled.
final bool checkedModeEnabled =
    typeAssertionsEnabled && assertStatementsEnabled;
