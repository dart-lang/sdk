// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Only needed so that [TestFile] can be referenced in doc comments.
import 'test_file.dart';

/// A front end that can report static errors.
class ErrorSource {
  static const analyzer = ErrorSource._("analyzer");
  static const cfe = ErrorSource._("CFE");
  static const web = ErrorSource._("web");

  /// All of the supported front ends.
  ///
  /// The order is significant here. In static error tests, error expectations
  /// must be in this order for consistency.
  static const all = [analyzer, cfe, web];

  /// Gets the source whose lowercase name is [name] or `null` if no source
  /// with that name could be found.
  static ErrorSource find(String name) {
    for (var source in all) {
      if (source.marker == name) return source;
    }

    return null;
  }

  /// A user readable name for the error source.
  final String name;

  /// The string used to mark errors from this source in test files.
  String get marker => name.toLowerCase();

  const ErrorSource._(this.name);
}

/// Describes one or more static errors that should be reported at a specific
/// location.
///
/// These can be parsed from comments in [TestFile]s, in which case they
/// represent *expected* errors. If a test contains any of these, then it is a
/// "static error test" and exists to validate that a conforming front end
/// produces the expected compile-time errors. This same class is also used for
/// *reported* errors when parsing the output of a front end.
///
/// Because there are multiple front ends that each report errors somewhat
/// differently, each [StaticError] has a map to associate an error message
/// with each front end. If there is no message for a given front end, it means
/// the error is not reported by that front end.
///
/// For analyzer errors, the error "message" is actually the constant name for
/// the error code, like "CompileTimeErrorCode.WRONG_TYPE".
class StaticError implements Comparable<StaticError> {
  static const _unspecified = "unspecified";

  /// The error codes for all of the analyzer errors that are non-fatal
  /// warnings.
  ///
  /// We can't rely on the type ("STATIC_WARNING", etc.) because for historical
  /// reasons the "warning" types contain a large number of actual compile
  /// errors.
  // TODO(rnystrom): This list was generated on 2020/07/24 based on the list
  // of error codes in sdk/pkg/analyzer/lib/error/error.dart. Is there a more
  // systematic way to handle this?
  static const _analyzerWarningCodes = {
    "STATIC_WARNING.ANALYSIS_OPTION_DEPRECATED",
    "STATIC_WARNING.INCLUDE_FILE_NOT_FOUND",
    "STATIC_WARNING.INCLUDED_FILE_WARNING",
    "STATIC_WARNING.INVALID_OPTION",
    "STATIC_WARNING.INVALID_SECTION_FORMAT",
    "STATIC_WARNING.SPEC_MODE_REMOVED",
    "STATIC_WARNING.UNRECOGNIZED_ERROR_CODE",
    "STATIC_WARNING.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE",
    "STATIC_WARNING.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES",
    "STATIC_WARNING.UNSUPPORTED_OPTION_WITHOUT_VALUES",
    "STATIC_WARNING.UNSUPPORTED_VALUE",
    "STATIC_WARNING.CAMERA_PERMISSIONS_INCOMPATIBLE",
    "STATIC_WARNING.NO_TOUCHSCREEN_FEATURE",
    "STATIC_WARNING.NON_RESIZABLE_ACTIVITY",
    "STATIC_WARNING.PERMISSION_IMPLIES_UNSUPPORTED_HARDWARE",
    "STATIC_WARNING.SETTING_ORIENTATION_ON_ACTIVITY",
    "STATIC_WARNING.UNSUPPORTED_CHROME_OS_FEATURE",
    "STATIC_WARNING.UNSUPPORTED_CHROME_OS_HARDWARE",
    "STATIC_WARNING.DEAD_NULL_AWARE_EXPRESSION",
    "STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR",
    "STATIC_WARNING.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED",
    "STATIC_WARNING.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL",
    "STATIC_WARNING.MISSING_ENUM_CONSTANT_IN_SWITCH",
    "STATIC_WARNING.UNNECESSARY_NON_NULL_ASSERTION",
    "STATIC_WARNING.TOP_LEVEL_INSTANCE_GETTER",
    "STATIC_WARNING.TOP_LEVEL_INSTANCE_METHOD",
  };

  /// Parses the set of static error expectations defined in the Dart source
  /// file [source].
  static List<StaticError> parseExpectations(String source) =>
      _ErrorExpectationParser(source)._parse();

