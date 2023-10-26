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
    StringBuffer buf = StringBuffer();
    if (start > 0) buf.write("...");
    _escapeSubstring(buf, string, 0, string.length);
    if (end < string.length) buf.write("...");
    return buf.toString();
  }

  /// Return the string with characters that are not printable ASCII characters
  /// escaped as either "\xXX" codes or "\uXXXX" codes.
  static String _escapeString(String string) {
    StringBuffer buf = StringBuffer();
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

  /// Find the difference between two strings.
  ///
  /// This finds the first point where two strings differ, and returns
  /// a text describing the difference.
  ///
  /// For small strings (length less than 20) nothing is done, and "" is
  /// returned. Small strings can be compared visually, but for longer strings
  /// only a slice containing the first difference will be shown.
  static String _stringDifference(String expected, String actual) {
    if (expected.length < 20 && actual.length < 20) return "";
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
    return "";
  }

  /// Checks whether the expected and actual values are equal (using `==`).
  static void equals(dynamic expected, dynamic actual, [String reason = ""]) {
    if (expected == actual) return;
    String msg = _getMessage(reason);
    if (expected is String && actual is String) {
      String stringDifference = _stringDifference(expected, actual);
      if (stringDifference.isNotEmpty) {
        _fail("Expect.equals($stringDifference$msg) fails.");
      }
      _fail("Expect.equals(expected: <${_escapeString(expected)}>"
          ", actual: <${_escapeString(actual)}>$msg) fails.");
    }
    _fail("Expect.equals(expected: <$expected>, actual: <$actual>$msg) fails.");
  }

  static String _getMessage(String reason) =>
      (reason.isEmpty) ? "" : ", '$reason'";

  static Never _fail(String message) {
    throw ExpectException(message);
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
    if (name != "") return 'In test "$name" $message';
    return message;
  }

  /// Initial value for _getTestName.
  static String _kEmptyString() => "";
}
