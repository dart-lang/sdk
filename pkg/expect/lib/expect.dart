// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library contains an `Expect` class with static methods that can be used
/// for simple unit-tests.
///
/// The library is deliberately written to use as few and simple language
/// features as reasonable to perform the tests.
/// This ensures that it can be used to test as many language features as
/// possible.
///
/// Error reporting as allowed to use more features, under the assumption
/// that it will either work as desired, or break in some other way.
/// As long as the *success path* is simple, a successful test can be trusted.
library expect;

/// Whether the program is running without sound null safety.
// TODO(54798): migrate uses to directly import variations.dart
@Deprecated('Use unsoundNullSafety from variations.dart instead')
bool get hasUnsoundNullSafety => const <Null>[] is List<Object>;

/// Whether the program is running with sound null safety.
// TODO(54798): migrate uses to directly import variations.dart
@Deprecated('Use !unsoundNullSafety from variations.dart instead')
bool get hasSoundNullSafety => !hasUnsoundNullSafety;

/// Expect is used for tests that do not want to make use of the
/// Dart unit test library - for example, the core language tests.
/// Third parties are discouraged from using this, and should use
/// the expect() function in the unit test library instead for
/// test assertions.
class Expect {
  /// A slice of a string for inclusion in error messages.
  ///
  /// The [start] and [end] represents a slice of a string which
  /// has failed a test. For example, it's a part of a string
  /// which is not equal to an expected string value.
  ///
  /// The [length] limits the length of the representation of the slice,
  /// to avoid a long difference being shown in its entirety.
  ///
  /// The slice will contain at least some part of the substring from [start]
  /// to the lower of [end] and `start + length`.
  /// If the result is no more than `length - 10` characters long,
  /// context may be added by extending the range of the slice, by decreasing
  /// [start] and increasing [end], up to at most length characters.
  /// If the start or end of the slice are not matching the start or end of
  /// the string, ellipses (`"..."`) are added before or after the slice.
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

  /// The [string] with non printable-ASCII characters escaped.
  ///
  /// Any character of [string] which is not ASCII or an ASCII control character
  /// is represented as either `"\xXX"` or `"\uXXXX"` hex escapes.
  /// Backslashes are escaped as `"\\"`.
  static String _escapeString(String string) {
    StringBuffer buf = StringBuffer();
    _escapeSubstring(buf, string, 0, string.length);
    return buf.toString();
  }

  static _escapeSubstring(StringBuffer buf, String string, int start, int end) {
    const hexDigits = "0123456789ABCDEF";
    const backslash = 0x5c;
    int chunkStart = start; // No escapes since this point.
    for (int i = start; i < end; i++) {
      int code = string.codeUnitAt(i);
      if (0x20 <= code && code < 0x7F && code != backslash) {
        continue;
      }
      if (i > chunkStart) {
        buf.write(string.substring(chunkStart, i));
      }
      if (code == backslash) {
        buf.write(r"\\");
      } else if (code < 0x100) {
        if (code == 0x09) {
          buf.write(r"\t");
        } else if (code == 0x0a) {
          buf.write(r"\n");
        } else if (code == 0x0d) {
          buf.write(r"\r");
        } else if (code == 0x5c) {
          buf.write(r"\\");
        } else {
          buf.write(r"\x");
          buf.write(hexDigits[code >> 4]);
          buf.write(hexDigits[code & 15]);
        }
      } else {
        buf.write(r"\u{");
        buf.write(code.toRadixString(16).toUpperCase());
        buf.write(r"}");
      }
      chunkStart = i + 1;
    }
    if (chunkStart < end) {
      buf.write(string.substring(chunkStart, end));
    }
  }