  /// Collapses overlapping [errors] into a shorter list of errors where
  /// possible.
  ///
  /// Errors on the same location can be collapsed if none of them both define
  /// a message for the same front end.
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

        // Can't lose any messages.
        if (ErrorSource.all
            .any((source) => a.hasError(source) && b.hasError(source))) {
          continue;
        }

        // TODO(rnystrom): Now that there are more than two front ends, this
        // isn't as smart as it could be. It could try to pack all of the
        // messages in a given location into as few errors as possible by
        // taking only the non-colliding messages from one error. But that's
        // weird.
        //
        // A cleaner model is to have each StaticError represent a unique error
        // location. It would have an open-ended list of every message that
        // occurs at that location, across the various front-ends, including
        // multiple messages for the same front end. But that would change how
        // the existing static error tests look since something like:
        //
        //     // ^^^
        //     // [cfe] Message 1.
        //     // ^^^
        //     // [cfe] Message 2.
        //
        // Would turn into:
        //
        //     // ^^^
        //     // [cfe] Message 1.
        //     // [cfe] Message 2.
        //
        // That's a good change to do, but should probably wait until after
        // NNBD.

        // Merge the two errors.
        result[i] = StaticError({...a._errors, ...b._errors},
            line: a.line, column: a.column, length: a.length ?? b.length);

        // Continue trying to merge this merged error with more since multiple
        // errors might collapse into a single one.
        result.removeAt(j);
        a = result[i];
        j--;
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

