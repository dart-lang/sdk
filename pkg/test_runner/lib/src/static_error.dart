// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Only needed so that [TestFile] can be referenced in doc comments.
import 'test_file.dart';

/// Describes a static error.
///
/// These can be parsed from comments in [TestFile]s, in which case they
/// represent *expected* errors. If a test contains any of these, then it is a
/// "static error test" and exists to validate that a conforming front end
/// produces the expected compile-time errors.
///
/// Aside from location, there are two interesting attributes of an error that
/// a test can verify: its error code and the error message. Currently, for
/// analyzer we only care about the error code. The CFE does not report an
/// error code and only reports a message. So this class takes advantage of
/// that by allowing you to set expectations for analyzer and CFE independently
/// by assuming the [code] field is only used for the former and the [message]
/// for the latter.
///
/// This same class is also used for *reported* errors when parsing the output
/// of a front end.
class StaticError implements Comparable<StaticError> {
  static const _unspecified = "unspecified";

  /// Parses the set of static error expectations defined in the Dart source
  /// file [source].
  static List<StaticError> parseExpectations(String source) =>
      _ErrorExpectationParser(source)._parse();

  /// Collapses overlapping [errors] into a shorter list of errors where
  /// possible.
  ///
  /// Two errors on the same location can be collapsed if one has an error code
  /// but no message and the other has a message but no code.
  static List<StaticError> simplify(List<StaticError> errors) {
    var result = errors.toList();
    result.sort();

    for (var i = 0; i < result.length - 1; i++) {
      var a = result[i];

      // Look for a later error we can merge with this one. Usually, it will be
      // adjacent to this one, but if there are multiple errors with no length
      // on the same location, those will all be next to each other and their
      // merge targets will come later. This happens when CFE reports multiple
      // errors at the same location (messages but no length) and analyzer does
      // too (codes and lengths but no messages).
      for (var j = i + 1; j < result.length; j++) {
        var b = result[j];

        // Position must be the same. If the position is different, we can
        // stop looking because all same-position errors will be adjacent.
        if (a.line != b.line) break;
        if (a.column != b.column) break;

        // If they both have lengths that are different, we can't discard that
        // information.
        if (a.length != null && b.length != null && a.length != b.length) {
          continue;
        }

        // Can't discard content.
        if (a.code != null && b.code != null) continue;
        if (a.message != null && b.message != null) continue;

        result[i] = StaticError(
            line: a.line,
            column: a.column,
            length: a.length ?? b.length,
            code: a.code ?? b.code,
            message: a.message ?? b.message);
        result.removeAt(j);
        break;
      }
    }

    return result;
  }

