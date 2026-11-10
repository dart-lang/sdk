// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Originally from package:expect in the Dart SDK.

/// This library contains an Expect class with static methods that can be used
/// for simple unit-tests.
library expect;

/// Expect is used for tests that do not want to make use of the
/// Dart unit test library - for example, the core language tests.
/// Third parties are discouraged from using this, and should use
/// the expect() function in the unit test library instead for
/// test assertions.
class Expect {
  /// Return a slice of a string.
  ///
  /// The slice will contain at least the substring from [start] to the lower of
  /// [end] and `start + length`.
  /// If the result is no more than `length - 10` characters long,
  /// context may be added by extending the range of the slice, by decreasing
  /// [start] and increasing [end], up to at most length characters.
  /// If the start or end of the slice are not matching the start or end of
  /// the string, ellipses are added before or after the slice.
  /// Characters other than printable ASCII are escaped.
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
    final StringBuffer buf = StringBuffer();
    if (start > 0) buf.write('...');
    _escapeSubstring(buf, string, 0, string.length);
    if (end < string.length) buf.write('...');
    return buf.toString();
  }

  /// Return the string with characters that are not printable ASCII characters
  /// escaped as either "\xXX" codes or "\uXXXX" codes.
  static String _escapeString(String string) {
    final StringBuffer buf = StringBuffer();
    _escapeSubstring(buf, string, 0, string.length);
    return buf.toString();
  }

  static void _escapeSubstring(
    StringBuffer buf,
    String string,
    int start,
    int end,
  ) {
    const hexDigits = '0123456789ABCDEF';
    for (int i = start; i < end; i++) {
      final int code = string.codeUnitAt(i);
      if (0x20 <= code && code < 0x7F) {
        if (code == 0x5C) {
          buf.write(r'\\');
        } else {
          buf.writeCharCode(code);
        }
      } else if (code < 0x100) {
        buf.write(r'\x');
        buf.write(hexDigits[code >> 4]);
        buf.write(hexDigits[code & 15]);
      } else {
        buf.write(r'\u{');
        buf.write(code.toRadixString(16).toUpperCase());
        buf.write('}');
      }
    }
  }

  /// Find the difference between two strings.
  ///
  /// This finds the first point where two strings differ, and returns
  /// a text describing the difference.
  ///
  /// For small strings (length less than 20) nothing is done, and "" is
  /// returned. Small strings can be compared visually, but for longer strings
  /// only a slice containing the first difference will be shown.
  static String _stringDifference(String expected, String actual) {
    if (expected.length < 20 && actual.length < 20) return '';
    for (int i = 0; i < expected.length && i < actual.length; i++) {
      if (expected.codeUnitAt(i) != actual.codeUnitAt(i)) {
        final int start = i;
        i++;
        while (i < expected.length && i < actual.length) {
          if (expected.codeUnitAt(i) == actual.codeUnitAt(i)) break;
          i++;
        }
        final int end = i;
        final truncExpected = _truncateString(expected, start, end, 20);
        final truncActual = _truncateString(actual, start, end, 20);
        return 'at index $start: Expected <$truncExpected>, '
            'Found: <$truncActual>';
      }
    }
    return '';
  }

  /// Checks whether the expected and actual values are equal (using `==`).
  static void equals(dynamic expected, dynamic actual, [String reason = '']) {
    if (expected == actual) return;
    final String msg = _getMessage(reason);
    if (expected is String && actual is String) {
      final String stringDifference = _stringDifference(expected, actual);
      if (stringDifference.isNotEmpty) {
        fail('Expect.equals($stringDifference$msg) fails.');
      }
      fail('Expect.equals(expected: <${_escapeString(expected)}>'
          ', actual: <${_escapeString(actual)}>$msg) fails.');
    }
    fail('Expect.equals(expected: <$expected>, actual: <$actual>$msg) fails.');
  }

  /// Verifies that [computation] throws a [T].
  ///
  /// Calls the [computation] function and fails if that call doesn't throw,
  /// throws something which is not a [T], or throws a [T] which does not
  /// satisfy the optional [check] function.
  ///
  /// Returns the accepted thrown [T] object, if one is caught.
  /// This value can be checked further, instead of checking it in the [check]
  /// function. For example, to check the content of the thrown object,
  /// you could write this:
  /// ```
  /// var e = Expect.throws<MyException>(myThrowingFunction);
  /// Expect.isTrue(e.myMessage.contains("WARNING"));
  /// ```
  /// The type variable can be omitted, in which case it defaults to [Object],
  /// and the (sub-)type of the object can be checked in [check] instead.
  /// This was traditionally done before Dart had generic methods.
  ///
  /// If `computation` fails another test expectation
  /// (i.e., throws an [ExpectException]),
  /// that exception cannot be caught and accepted by [Expect.throws].
  /// The test is still considered failing.
  static T throws<T extends Object>(
    void Function() computation, [
    bool Function(T error)? check,
    String reason = '',
  ]) {
    if ((computation as dynamic) == null) {
      // Only throws from executing the function body should count as throwing.
      // The failure to even call `f` should throw outside the try/catch.
      testError('Function must not be null');
    }
    try {
      computation();
    } catch (e, s) {
      // A test failure doesn't count as throwing, and can't be expected.
      if (e is ExpectException) rethrow;
      if (e is T && (check == null || check(e))) return e;
      // Throws something unexpected.
      final msg = _getMessage(reason);
      String type = '';
      if (T != dynamic && T != Object) {
        type = '<$T>';
      }
      fail(
        'Expect.throws$type$msg: '
        "Unexpected '${Error.safeToString(e)}'\n$s",
      );
    }
    fail('Expect.throws${_getMessage(reason)} fails: Did not throw');
  }

  /// Checks whether the actual value is a bool and its value is true.
  static void isTrue(dynamic actual, [String reason = '']) {
    if (_identical(actual, true)) return;
    final String msg = _getMessage(reason);
    fail('Expect.isTrue($actual$msg) fails.');
  }

  /// Checks whether the actual value is a bool and its value is false.
  static void isFalse(dynamic actual, [String reason = '']) {
    if (_identical(actual, false)) return;
    final String msg = _getMessage(reason);
    fail('Expect.isFalse($actual$msg) fails.');
  }

  /// Checks whether [actual] is null.
  static void isNull(dynamic actual, [String reason = '']) {
    if (null == actual) return;
    final String msg = _getMessage(reason);
    fail('Expect.isNull(actual: <$actual>$msg) fails.');
  }

  /// Checks whether [actual] is not null.
  static void isNotNull(dynamic actual, [String reason = '']) {
    if (null != actual) return;
    final String msg = _getMessage(reason);
    fail('Expect.isNotNull(actual: <$actual>$msg) fails.');
  }

  static String _getMessage(String reason) =>
      (reason.isEmpty) ? '' : ", '$reason'";

  static Never fail(String message) {
    throw ExpectException(message);
  }

  /// Reports that there is an error in the test itself and not the code under
  /// test.
  ///
  /// It may be using the expect API incorrectly or failing some other
  /// invariant that the test expects to be true.
  static Never testError(String message) {
    fail('Test error: $message');
  }
}

/// Exception thrown on a failed expectation check.
///
/// Always recognized by [Expect.throws] as an unexpected error.
class ExpectException {
  /// Call this to provide a function that associates a test name with this
  /// failure.
  ///
  /// Used by async_helper/async_minitest.dart to inject logic to bind the
  /// `group()` and `test()` name strings to a test failure.
  static void setTestNameCallback(String Function() getName) {
    _getTestName = getName;
  }

  static String Function() _getTestName = _kEmptyString;

  final String message;
  final String name;

  ExpectException(this.message) : name = _getTestName();

  @override
  String toString() {
    if (name != '') return 'In test "$name" $message';
    return message;
  }

  /// Initial value for _getTestName.
  static String _kEmptyString() => '';
}

/// Used in [Expect] because [Expect.identical] shadows the real [identical].
bool _identical(a, b) => identical(a, b);