      for (var source in ErrorSource.all) {
        var sourceError = error._errors[source];
        if (sourceError == _unspecified) {
          buffer.writeln("- $verb unspecified ${source.name} error.");
        } else if (sourceError != null) {
          buffer.writeln("- $verb ${source.name} error '$sourceError'.");
        }
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

  /// The error messages that should be or were reported by each front end.
  final Map<ErrorSource, String> _errors;

  /// Whether this static error exists for [source].
  bool hasError(ErrorSource source) => _errors.containsKey(source);

  /// The error for [source] or `null` if this error isn't expected to
  /// reported by that source.
  String errorFor(ErrorSource source) => _errors[source];

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
  StaticError(Map<ErrorSource, String> errors,
      {this.line,
      this.column,
      this.length,
      this.markerStartLine,
      this.markerEndLine})
      : _errors = errors {
    // Must have a location.
    assert(line != null);
    assert(column != null);

    // Must have at least one piece of description.
    assert(_errors.isNotEmpty);
  }

  /// A textual description of this error's location.
  String get location {
    var result = "line $line, column $column";
    if (length != null) result += ", length $length";
    return result;
  }

  /// Whether this error is only considered a warning on all front ends that
  /// report it.
  bool get isWarning {
    var analyzer = _errors[ErrorSource.analyzer];
    if (analyzer != null && !_analyzerWarningCodes.contains(analyzer)) {
      return false;
    }

    // TODO(42787): Once CFE starts reporting warnings, encode that in the
    // message somehow and then look for it here.
    if (hasError(ErrorSource.cfe)) return false;

    // TODO(rnystrom): If the web compilers report warnings, encode that in the
    // message somehow and then look for it here.
    if (hasError(ErrorSource.web)) return false;

    return true;
  }

  String toString() {
    var result = "Error at $location";

    for (var source in ErrorSource.all) {
      var sourceError = _errors[source];
      if (sourceError != null) {
        result += "\n[${source.name.toLowerCase()}] $sourceError";
      }
    }

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

    for (var source in ErrorSource.all) {
      var thisError = _errors[source] ?? "";
      var otherError = other._errors[source] ?? "";
      if (thisError != otherError) {
        return thisError.compareTo(otherError);
      }
    }

    return 0;
  }

  @override
  bool operator ==(other) => other is StaticError && compareTo(other) == 0;

  @override
  int get hashCode =>
      3 * line.hashCode +
      5 * column.hashCode +
      7 * (length ?? 0).hashCode +
      11 * (_errors[ErrorSource.analyzer] ?? "").hashCode +
      13 * (_errors[ErrorSource.cfe] ?? "").hashCode +
      17 * (_errors[ErrorSource.web] ?? "").hashCode;

  /// Whether this error expectation is a specified error for the front end
  /// reported by [actual].
  bool isSpecifiedFor(StaticError actual) {
    assert(actual._errors.length == 1,
        "Actual error should only have one source.");

    for (var source in ErrorSource.all) {
      if (actual.hasError(source)) {
        return hasError(source) && _errors[source] != _unspecified;
      }
    }

    return false;
  }

  /// Compares this error expectation to [actual].
  ///
  /// If this error correctly matches [actual], returns `null`. Otherwise
  /// returns a list of strings describing the mismatch.
  ///
  /// Note that this does *not* check to see that [actual] matches the front
  /// ends that this error expects. For example, if [actual] only reports an
  /// analyzer error and this error only specifies a CFE error, this will still
  /// report differences in location information. This method expects that error
  /// expectations have already been filtered by platform so this will only be
  /// called in cases where the platforms do match.
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

    for (var source in ErrorSource.all) {
      var error = _errors[source];
      var actualError = actual._errors[source];

      if (error != null &&
          error != _unspecified &&
          actualError != null &&
          error != actualError) {
        differences.add("Expected ${source.name} error '$error' "
            "but was '$actualError'.");
      }
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

  /// Matches the beginning of an error message, like `// [analyzer]`.
  static final _errorMessageRegExp = RegExp(r"^\s*// \[(\w+)\]\s*(.*)");

  /// An analyzer error code is a dotted identifier or the magic string
  /// "unspecified".
  static final _errorCodeRegExp = RegExp(r"^\w+\.\w+|unspecified$");

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
    while (_canPeek(0)) {
      var sourceLine = _peek(0);

      var match = _caretLocationRegExp.firstMatch(sourceLine);
      if (match != null) {
        if (_lastRealLine == -1) {
          _fail("An error expectation must follow some code.");
        }

        _parseErrorMessages(
            line: _lastRealLine,
            column: sourceLine.indexOf("^") + 1,
            length: match.group(1).length);
        _advance();
        continue;
      }

      match = _explicitLocationAndLengthRegExp.firstMatch(sourceLine);
      if (match != null) {
        _parseErrorMessages(
            line: int.parse(match.group(1)),
            column: int.parse(match.group(2)),
            length: int.parse(match.group(3)));
        _advance();
        continue;
      }

      match = _explicitLocationRegExp.firstMatch(sourceLine);
      if (match != null) {
        _parseErrorMessages(
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
  void _parseErrorMessages({int line, int column, int length}) {
    var errors = <ErrorSource, String>{};

    var startLine = _currentLine;

    while (_canPeek(1)) {
      var match = _errorMessageRegExp.firstMatch(_peek(1));
      if (match == null) break;

      var sourceName = match.group(1);
      var source = ErrorSource.find(sourceName);
      if (source == null) _fail("Unknown front end '[$sourceName]'.");

      var message = match.group(2);
      _advance();

      // Consume as many additional error message lines as we find.
      while (_canPeek(1)) {
        var nextLine = _peek(1);

        // A location line shouldn't be treated as part of the message.
        if (_caretLocationRegExp.hasMatch(nextLine)) break;
        if (_explicitLocationAndLengthRegExp.hasMatch(nextLine)) break;
        if (_explicitLocationRegExp.hasMatch(nextLine)) break;

        // The next source should not be treated as part of the message.
        if (_errorMessageRegExp.hasMatch(nextLine)) break;

        var messageMatch = _errorMessageRestRegExp.firstMatch(nextLine);
        if (messageMatch == null) break;

        message += "\n" + messageMatch.group(1);
        _advance();
      }

      if (source == ErrorSource.analyzer &&
          !_errorCodeRegExp.hasMatch(message)) {
        _fail("An analyzer error expectation should be a dotted identifier.");
      }

      if (errors.containsKey(source)) {
        _fail("Already have an error for ${source.name}:\n${errors[source]}");
      }

      errors[source] = message;
    }

    if (errors.isEmpty) {
      _fail("An error expectation must specify at least one error message.");
    }

    // Hack: If the error is CFE-only and the length is one, treat it as no
    // length. The CFE does not output length information, and when the update
    // tool writes a CFE-only error, it implicitly uses a length of one. Thus,
    // when we parse back in a length one CFE error, we ignore the length so
    // that the error round-trips correctly.
    // TODO(rnystrom): Stop doing this when the CFE reports error lengths.
    if (length == 1 &&
        errors.length == 1 &&
        errors.containsKey(ErrorSource.cfe)) {
      length = null;
    }

    _errors.add(StaticError(errors,
        line: line,
        column: column,
        length: length,
        markerStartLine: startLine,
        markerEndLine: _currentLine));
  }

  bool _canPeek(int offset) => _currentLine + offset < _lines.length;

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