  /// Determines whether all [actualErrors] match the given [expectedErrors].
  ///
  /// If they match, returns `null`. Otherwise returns a string describing the
  /// mismatches. This is a human-friendly explanation of the difference
  /// between the two sets of errors, while also being simple to implement.
  /// An expected error that is completely identical to an actual error is
  /// treated as a match. Everything else is a failure.
  ///
  /// It treats line number as the "identity" of an error. So if there are two
  /// errors on the same line that differ in other properties, it reports that
  /// as a "wrong" error. Any expected error on a line containing no actual
  /// error is reported as a "missing" error. Conversely, an actual error on a
  /// line containing no expected error is an "unexpected" error.
  ///
  /// By not treating the error's index in the list to be its identity, we
  /// gracefully handle extra or missing errors without causing cascading
  /// failures for later errors in the lists.
  static String validateExpectations(Iterable<StaticError> expectedErrors,
      Iterable<StaticError> actualErrors) {
    // Don't require the test or front end to output in any specific order.
    var sortedExpected = expectedErrors.toList();
    var sortedActual = actualErrors.toList();
    sortedExpected.sort();
    sortedActual.sort();

    var buffer = StringBuffer();

    describeError(String adjective, StaticError error, String verb) {
      buffer.writeln("$adjective static error at ${error.location}:");
      if (error.code == _unspecified) {
        buffer.writeln("- $verb unspecified error code.");
      } else if (error.code != null) {
        buffer.writeln("- $verb error code ${error.code}.");
      }

      if (error.message == _unspecified) {
        buffer.writeln("- $verb unspecified error message.");
      } else if (error.message != null) {
        buffer.writeln("- $verb error message '${error.message}'.");
      }
      buffer.writeln();
    }

    var expectedIndex = 0;
    var actualIndex = 0;
    for (;
        expectedIndex < sortedExpected.length &&
            actualIndex < sortedActual.length;) {
      var expected = sortedExpected[expectedIndex];
      var actual = sortedActual[actualIndex];

      var differences = expected.describeDifferences(actual);
      if (differences == null) {
        // Consume this actual error.
        actualIndex++;

        // Consume the expectation, unless it's an unspecified error that can
        // match more actual errors.
        if (expected.isSpecifiedFor(actual) ||
            actualIndex == sortedActual.length ||
            sortedActual[actualIndex].line != expected.line) {
          expectedIndex++;
        }
      } else if (expected.line == actual.line) {
        buffer.writeln("Wrong static error at ${expected.location}:");
        for (var difference in differences) {
          buffer.writeln("- $difference");
        }
        buffer.writeln();
        expectedIndex++;
        actualIndex++;
      } else if (expected.line < actual.line) {
        describeError("Missing", expected, "Expected");
        expectedIndex++;
      } else {
        describeError("Unexpected", actual, "Had");
        actualIndex++;
      }
    }

    // Output any trailing expected or actual errors if the lengths of the
    // lists differ.
    for (; expectedIndex < sortedExpected.length; expectedIndex++) {
      describeError("Missing", sortedExpected[expectedIndex], "Expected");
    }

    for (; actualIndex < sortedActual.length; actualIndex++) {
      describeError("Unexpected", sortedActual[actualIndex], "Had");
    }

    if (buffer.isEmpty) return null;
    return buffer.toString().trimRight();
  }

  /// The one-based line number of the beginning of the error's location.
  final int line;

  /// The one-based column number of the beginning of the error's location.
  final int column;

  /// The number of characters in the error location.
  ///
  /// This is optional. The CFE only reports error location, but not length.
  final int length;

  /// The expected analyzer error code for the error or `null` if this error
  /// isn't expected to be reported by analyzer.
  final String code;

  /// The expected CFE error message or `null` if this error isn't expected to
  /// be reported by the CFE.
  final String message;

  /// The zero-based index of the first line in the [TestFile] containing the
  /// marker comments that define this error.
  ///
  /// If this error was not parsed from a file, this may be `null`.
  final int markerStartLine;

  /// The zero-based index of the last line in the [TestFile] containing the
  /// marker comments that define this error, inclusive.
  ///
  /// If this error was not parsed from a file, this may be `null`.
  final int markerEndLine;

  /// Creates a new StaticError at the given location with the given expected
  /// error code and message.
  ///
  /// In order to make it easier to incrementally add error tests before a
  /// feature is fully implemented or specified, an error expectation can be in
  /// an "unspecified" state for either or both platforms by having the error
  /// code or message be the special string "unspecified". When an unspecified
  /// error is tested, a front end is expected to report *some* error on that
  /// error's line, but it can be any location, error code, or message.
  StaticError(
      {this.line,
      this.column,
      this.length,
      this.code,
      this.message,
      this.markerStartLine,
      this.markerEndLine}) {
    // Must have a location.
    assert(line != null);
    assert(column != null);

    // Must have at least one piece of description.
    assert(code != null || message != null);
  }

  /// Whether this error should be reported by analyzer.
  bool get isAnalyzer => code != null;

  /// Whether this error should be reported by the CFE.
  bool get isCfe => message != null;

  /// A textual description of this error's location.
  String get location {
    var result = "line $line, column $column";
    if (length != null) result += ", length $length";
    return result;
  }

  String toString() {
    var result = "Error at $location";
    if (code != null) result += "\n$code";
    if (message != null) result += "\n$message";
    return result;
  }

  /// Orders errors primarily by location, then by other fields if needed.
  @override
  int compareTo(StaticError other) {
    if (line != other.line) return line.compareTo(other.line);
    if (column != other.column) return column.compareTo(other.column);

    // Sort no length after all other lengths.
    if (length == null && other.length != null) return 1;
    if (length != null && other.length == null) return -1;
    if (length != other.length) return length.compareTo(other.length);

    var thisCode = code ?? "";
    var otherCode = other.code ?? "";
    if (thisCode != otherCode) return thisCode.compareTo(otherCode);

    var thisMessage = message ?? "";
    var otherMessage = other.message ?? "";
    return thisMessage.compareTo(otherMessage);
  }