  /// A string representing the difference between two strings.
  ///
  /// The two strings have already been checked as not being equal (`==`).
  ///
  /// This function finds the first point where the two strings differ,
  /// and returns a text describing the difference.
  ///
  /// For small strings (length less than 20) nothing is done, and "" is
  /// returned, representing that the entire string can be used to display
  /// the difference.
  /// Small strings can be compared visually, but for longer strings
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
        var truncatedExpected = _truncateString(expected, start, end, 20);
        var truncatedActual = _truncateString(actual, start, end, 20);
        return "at index $start: Expected <$truncatedExpected>, "
            "Found: <$truncatedActual>";
      }
    }
    return "";
  }

  /// Checks that the expected and actual values are equal (using `==`).
  static void equals(dynamic expected, dynamic actual, [String reason = ""]) {
    if (expected == actual) return;
    _failNotEqual(expected, actual, "equals", reason);
  }

  /// Reports two values not equal.
  ///
  /// Used by, for example, `Expect.equals` and `Expect.deepEquals`.
  static void _failNotEqual(
      dynamic expected, dynamic actual, String test, String reason) {
    String msg = _getMessage(reason);
    if (expected is String && actual is String) {
      String stringDifference = _stringDifference(expected, actual);
      if (stringDifference.isNotEmpty) {
        _fail("Expect.$test($stringDifference$msg) fails.");
      }
      _fail("Expect.$test(expected: <${_escapeString(expected)}>"
          ", actual: <${_escapeString(actual)}>$msg) fails.");
    }
    _fail("Expect.$test(expected: <$expected>, actual: <$actual>$msg) fails.");
  }

  /// Checks that the actual value is a `bool` and its value is `true`.
  static void isTrue(dynamic actual, [String reason = ""]) {
    if (_identical(actual, true)) return;
    String msg = _getMessage(reason);
    _fail("Expect.isTrue($actual$msg) fails.");
  }

  /// Checks that the actual value is a `bool` and its value is `false`.
  static void isFalse(dynamic actual, [String reason = ""]) {
    if (_identical(actual, false)) return;
    String msg = _getMessage(reason);
    _fail("Expect.isFalse($actual$msg) fails.");
  }

  /// Checks that [actual] is null.
  static void isNull(dynamic actual, [String reason = ""]) {
    if (null == actual) return;
    String msg = _getMessage(reason);
    _fail("Expect.isNull(actual: <$actual>$msg) fails.");
  }

  /// Checks that [actual] is not null.
  static void isNotNull(dynamic actual, [String reason = ""]) {
    if (null != actual) return;
    String msg = _getMessage(reason);
    _fail("Expect.isNotNull(actual: null$msg) fails.");
  }

  /// Checks that the [Iterable] [actual] is empty.
  static void isEmpty(Iterable actual, [String reason = ""]) {
    if (actual.isEmpty) return;
    String msg = _getMessage(reason);
    var sample = actual.take(4).toList();
    var sampleString = sample.length < 4
        ? sample.join(", ")
        : "${sample.take(3).join(", ")}, ...";
    _fail("Expect.isEmpty(actual: <$sampleString>$msg): Is not empty.");
  }

  /// Checks that the [Iterable] [actual] is not empty.
  static void isNotEmpty(Iterable actual, [String reason = ""]) {
    if (!actual.isEmpty) return; // ignore: prefer_is_not_empty
    String msg = _getMessage(reason);
    _fail("Expect.isNotEmpty(actual: <${Error.safeToString(actual)}>$msg): "
        "Is empty.");
  }

  /// Checks that the expected and actual values are identical
  /// (using `identical`).
  // TODO(lrn): Rename to `same`, to match package:test, and to not
  // shadow `identical` from `dart:core`. (And `allIdentical` to `allSame`.)
  static void identical(dynamic expected, dynamic actual,
      [String reason = ""]) {
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

  /// Finds equivalence classes of objects (by index) wrt. identity.
  ///
  /// Returns a list of lists of identical object indices per object.
  /// That is, `objects[i]` is identical to objects with indices in
  /// `_findEquivalences(objects)[i]`.
  ///
  /// Uses `[]` for objects that are only identical to themselves.
  static List<List<int>> _findEquivalences(List<dynamic> objects) {
    var equivalences = List<List<int>>.generate(objects.length, (_) => <int>[]);
    for (int i = 0; i < objects.length; i++) {
      if (equivalences[i].isNotEmpty) continue;
      var o = objects[i];
      for (int j = i + 1; j < objects.length; j++) {
        if (equivalences[j].isNotEmpty) continue;
        if (_identical(o, objects[j])) {
          if (equivalences[i].isEmpty) {
            equivalences[i].add(i);
          }
          equivalences[j] = equivalences[i]..add(j);
        }
      }
    }
    return equivalences;
  }

  static void _writeEquivalences(List<dynamic> objects,
      List<List<int>> equivalences, StringBuffer buffer) {
    var separator = "";
    for (int i = 0; i < objects.length; i++) {
      buffer.write(separator);
      separator = ",";
      var equivalence = equivalences[i];
      if (equivalence.isEmpty) {
        buffer.write('_');
      } else {
        int first = equivalence[0];
        buffer
          ..write('#')
          ..write(first);
        if (first == i) {
          buffer
            ..write('=')
            ..write(objects[i]);
        }
      }
    }
  }

  static void allIdentical(List<dynamic> objects, [String reason = ""]) {
    if (objects.length <= 1) return;
    bool allIdentical = true;
    var firstObject = objects[0];
    for (var i = 1; i < objects.length; i++) {
      if (!_identical(firstObject, objects[i])) {
        allIdentical = false;
      }
    }
    if (allIdentical) return;
    String msg = _getMessage(reason);
    var equivalences = _findEquivalences(objects);
    var buffer = StringBuffer("Expect.allIdentical([");
    _writeEquivalences(objects, equivalences, buffer);
    buffer
      ..write("]")
      ..write(msg)
      ..write(")");
    _fail(buffer.toString());
  }

  /// Checks that the expected and actual values are *not* identical
  /// (using `identical`).
  static void notIdentical(var unexpected, var actual, [String reason = ""]) {
    if (!_identical(unexpected, actual)) return;
    String msg = _getMessage(reason);
    _fail("Expect.notIdentical(expected and actual: <$actual>$msg) fails.");
  }

  /// Checks that no two [objects] are `identical`.
  static void allDistinct(List<dynamic> objects, [String reason = ""]) {
    if (objects.length <= 1) return;
    bool allDistinct = true;
    for (var i = 0; i < objects.length; i++) {
      var earlierObject = objects[i];
      for (var j = i + 1; j < objects.length; j++) {
        if (_identical(earlierObject, objects[j])) {
          allDistinct = false;
        }
      }
    }
    if (allDistinct) return;
    String msg = _getMessage(reason);
    var equivalences = _findEquivalences(objects);

    var buffer = StringBuffer("Expect.allDistinct([");
    _writeEquivalences(objects, equivalences, buffer);
    buffer
      ..write("]")
      ..write(msg)
      ..write(")");
    _fail(buffer.toString());
  }

  // Unconditional failure.
  // This function always throws, as [_fail] always throws.
  // TODO(srawlins): It would be more correct to change the return type to
  // `Never`, which would require refactoring many language and co19 tests.
  static void fail(String msg) {
    _fail("Expect.fail('$msg')");
  }

  /// Checks that two numbers are relatively close.
  ///
  /// Intended for `double` computations with some tolerance in the result.
  ///
  /// Fails if the difference between expected and actual is greater than the
  /// given tolerance. If no tolerance is given, tolerance is assumed to be the
  /// value 4 significant digits smaller than the value given for expected.
  static void approxEquals(num expected, num actual,
      [num tolerance = -1, String reason = ""]) {
    if (tolerance < 0) {
      tolerance = (expected / 1e4).abs();
    }
    // Note: Use success if `<=` rather than failing on `>`
    // so the test fails on NaNs.
    if ((expected - actual).abs() <= tolerance) return;

    String msg = _getMessage(reason);
    _fail('Expect.approxEquals(expected:<$expected>, actual:<$actual>, '
        'tolerance:<$tolerance>$msg) fails');
  }

  static void notEquals(unexpected, actual, [String reason = ""]) {
    if (unexpected != actual) return;
    String msg = _getMessage(reason);
    _fail("Expect.notEquals(unexpected: <$unexpected>, actual:<$actual>$msg) "
        "fails.");
  }

  /// Checks that all elements in [expected] and [actual] are pairwise equal.
  ///
  /// This is different than the typical check for identity equality `identical`
  /// used by the standard list implementation.
  static void listEquals(List expected, List actual, [String reason = ""]) {
    // Check elements before length.
    // It may show *which* element has been added or is missing.
    int n = (expected.length < actual.length) ? expected.length : actual.length;
    for (int i = 0; i < n; i++) {
      var expectedValue = expected[i];
      var actualValue = actual[i];
      if (expectedValue != actualValue) {
        var indexReason =
            reason.isEmpty ? "at index $i" : "$reason, at index $i";
        _failNotEqual(expectedValue, actualValue, "listEquals", indexReason);
      }
    }
    // Check that the lengths agree as well.
    if (expected.length != actual.length) {
      String msg = _getMessage(reason);
      _fail('Expect.listEquals(list length, '
          'expected: <${expected.length}>, actual: <${actual.length}>$msg) '
          'fails: Next element <'
          '${expected.length > n ? expected[n] : actual[n]}>');
    }
  }

  /// Checks that all [expected] and [actual] have the same set entries.
  ///
  /// Check that the maps have the same keys, using the semantics of
  /// [Map.containsKey] to determine what "same" means. For
  /// each key, checks that their values are equal using `==`.
  static void mapEquals(Map expected, Map actual, [String reason = ""]) {
    String msg = _getMessage(reason);

    // Make sure all of the values are present in both, and they match.
    var expectedKeys = expected.keys.toList();
    for (var i = 0; i < expectedKeys.length; i++) {
      var key = expectedKeys[i];
      if (!actual.containsKey(key)) {
        _fail('Expect.mapEquals(missing expected key: <$key>$msg) fails');
      }

      var expectedValue = expected[key];
      var actualValue = actual[key];
      if (expectedValue == actualValue) continue;
      _failNotEqual(expectedValue, actualValue, "mapEquals", "map[$key]");
    }

    // Make sure the actual map doesn't have any extra keys.
    var actualKeys = actual.keys.toList();
    for (var i = 0; i < actualKeys.length; i++) {
      var key = actualKeys[i];
      if (!expected.containsKey(key)) {
        _fail('Expect.mapEquals(unexpected key: <$key>$msg) fails');
      }
    }
  }

  /// Specialized equality test for strings. When the strings don't match,
  /// this method shows where the mismatch starts and ends.
  static void stringEquals(String expected, String actual,
      [String reason = ""]) {
    if (expected == actual) return;

    String msg = _getMessage(reason);
    String defaultMessage =
        'Expect.stringEquals(expected: <$expected>", <$actual>$msg) fails';

    // TODO(sound-null-safety): Remove.
    if ((expected as dynamic) == null || (actual as dynamic) == null) {
      _fail(defaultMessage);
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
      eSnippet = '${eSnippet.substring(0, 20)}...'
          '${eSnippet.substring(eSnippet.length - 20)}';
    }
    if (aSnippet.length > 43) {
      aSnippet = '${aSnippet.substring(0, 20)}...'
          '${aSnippet.substring(aSnippet.length - 20)}';
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

  /// Checks that the [haystack] string contains a given substring [needle].
  ///
  /// For example, this succeeds:
  /// ```dart
  /// Expect.contains("a", "abcdefg");
  /// ```
  static void contains(String expectedSubstring, String actual,
      [String reason = ""]) {
    if (actual.contains(expectedSubstring)) return;
    var msg = _getMessage(reason);
    _fail("Expect.contains('${_escapeString(expectedSubstring)}',"
        " '${_escapeString(actual)}'$msg) fails");
  }

  /// Checks that the [actual] string contains any of the [expectedSubstrings].
  ///
  /// For example, this succeeds since it contains at least one of the
  /// expected substrings:
  /// ```dart
  /// Expect.containsAny(["a", "e", "h"], "abcdefg");
  /// ```
  static void containsAny(List<String> expectedSubstrings, String actual,
      [String reason = ""]) {
    for (var i = 0; i < expectedSubstrings.length; i++) {
      if (actual.contains(expectedSubstrings[i])) return;
    }
    var msg = _getMessage(reason);
    _fail("Expect.containsAny(..., '${_escapeString(actual)}$msg): None of "
        "'${expectedSubstrings.join("', '")}' found");
  }

  /// Checks that [actual] contains the list of [expectedSubstrings] in order.
  ///
  /// For example, this succeeds:
  /// ```dart
  /// Expect.containsInOrder(["a", "c", "e"], "abcdefg");
  /// ```
  static void containsInOrder(List<String> expectedSubstrings, String actual,
      [String reason = ""]) {
    var start = 0;
    for (var i = 0; i < expectedSubstrings.length; i++) {
      var s = expectedSubstrings[i];
      var position = actual.indexOf(s, start);
      if (position < 0) {
        var msg = _getMessage(reason);
        _fail("Expect.containsInOrder(..., '${_escapeString(actual)}'"
            "$msg): Did not find '${_escapeString(s)}' in the expected order: "
            "'${expectedSubstrings.map(_escapeString).join("', '")}'");
      }
    }
  }

  /// Checks that [actual] contains the same elements as [expected].
  ///
  /// Intended to be used with sets, which has efficient [Set.contains],
  /// but can be used with any collection. The test behaves as if the
  /// collection was converted to a set.
  ///
  /// Should not be used with a lazy iterable, since it calls
  /// [Iterable.contains] repeatedly. Efficiency aside, if separate iterations
  /// can provide different results, the outcome of this test is unspecified.
  /// Should not be used with collections that contain the same value more than
  /// once.
  /// This is *not* an "unordered equality", which would consider `["a", "a"]`
  /// and `["a"]` different. This check would accept those inputs, as if
  /// calling `.toSet()` on the values first.
  ///
  /// Checks that the elements of [expected] are all in [actual],
  /// according to [actual.contains], and vice versa.
  /// Assumes that the sets use the same equality,
  /// which should be `==`-equality.
  static void setEquals(Iterable expected, Iterable actual,
      [String reason = ""]) {
    final List<dynamic> missingElements = [];
    final List<dynamic> extraElements = [];
    final List<dynamic> expectedElements = expected.toList();
    final List<dynamic> actualElements = actual.toList();
    for (var i = 0; i < expectedElements.length; i++) {
      var expectedElement = expectedElements[i];
      if (!actual.contains(expectedElement)) {
        missingElements.add(expectedElement);
      }
    }
    for (var i = 0; i < actualElements.length; i++) {
      var actualElement = actualElements[i];
      if (!expected.contains(actualElement)) {
        extraElements.add(actualElement);
      }
    }
    if (missingElements.isEmpty && extraElements.isEmpty) return;
    String msg = _getMessage(reason);

    StringBuffer sb = StringBuffer("Expect.setEquals($msg) fails");
    // Report any missing items.
    if (missingElements.isNotEmpty) {
      sb.write('\nMissing expected elements: ');
      for (final val in missingElements) {
        sb.write('$val ');
      }
    }

    // Report any extra items.
    if (extraElements.isNotEmpty) {
      sb.write('\nUnexpected elements: ');
      for (final val in extraElements) {
        sb.write('$val ');
      }
    }

    _fail(sb.toString());
  }

  /// Checks that [expected] is equivalent to [actual].
  ///
  /// If the objects are both `Set`s, `Iterable`s, or `Map`s,
  /// check that they have the same structure:
  /// * For sets: Same elements, based on [Set.contains]. Not recursive.
  /// * For maps: Same keys, based on [Map.containsKey], and with
  ///   recursively deep-equal for the values of each key.
  /// * For other, non-set, iterables: Same length and elements that
  ///   are pair-wise deep-equal.
  ///
  /// Assumes expected and actual maps and sets use the same equality.
  static void deepEquals(dynamic expected, dynamic actual) {
    _deepEquals(expected, actual, []);
  }

  static String _pathString(List<Object> path) => "[${path.join("][")}]";

  /// Recursive implementation of [deepEquals].
  ///
  /// The [path] contains a mutable list of the map keys or list indices
  /// traversed so far.
  static void _deepEquals(dynamic expected, dynamic actual, List<Object> path) {
    // Early exit check for equality.
    if (expected == actual) return;

    if (expected is Set && actual is Set) {
      var expectedElements = expected.toList();
      var actualElements = actual.toList();
      for (var i = 0; i < expectedElements.length; i++) {
        var value = expectedElements[i];
        if (!actual.contains(value)) {
          _fail("Expect.deepEquals(${_pathString(path)}), "
              "missing value: <$value>");
        }
      }
      for (var value in actualElements) {
        if (!expected.contains(value)) {
          _fail("Expect.deepEquals(${_pathString(path)}), "
              "unexpected value: <$value>");
        }
      }
    } else if (expected is Iterable && actual is Iterable) {
      var expectedElements = expected.toList();
      var actualElements = actual.toList();
      var expectedLength = expectedElements.length;
      var actualLength = actualElements.length;
      var minLength =
          expectedLength < actualLength ? expectedLength : actualLength;
      for (var i = 0; i < minLength; i++) {
        var expectedElement = expectedElements[i];
        var actualElement = actualElements[i];
        path.add(i);
        _deepEquals(expectedElement, actualElement, path);
        path.removeLast();
      }
      if (expectedLength != actualLength) {
        var nextElement = (expectedLength > actualLength
            ? expectedElements
            : actualElements)[minLength];
        _fail("Expect.deepEquals(${_pathString(path)}.length, "
            "expected: <$expectedLength>, actual: <$actualLength>) "
            "fails: Next element <$nextElement>");
      }
    } else if (expected is Map && actual is Map) {
      var expectedKeys = expected.keys.toList();
      var actualKeys = actual.keys.toList();
      // Make sure all of the keys are present in both, and match values.
      for (var i = 0; i < expectedKeys.length; i++) {
        var key = expectedKeys[i];
        if (!actual.containsKey(key)) {
          _fail("Expect.deepEquals(${_pathString(path)}), "
              "missing map key: <$key>");
        }
        path.add(key);
        _deepEquals(expected[key], actual[key], path);
        path.removeLast();
      }
      for (var key in actualKeys) {
        if (!expected.containsKey(key)) {
          _fail("Expect.deepEquals(${_pathString(path)}), "
              "unexpected map key: <$key>");
        }
      }
    } else {
      _failNotEqual(expected, actual, "deepEquals", _pathString(path));
    }
  }

  static bool _defaultCheck(dynamic _) => true;

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
  static T throws<T extends Object>(void Function() computation,
      [bool Function(T error)? check, String reason = ""]) {
    if ((computation as dynamic) == null) {
      // Only throws from executing the function body should count as throwing.
      // The failure to even call `f` should throw outside the try/catch.
      testError("Function must not be null");
    }
    try {
      computation();
    } catch (e, s) {
      // A test failure doesn't count as throwing, and can't be expected.
      if (e is ExpectException) rethrow;
      if (e is T && (check == null || check(e))) return e;
      // Throws something unexpected.
      String msg = _getMessage(reason);
      String type = "";
      if (T != dynamic && T != Object) {
        type = "<$T>";
      }
      _fail("Expect.throws$type$msg: "
          "Unexpected '${Error.safeToString(e)}'\n$s");
    }
    _fail('Expect.throws${_getMessage(reason)} fails: Did not throw');
  }

  /// Calls [computation] and checks that it throws an [E] when [condition] is
  /// `true`.
  ///
  /// If [condition] is `true`, the test succeeds if an [E] is thrown, and then
  /// that error is returned. The test fails if nothing is thrown or a different
  /// error is thrown.
  /// If [condition] is `false`, the test succeeds if nothing is thrown,
  /// returning `null`, and fails if anything is thrown.
  static E? throwsWhen<E extends Object>(
      bool condition, void Function() computation,
      [String reason = ""]) {
    if (condition) return throws<E>(computation, _defaultCheck, reason);
    computation();
    return null;
  }

  static ArgumentError throwsArgumentError(void Function() f,
          [String reason = ""]) =>
      Expect.throws<ArgumentError>(f, _defaultCheck, reason);

  static AssertionError throwsAssertionError(void Function() f,
          [String reason = ""]) =>
      Expect.throws<AssertionError>(f, _defaultCheck, reason);

  static FormatException throwsFormatException(void Function() f,
          [String reason = ""]) =>
      Expect.throws<FormatException>(f, _defaultCheck, reason);

  static NoSuchMethodError throwsNoSuchMethodError(void Function() f,
          [String reason = ""]) =>
      Expect.throws<NoSuchMethodError>(f, _defaultCheck, reason);

  static RangeError throwsRangeError(void Function() f, [String reason = ""]) =>
      Expect.throws<RangeError>(f, _defaultCheck, reason);

  static StateError throwsStateError(void Function() f, [String reason = ""]) =>
      Expect.throws<StateError>(f, _defaultCheck, reason);

  static TypeError throwsTypeError(void Function() f, [String reason = ""]) =>
      Expect.throws<TypeError>(f, _defaultCheck, reason);

  /// Checks that [f] throws a [TypeError] if and only if [condition] is `true`.
  static TypeError? throwsTypeErrorWhen(bool condition, void Function() f,
          [String reason = ""]) =>
      Expect.throwsWhen<TypeError>(condition, f, reason);

  static UnsupportedError throwsUnsupportedError(void Function() f,
          [String reason = ""]) =>
      Expect.throws<UnsupportedError>(f, _defaultCheck, reason);

  /// Reports that there is an error in the test itself and not the code under
  /// test.
  ///
  /// It may be using the expect API incorrectly or failing some other
  /// invariant that the test expects to be true.
  static void testError(String message) {
    _fail("Test error: $message");
  }

  /// Checks that [object] has type [T].
  static void type<T>(dynamic object, [String reason = ""]) {
    if (object is T) return;
    String msg = _getMessage(reason);
    _fail("Expect.type($object is $T$msg) fails "
        "on ${Error.safeToString(object)}");
  }

  /// Checks that [object] does not have type [T].
  static void notType<T>(dynamic object, [String reason = ""]) {
    if (object is! T) return;
    String msg = _getMessage(reason);
    _fail("Expect.type($object is! $T$msg) fails "
        "on ${Error.safeToString(object)}");
  }

  /// Asserts that `Sub` is a subtype of `Super` at compile time and run time.
  ///
  /// The upper bound on [Sub] means that it must *statically* be a subtype
  /// of [Super]. Soundness should guarantee that it is also true at runtime.
  ///
  /// This is more of an assertion than a test.
  // TODO(lrn): Remove this method, or make it only do runtime checks.
  // It doesn't fit the `Expect` class.
  // Use `static_type_helper.dart` or make a `Chk` class a member of the
  // `expect` package for use in checking *static* type properties.
  static void subtype<Sub extends Super, Super>() {
    if ((<Sub>[] as dynamic) is List<Super>) return;
    _fail("Expect.subtype<$Sub, $Super>: $Sub is not a subtype of $Super");
  }

  /// Checks that `Sub` is a subtype of `Super` at runtime.
  ///
  /// This is similar to [subtype] but without the `Sub extends Super` generic
  /// constraint, so a compiler is less likely to optimize away the `is` check
  /// because the types appear to be unrelated.
  static void runtimeSubtype<Sub, Super>() {
    if (<Sub>[] is List<Super>) return;
    _fail("Expect.runtimeSubtype<$Sub, $Super>: "
        "$Sub is not a subtype of $Super");
  }

  /// Checks that `Sub` is not a subtype of `Super` at runtime.
  static void notSubtype<Sub, Super>() {
    if (<Sub>[] is List<Super>) {
      _fail("Expect.notSubtype<$Sub, $Super>: $Sub is a subtype of $Super");
    }
  }

  static String _getMessage(String reason) =>
      reason.isEmpty ? "" : ", '$reason'";

  static Never _fail(String message) {
    throw ExpectException(message);
  }
}

/// Used in [Expect] because [Expect.identical] shadows the real [identical].
bool _identical(a, b) => identical(a, b);

/// Exception thrown on a failed expectation check.
///
/// Always recognized by [Expect.throws] as an unexpected error.
class ExpectException {
  /// Call this to provide a function that associates a test name with this
  /// failure.
  ///
  /// Used by legacy/async_minitest.dart to inject logic to bind the
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
