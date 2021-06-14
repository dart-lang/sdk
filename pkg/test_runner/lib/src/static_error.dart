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

  /// Pseudo-front end for context messages.
  static const context = ErrorSource._("context");

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

    if (name == "context") return context;

    return null;
  }

  /// A user readable name for the error source.
  final String name;

  /// The string used to mark errors from this source in test files.
  String get marker => name.toLowerCase();

  const ErrorSource._(this.name);
}

/// Describes a single static error reported by a single front end at a specific
/// location.
///
/// These can be parsed from comments in [TestFile]s, in which case they
/// represent *expected* errors. If a test contains any of these, then it is a
/// "static error test" and exists to validate that a conforming front end
/// produces the expected compile-time errors. This same class is also used for
/// *reported* errors when parsing the output of a front end.
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

  /// Determines whether all [actualErrors] match the given [expectedErrors].
  ///
  /// If they match, returns `null`. Otherwise returns a string describing the
  /// mismatches. This is a human-friendly explanation of the difference
  /// between the two sets of errors, while also being simple to implement.
  /// An expected error that is completely identical to an actual error is
  /// treated as a match. Everything else is a failure.
  ///
  /// It has a few heuristics to try to determine what the discrepancies mean,
  /// which it applies in order:
  ///
  /// *   If it sees an actual errors with the same message but different
  ///     location as expected ones, it considers those to be the same error
  ///     but with the wrong location.
  ///
  /// *   If it sees an actual errors at the same location as expected ones,
  ///     it considers those to be wrong messages.
  ///
  /// *   Otherwise, any remaining expected errors are considered missing
  ///     errors and remaining actual errors are considered unexpected.
  ///
  /// Also describes any mismatches between the context messages in the expected
  /// and actual errors.
  static String validateExpectations(Iterable<StaticError> expectedErrors,
      Iterable<StaticError> actualErrors) {
    var expected = expectedErrors.toList();
    var actual = actualErrors.toList();

    // Put them in a deterministic order.
    expected.sort();
    actual.sort();

    var buffer = StringBuffer();

    // Pair up errors by location and message.
    for (var i = 0; i < expected.length; i++) {
      var matchedExpected = false;

      for (var j = 0; j < actual.length; j++) {
        if (actual[j] == null) continue;

        if (expected[i]._matchMessage(actual[j]) &&
            expected[i]._matchLocation(actual[j])) {
          // Report any mismatches in the context messages.
          expected[i]._validateContext(actual[j], buffer);

          actual[j] = null;
          matchedExpected = true;

          // If the expected error is unspecified, keep going so that it can
          // consume multiple errors on the same line.
          if (expected[i].isSpecified) break;
        }
      }

      if (matchedExpected) expected[i] = null;
    }

    expected.removeWhere((error) => error == null);
    actual.removeWhere((error) => error == null);

    // If every error was paired up, and the contexts matched, we're done.
    if (expected.isEmpty && actual.isEmpty && buffer.isEmpty) return null;

    void fail(StaticError error, String label, String contextLabel,
        [String secondary]) {
      if (error.isContext) label = contextLabel;

      if (error.isSpecified) {
        buffer.writeln("- $label ${error.location}: ${error.message}");
      } else {
        label = label.replaceAll("error", "unspecified error");
        buffer.writeln("- $label ${error.location}.");
      }

      if (secondary != null) buffer.writeln("  $secondary");
      buffer.writeln();
    }

    // Look for matching messages, which means a wrong location.
    for (var i = 0; i < expected.length; i++) {
      if (expected[i] == null) continue;

      for (var j = 0; j < actual.length; j++) {
        if (actual[j] == null) continue;

        if (expected[i].message == actual[j].message) {
          fail(expected[i], "Wrong error location", "Wrong context location",
              expected[i]._locationError(actual[j]));
          // Report any mismatches in the context messages.
          expected[i]._validateContext(actual[j], buffer);

          // Only report this mismatch once.
          expected[i] = null;
          actual[j] = null;
          break;
        }
      }
    }

    // Look for matching locations, which means a wrong message.
    for (var i = 0; i < expected.length; i++) {
      if (expected[i] == null) continue;
      for (var j = 0; j < actual.length; j++) {
        if (actual[j] == null) continue;

        if (expected[i]._matchLocation(actual[j])) {
          fail(actual[j], "Wrong message at", "Wrong context message at",
              "Expected: ${expected[i].message}");
          // Report any mismatches in the context messages.
          expected[i]._validateContext(actual[j], buffer);

          // Only report this mismatch once.
          expected[i] = null;
          actual[j] = null;
          break;
        }
      }
    }

    // Any remaining expected errors are missing.
    for (var i = 0; i < expected.length; i++) {
      if (expected[i] == null) continue;
      fail(expected[i], "Missing expected error at",
          "Missing expected context message at");
    }

    // Any remaining actual errors are unexpected.
    for (var j = 0; j < actual.length; j++) {
      if (actual[j] == null) continue;
      fail(actual[j], "Unexpected error at", "Unexpected context message at");
    }

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

  /// The front end this error is for.
  final ErrorSource source;

  final String message;

  /// Additional context messages associated with this error.
  final List<StaticError> contextMessages = [];

  /// The zero-based numbers of the lines in the [TestFile] containing comments
  /// that were parsed to produce this error.
  ///
  /// This includes a line for the location comment, as well as lines for the
  /// error message. Note that lines may not be contiguous and multiple errors
  /// may share the same line number for a shared location marker.
  final Set<int> sourceLines;

  /// Creates a new StaticError at the given location with the given expected
  /// error code and message.
  ///
  /// In order to make it easier to incrementally add error tests before a
  /// feature is fully implemented or specified, an error expectation can be in
  /// an "unspecified" state for either or both platforms by having the error
  /// code or message be the special string "unspecified". When an unspecified
  /// error is tested, a front end is expected to report *some* error on that
  /// error's line, but it can be any location, error code, or message.
  StaticError(this.source, this.message,
      {this.line, this.column, this.length, Set<int> sourceLines})
      : sourceLines = {...?sourceLines} {
    // Must have a location.
    assert(line != null);
    assert(column != null);
  }

  /// A textual description of this error's location.
  String get location {
    var result = "line $line, column $column";
    if (length != null) result += ", length $length";
    return result;
  }

  /// True if this error has a specific expected message and location.
  ///
  /// Otherwise, it is an "unspecified error", which means that as long as some
  /// actual error is reported on this error's line, then the expectation is
  /// met.
  bool get isSpecified => message != _unspecified;

  /// Whether this is a context message instead of an error.
  bool get isContext => source == ErrorSource.context;

  /// Whether this error is only considered a warning on all front ends that
  /// report it.
  bool get isWarning {
    switch (source) {
      case ErrorSource.analyzer:
        return _analyzerWarningCodes.contains(message);
      case ErrorSource.cfe:
        // TODO(42787): Once CFE starts reporting warnings, encode that in the
        // message somehow and then look for it here.
        return false;
      case ErrorSource.web:
        // TODO(rnystrom): If the web compilers report warnings, encode that in
        // the message somehow and then look for it here.
        return false;
    }

    throw FallThroughError();
  }

  String toString() {
    var buffer = StringBuffer("StaticError(");
    buffer.write("line: $line, column: $column");
    if (length != null) buffer.write(", length: $length");
    buffer.write(", message: '$message'");

    if (contextMessages.isNotEmpty) {
      buffer.write(", context: [ ");
      buffer.writeAll(contextMessages, ", ");
      buffer.write(" ]");
    }

    buffer.write(")");
    return buffer.toString();
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

    if (source != other.source) {
      return source.marker.compareTo(other.source.marker);
    }

    return message.compareTo(other.message);
  }

  @override
  bool operator ==(other) {
    if (other is StaticError) {
      if (compareTo(other) != 0) return false;

      if (contextMessages.length != other.contextMessages.length) return false;
      for (var i = 0; i < contextMessages.length; i++) {
        if (contextMessages[i] != other.contextMessages[i]) return false;
      }

      return true;
    }

    return false;
  }

  @override
  int get hashCode =>
      3 * line.hashCode +
      5 * column.hashCode +
      7 * (length ?? 0).hashCode +
      11 * source.hashCode +
      13 * message.hashCode;

  /// Returns true if [actual]'s message matches this one.
  ///
  /// Takes unspecified errors into account.
  bool _matchMessage(StaticError actual) {
    return !isSpecified || message == actual.message;
  }

  /// Returns true if [actual]'s location matches this one.
  ///
  /// Takes into account unspecified errors and errors without lengths.
  bool _matchLocation(StaticError actual) {
    if (line != actual.line) return false;

    // Ignore column and length for unspecified errors.
    if (isSpecified) {
      if (column != actual.column) return false;
      if (actual.length != null && length != actual.length) return false;
    }

    return true;
  }

  /// Returns a string describing how this error's expected location differs
  /// from [actual].
  String _locationError(StaticError actual) {
    var expectedMismatches = <String>[];
    var actualMismatches = <String>[];

    if (line != actual.line) {
      expectedMismatches.add("line $line");
      actualMismatches.add("line ${actual.line}");
    }

    // Ignore column and length for unspecified errors.
    if (isSpecified) {
      if (column != actual.column) {
        expectedMismatches.add("column $column");
        actualMismatches.add("column ${actual.column}");
      }

      if (actual.length != null && length != actual.length) {
        expectedMismatches.add("length $length");
        actualMismatches.add("length ${actual.length}");
      }
    }

    // Should only call this when the locations don't match.
    assert(expectedMismatches.isNotEmpty);

    var expectedList = expectedMismatches.join(", ");
    var actualList = actualMismatches.join(", ");
    return "Expected $expectedList but was $actualList.";
  }

  /// Validates that this expected error's context messages match [actual]'s.
  ///
  /// Writes any mismatch errors to [buffer].
  void _validateContext(StaticError actual, StringBuffer buffer) {
    // If the expected error has no context, then ignore actual context
    // messages.
    if (contextMessages.isEmpty) return;

    var result = validateExpectations(contextMessages, actual.contextMessages);
    if (result != null) {
      buffer.writeln(result);
      buffer.writeln();
    }
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
  ///
  /// or implicitly on the previous line
  ///
  ///     // [error column 17, length 3]
  static final _explicitLocationAndLengthRegExp = RegExp(
      r"^\s*//\s*\[\s*error (?:line\s+(\d+)\s*,)?\s*column\s+(\d+)\s*,\s*"
      r"length\s+(\d+)\s*\]\s*$");

  /// Matches an explicit error location without a length, like:
  ///
  ///     // [error line 1, column 17]
  ///
  /// or implicitly on the previous line.
  ///
  ///     // [error column 17]
  static final _explicitLocationRegExp = RegExp(
      r"^\s*//\s*\[\s*error (?:line\s+(\d+)\s*,)?\s*column\s+(\d+)\s*\]\s*$");

  /// Matches the beginning of an error message, like `// [analyzer]`.
  ///
  /// May have an optional number like `// [cfe 32]`.
  static final _errorMessageRegExp =
      RegExp(r"^\s*// \[(\w+)(\s+\d+)?\]\s*(.*)");

  /// An analyzer error code is a dotted identifier or the magic string
  /// "unspecified".
  static final _errorCodeRegExp = RegExp(r"^\w+\.\w+|unspecified$");

  /// Any line-comment-only lines after the first line of a CFE error message
  /// are part of it.
  static final _errorMessageRestRegExp = RegExp(r"^\s*//\s*(.*)");

  final List<String> _lines;
  final List<StaticError> _errors = [];

  /// The parsed context messages.
  ///
  /// Once parsing is done, these are added to the errors that own them.
  final List<StaticError> _contextMessages = [];

  /// For errors that have a number associated with them, tracks that number.
  ///
  /// These are used after parsing to attach context messages to their errors.
  ///
  /// Note: if the same context message appears multiple times at the same
  /// location, there will be distinct (non-identical) StaticError instances
  /// that compare equal.  We use `Map.identity` to ensure that we can associate
  /// each with its own context number.
  final Map<StaticError, int> _errorNumbers = Map.identity();

  int _currentLine = 0;

  // One-based index of the last line that wasn't part of an error expectation.
  int _lastRealLine = -1;

  _ErrorExpectationParser(String source) : _lines = source.split("\n");

  List<StaticError> _parse() {
    // Read all the lines.
    while (_canPeek(0)) {
      var sourceLine = _peek(0);

      var match = _caretLocationRegExp.firstMatch(sourceLine);
      if (match != null) {
        if (_lastRealLine == -1) {
          _fail("An error expectation must follow some code.");
        }

        _parseErrors(
            line: _lastRealLine,
            column: sourceLine.indexOf("^") + 1,
            length: match[1].length);
        _advance();
        continue;
      }

      match = _explicitLocationAndLengthRegExp.firstMatch(sourceLine);
      if (match != null) {
        var lineCapture = match[1];
        _parseErrors(
            line: lineCapture == null ? _lastRealLine : int.parse(lineCapture),
            column: int.parse(match[2]),
            length: int.parse(match[3]));
        _advance();
        continue;
      }

      match = _explicitLocationRegExp.firstMatch(sourceLine);
      if (match != null) {
        var lineCapture = match[1];
        _parseErrors(
            line: lineCapture == null ? _lastRealLine : int.parse(lineCapture),
            column: int.parse(match[2]));
        _advance();
        continue;
      }

      _lastRealLine = _currentLine + 1;
      _advance();
    }

    _attachContext();
    return _errors;
  }

  /// Finishes parsing a series of error expectations after parsing a location.
  void _parseErrors({int line, int column, int length}) {
    var locationLine = _currentLine;
    var parsedError = false;

    // Allow errors for multiple front-ends to share the same location marker.
    while (_canPeek(1)) {
      var match = _errorMessageRegExp.firstMatch(_peek(1));
      if (match == null) break;

      var number = match[2] != null ? int.parse(match[2]) : null;

      var sourceName = match[1];
      var source = ErrorSource.find(sourceName);
      if (source == null) _fail("Unknown front end '[$sourceName]'.");
      if (source == ErrorSource.context && number == null) {
        _fail("Context messages must have an error number.");
      }

      var message = match[3];
      _advance();
      var sourceLines = {locationLine, _currentLine};

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

        message += "\n" + messageMatch[1];
        _advance();
        sourceLines.add(_currentLine);
      }

      if (source == ErrorSource.analyzer &&
          !_errorCodeRegExp.hasMatch(message)) {
        _fail("An analyzer error expectation should be a dotted identifier.");
      }

      // Hack: If the error is CFE-only and the length is one, treat it as no
      // length. The CFE does not output length information, and when the update
      // tool writes a CFE-only error, it implicitly uses a length of one. Thus,
      // when we parse back in a length one CFE error, we ignore the length so
      // that the error round-trips correctly.
      // TODO(rnystrom): Stop doing this when the CFE reports error lengths.
      var errorLength = length;
      if (errorLength == 1 && source == ErrorSource.cfe) {
        errorLength = null;
      }

      var error = StaticError(source, message,
          line: line,
          column: column,
          length: errorLength,
          sourceLines: sourceLines);

      if (number != null) {
        // Make sure two errors don't claim the same number.
        if (source != ErrorSource.context) {
          var existingError = _errors.firstWhere(
              (error) => _errorNumbers[error] == number,
              orElse: () => null);
          if (existingError != null) {
            _fail("Already have an error with number $number.");
          }
        }

        _errorNumbers[error] = number;
      }

      if (source == ErrorSource.context) {
        _contextMessages.add(error);
      } else {
        _errors.add(error);
      }

      parsedError = true;
    }

    if (!parsedError) {
      _fail("An error expectation must specify at least one error message.");
    }
  }

  /// Attach context messages to their errors and validate that everything lines
  /// up.
  void _attachContext() {
    for (var contextMessage in _contextMessages) {
      var number = _errorNumbers[contextMessage];

      var error = _errors.firstWhere((error) => _errorNumbers[error] == number,
          orElse: () => null);
      if (error == null) {
        throw FormatException("No error with number $number for context "
            "message '${contextMessage.message}'.");
      }

      error.contextMessages.add(contextMessage);
    }

    // Make sure every numbered error does have some context, otherwise the
    // number is pointless.
    for (var error in _errors) {
      var number = _errorNumbers[error];
      if (number == null) continue;

      var context = _contextMessages.firstWhere(
          (context) => _errorNumbers[context] == number,
          orElse: () => null);
      if (context == null) {
        throw FormatException("Missing context for numbered error $number "
            "'${error.message}'.");
      }
    }
  }

  bool _canPeek(int offset) => _currentLine + offset < _lines.length;

  void _advance() {
    _currentLine++;
  }

  String _peek(int offset) {
    var line = _lines[_currentLine + offset];

    // Strip off any multitest marker.
    var index = line.indexOf("//#");
    if (index != -1) {
      line = line.substring(0, index).trimRight();
    }

    return line;
  }

  void _fail(String message) {
    throw FormatException("Test error on line ${_currentLine + 1}: $message");
  }
}