  @override
  bool operator ==(other) => other is StaticError && compareTo(other) == 0;

  @override
  int get hashCode {
    return 3 * line.hashCode +
        5 * column.hashCode +
        7 * (length ?? 0).hashCode +
        11 * (code ?? "").hashCode +
        13 * (message ?? "").hashCode;
  }

  /// Whether this error expectation is a specified error for the front end
  /// reported by [actual].
  bool isSpecifiedFor(StaticError actual) {
    if (actual.isAnalyzer) return isAnalyzer && code != _unspecified;
    return isCfe && message != _unspecified;
  }

  /// Compares this error expectation to [actual].
  ///
  /// If this error correctly matches [actual], returns `null`. Otherwise
  /// returns a list of strings describing the mismatch.
  ///
  /// Note that this does *not* check to see that [actual] matches the platforms
  /// that this error expects. For example, if [actual] only reports an error
  /// code (i.e. it is analyzer-only) and this error only specifies an error
  /// message (i.e. it is CFE-only), this will still report differences in
  /// location information. This method expects that error expectations have
  /// already been filtered by platform so this will only be called in cases
  /// where the platforms do match.
  List<String> describeDifferences(StaticError actual) {
    var differences = <String>[];

    if (line != actual.line) {
      differences.add("Expected on line $line but was on ${actual.line}.");
    }

    // If the error is unspecified on the front end being tested, the column
    // and length can be any values.
    if (isSpecifiedFor(actual)) {
      if (column != actual.column) {
        differences
            .add("Expected on column $column but was on ${actual.column}.");
      }

      // This error represents an expectation, so should have a length.
      assert(length != null);
      if (actual.length != null && length != actual.length) {
        differences.add("Expected length $length but was ${actual.length}.");
      }
    }

    if (code != null &&
        code != _unspecified &&
        actual.code != null &&
        code != actual.code) {
      differences.add("Expected error code $code but was ${actual.code}.");
    }

    if (message != null &&
        message != _unspecified &&
        actual.message != null &&
        message != actual.message) {
      differences.add(
          "Expected error message '$message' but was '${actual.message}'.");
    }

    if (differences.isNotEmpty) return differences;
    return null;
  }
}

class _ErrorExpectationParser {
  /// Marks the location of an expected error, like so:
  ///
  ///     int i = "s";
  ///     //      ^^^
  ///
  /// We look for a line that starts with a line comment followed by spaces and
  /// carets.
  static final _caretLocationRegExp = RegExp(r"^\s*//\s*(\^+)\s*$");

  /// Matches an explicit error location with a length, like:
  ///
  ///     // [error line 1, column 17, length 3]
  static final _explicitLocationAndLengthRegExp =
      RegExp(r"^\s*//\s*\[\s*error line\s+(\d+)\s*,\s*column\s+(\d+)\s*,\s*"
          r"length\s+(\d+)\s*\]\s*$");

  /// Matches an explicit error location without a length, like:
  ///
  ///     // [error line 1, column 17]
  static final _explicitLocationRegExp =
      RegExp(r"^\s*//\s*\[\s*error line\s+(\d+)\s*,\s*column\s+(\d+)\s*\]\s*$");

  /// An analyzer error expectation starts with `// [analyzer]`.
  static final _analyzerErrorRegExp = RegExp(r"^\s*// \[analyzer\]\s*(.*)");

  /// An analyzer error code is a dotted identifier or the magic string
  /// "unspecified".
  static final _errorCodeRegExp = RegExp(r"^\w+\.\w+|unspecified$");

  /// The first line of a CFE error expectation starts with `// [cfe]`.
  static final _cfeErrorRegExp = RegExp(r"^\s*// \[cfe\]\s*(.*)");

  /// Any line-comment-only lines after the first line of a CFE error message
  /// are part of it.
  static final _errorMessageRestRegExp = RegExp(r"^\s*//\s*(.*)");

