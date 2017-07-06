// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:core";

// Exceptions are thrown either by the VM or from Dart code.

/**
 * A marker interface implemented by all core library exceptions.
 *
 * An [Exception] is intended to convey information to the user about a failure,
 * so that the error can be addressed programmatically. It is intended to be
 * caught, and it should contain useful data fields.
 *
 * Creating instances of [Exception] directly with [:new Exception("message"):]
 * is discouraged, and only included as a temporary measure during development,
 * until the actual exceptions used by a library are done.
 */
abstract class Exception {
  factory Exception([var message]) => new _Exception(message);
}

/** Default implementation of [Exception] which carries a message. */
class _Exception implements Exception {
  final message;

  _Exception([this.message]);

  String toString() {
    if (message == null) return "Exception";
    return "Exception: $message";
  }
}

/**
 * Exception thrown when a string or some other data does not have an expected
 * format and cannot be parsed or processed.
 */
class FormatException implements Exception {
  /**
   * A message describing the format error.
   */
  final String message;

  /**
   * The actual source input which caused the error.
   *
   * This is usually a [String], but can be other types too.
   * If it is a string, parts of it may be included in the [toString] message.
   *
   * The source is `null` if omitted or unknown.
   */
  final source;

  /**
   * The offset in [source] where the error was detected.
   *
   * A zero-based offset into the source that marks the format error causing
   * this exception to be created. If `source` is a string, this should be a
   * string index in the range `0 <= offset <= source.length`.
   *
   * If input is a string, the [toString] method may represent this offset as
   * a line and character position. The offset should be inside the string,
   * or at the end of the string.
   *
   * May be omitted. If present, [source] should also be present if possible.
   */
  final int offset;

  /**
   * Creates a new FormatException with an optional error [message].
   *
   * Optionally also supply the actual [source] with the incorrect format,
   * and the [offset] in the format where a problem was detected.
   */
  const FormatException([this.message = "", this.source, this.offset]);

  /**
   * Returns a description of the format exception.
   *
   * The description always contains the [message].
   *
   * If [source] is present and is a string, the description will contain
   * (at least a part of) the source.
   * If [offset] is also provided, the part of the source included will
   * contain that offset, and the offset will be marked.
   *
   * If the source is a string and it contains a line break before offset,
   * only the line containing offset will be included, and its line number
   * will also be part of the description. Line and character offsets are
   * 1-based.
   */
  String toString() {
    String report = "FormatException";
    if (message != null && "" != message) {
      report = "$report: $message";
    }
    int offset = this.offset;
    if (source is! String) {
      if (offset != null) {
        report += " (at offset $offset)";
      }
      return report;
    }
    if (offset != null && (offset < 0 || offset > source.length)) {
      offset = null;
    }
    // Source is string and offset is null or valid.
    if (offset == null) {
      String source = this.source;
      if (source.length > 78) {
        source = source.substring(0, 75) + "...";
      }
      return "$report\n$source";
    }
    int lineNum = 1;
    int lineStart = 0;
    bool previousCharWasCR = false;
    for (int i = 0; i < offset; i++) {
      int char = source.codeUnitAt(i);
      if (char == 0x0a) {
        if (lineStart != i || !previousCharWasCR) {
          lineNum++;
        }
        lineStart = i + 1;
        previousCharWasCR = false;
      } else if (char == 0x0d) {
        lineNum++;
        lineStart = i + 1;
        previousCharWasCR = true;
      }
    }
    if (lineNum > 1) {
      report += " (at line $lineNum, character ${offset - lineStart + 1})\n";
    } else {
      report += " (at character ${offset + 1})\n";
    }
    int lineEnd = source.length;
    for (int i = offset; i < source.length; i++) {
      int char = source.codeUnitAt(i);
      if (char == 0x0a || char == 0x0d) {
        lineEnd = i;
        break;
      }
    }
    int length = lineEnd - lineStart;
    int start = lineStart;
    int end = lineEnd;
    String prefix = "";
    String postfix = "";
    if (length > 78) {
      // Can't show entire line. Try to anchor at the nearest end, if
      // one is within reach.
      int index = offset - lineStart;
      if (index < 75) {
        end = start + 75;
        postfix = "...";
      } else if (end - offset < 75) {
        start = end - 75;
        prefix = "...";
      } else {
        // Neither end is near, just pick an area around the offset.
        start = offset - 36;
        end = offset + 36;
        prefix = postfix = "...";
      }
    }
    String slice = source.substring(start, end);
    int markOffset = offset - start + prefix.length;
    return "$report$prefix$slice$postfix\n${" " * markOffset}^\n";
  }
}

// Exception thrown when doing integer division with a zero divisor.
class IntegerDivisionByZeroException implements Exception {
  const IntegerDivisionByZeroException();
  String toString() => "IntegerDivisionByZeroException";
}
