// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library for parsing strings using a sequence of patterns.
library string_scanner;

import 'dart:math' as math;

/// When compiled to JS, forward slashes are always escaped in [RegExp.pattern].
///
/// See issue 17998.
final _slashAutoEscape = new RegExp("/").pattern == "\\/";

// TODO(nweiz): Add some integration between this and source maps.
/// A class that scans through a string using [Pattern]s.
class StringScanner {
  /// The string being scanned through.
  final String string;

  /// The current position of the scanner in the string, in characters.
  int get position => _position;
  set position(int position) {
    if (position < 0 || position > string.length) {
      throw new ArgumentError("Invalid position $position");
    }

    _position = position;
  }
  int _position = 0;

  /// The data about the previous match made by the scanner.
  ///
  /// If the last match failed, this will be `null`.
  Match get lastMatch => _lastMatch;
  Match _lastMatch;

  /// The portion of the string that hasn't yet been scanned.
  String get rest => string.substring(position);

  /// Whether the scanner has completely consumed [string].
  bool get isDone => position == string.length;

  /// Creates a new [StringScanner] that starts scanning from [position].
  ///
  /// [position] defaults to 0, the beginning of the string.
  StringScanner(this.string, {int position}) {
    if (position != null) this.position = position;
  }

  /// If [pattern] matches at the current position of the string, scans forward
  /// until the end of the match.
  ///
  /// Returns whether or not [pattern] matched.
  bool scan(Pattern pattern) {
    var success = matches(pattern);
    if (success) _position = _lastMatch.end;
    return success;
  }

  /// If [pattern] matches at the current position of the string, scans forward
  /// until the end of the match.
  ///
  /// If [pattern] did not match, throws a [FormatException] describing the
  /// position of the failure. [name] is used in this error as the expected name
  /// of the pattern being matched; if it's `null`, the pattern itself is used
  /// instead.
  void expect(Pattern pattern, {String name}) {
    if (scan(pattern)) return;

    if (name == null) {
      if (pattern is RegExp) {
        var source = pattern.pattern;
        if (!_slashAutoEscape) source = source.replaceAll("/", "\\/");
        name = "/$source/";
      } else {
        name = pattern.toString()
            .replaceAll("\\", "\\\\").replaceAll('"', '\\"');
        name = '"$name"';
      }
    }
    _fail(name);
  }

  /// If the string has not been fully consumed, this throws a
  /// [FormatException].
  void expectDone() {
    if (isDone) return;
    _fail("no more input");
  }

  /// Returns whether or not [pattern] matches at the current position of the
  /// string.
  ///
  /// This doesn't move the scan pointer forward.
  bool matches(Pattern pattern) {
    _lastMatch = pattern.matchAsPrefix(string, position);
    return _lastMatch != null;
  }

  /// Throws a [FormatException] with [message] as well as a detailed
  /// description of the location of the error in the string.
  ///
  /// [match] is the match information for the span of the string with which the
  /// error is associated. This should be a match returned by this scanner's
  /// [lastMatch] property. By default, the error is associated with the last
  /// match.
  ///
  /// If [position] and/or [length] are passed, they are used as the error span
  /// instead. If only [length] is passed, [position] defaults to the current
  /// position; if only [position] is passed, [length] defaults to 1.
  ///
  /// It's an error to pass [match] at the same time as [position] or [length].
  void error(String message, {Match match, int position, int length}) {
    if (match != null && (position != null || length != null)) {
      throw new ArgumentError("Can't pass both match and position/length.");
    }

    if (position != null && position < 0) {
      throw new RangeError("position must be greater than or equal to 0.");
    }

    if (length != null && length < 1) {
      throw new RangeError("length must be greater than or equal to 0.");
    }

    if (match == null && position == null && length == null) match = lastMatch;
    if (position == null) {
      position = match == null ? this.position : match.start;
    }
    if (length == null) length = match == null ? 1 : match.end - match.start;

    var newlines = "\n".allMatches(string.substring(0, position)).toList();
    var line = newlines.length + 1;
    var column;
    var lastLine;
    if (newlines.isEmpty) {
      column = position + 1;
      lastLine = string.substring(0, position);
    } else {
      column = position - newlines.last.end + 1;
      lastLine = string.substring(newlines.last.end, position);
    }

    var remaining = string.substring(position);
    var nextNewline = remaining.indexOf("\n");
    if (nextNewline == -1) {
      lastLine += remaining;
    } else {
      length = math.min(length, nextNewline);
      lastLine += remaining.substring(0, nextNewline);
    }

    var spaces = new List.filled(column - 1, ' ').join();
    var underline = new List.filled(length, '^').join();

    throw new FormatException(
        "Error on line $line, column $column: $message\n"
        "$lastLine\n"
        "$spaces$underline");
  }

  // TODO(nweiz): Make this handle long lines more gracefully.
  /// Throws a [FormatException] describing that [name] is expected at the
  /// current position in the string.
  void _fail(String name) {
    error("expected $name.", position: this.position, length: 1);
  }
}