  /// Matches the multitest marker and yields the preceding content.
  final _stripMultitestRegExp = RegExp(r"(.*)//#");

  final List<String> _lines;
  final List<StaticError> _errors = [];
  int _currentLine = 0;

  // One-based index of the last line that wasn't part of an error expectation.
  int _lastRealLine = -1;

  _ErrorExpectationParser(String source) : _lines = source.split("\n");

  List<StaticError> _parse() {
    while (!_isAtEnd) {
      var sourceLine = _peek(0);

      var match = _caretLocationRegExp.firstMatch(sourceLine);
      if (match != null) {
        if (_lastRealLine == -1) {
          _fail("An error expectation must follow some code.");
        }

        _parseErrorDetails(
            line: _lastRealLine,
            column: sourceLine.indexOf("^") + 1,
            length: match.group(1).length);
        _advance();
        continue;
      }

      match = _explicitLocationAndLengthRegExp.firstMatch(sourceLine);
      if (match != null) {
        _parseErrorDetails(
            line: int.parse(match.group(1)),
            column: int.parse(match.group(2)),
            length: int.parse(match.group(3)));
        _advance();
        continue;
      }

      match = _explicitLocationRegExp.firstMatch(sourceLine);
      if (match != null) {
        _parseErrorDetails(
            line: int.parse(match.group(1)), column: int.parse(match.group(2)));
        _advance();
        continue;
      }

      _lastRealLine = _currentLine + 1;
      _advance();
    }

    return _errors;
  }

  /// Finishes parsing an error expectation after parsing the location.
  void _parseErrorDetails({int line, int column, int length}) {
    String code;
    String message;

    var startLine = _currentLine;

    // Look for an error code line.
    if (!_isAtEnd) {
      var match = _analyzerErrorRegExp.firstMatch(_peek(1));
      if (match != null) {
        code = match.group(1);

        if (!_errorCodeRegExp.hasMatch(code)) {
          _fail("An analyzer error expectation should be a dotted identifier.");
        }

        _advance();
      }
    }

    // Look for an error message.
    if (!_isAtEnd) {
      var match = _cfeErrorRegExp.firstMatch(_peek(1));
      if (match != null) {
        message = match.group(1);
        _advance();

        // Consume as many additional error message lines as we find.
        while (!_isAtEnd) {
          var nextLine = _peek(1);

          // A location line shouldn't be treated as a message.
          if (_caretLocationRegExp.hasMatch(nextLine)) break;
          if (_explicitLocationAndLengthRegExp.hasMatch(nextLine)) break;
          if (_explicitLocationRegExp.hasMatch(nextLine)) break;

          // Don't let users arbitrarily order the error code and message.
          if (_analyzerErrorRegExp.hasMatch(nextLine)) {
            _fail("An analyzer expectation must come before a CFE "
                "expectation.");
          }

          var messageMatch = _errorMessageRestRegExp.firstMatch(nextLine);
          if (messageMatch == null) break;

          message += "\n" + messageMatch.group(1);
          _advance();
        }
      }
    }

    if (code == null && message == null) {
      _fail("An error expectation must specify at least an analyzer or CFE "
          "error.");
    }

    // Hack: If the error is CFE-only and the length is one, treat it as no
    // length. The CFE does not output length information, and when the update
    // tool writes a CFE-only error, it implicitly uses a length of one. Thus,
    // when we parse back in a length one CFE error, we ignore the length so
    // that the error round-trips correctly.
    // TODO(rnystrom): Stop doing this when the CFE reports error lengths.
    if (code == null && length == 1) length = null;

    _errors.add(StaticError(
        line: line,
        column: column,
        length: length,
        code: code,
        message: message,
        markerStartLine: startLine,
        markerEndLine: _currentLine));
  }

  bool get _isAtEnd => _currentLine >= _lines.length;

  void _advance() {
    _currentLine++;
  }

  String _peek(int offset) {
    var line = _lines[_currentLine + offset];

    // Strip off any multitest marker.
    var multitestMatch = _stripMultitestRegExp.firstMatch(line);
    if (multitestMatch != null) {
      line = multitestMatch.group(1).trimRight();
    }

    return line;
  }

  void _fail(String message) {
    throw FormatException("Test error on line ${_currentLine + 1}: $message");
  }
}
