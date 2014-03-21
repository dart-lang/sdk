// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.util;

import "dart:collection";
import 'util_implementation.dart';
import 'characters.dart';

export 'setlet.dart';

part 'link.dart';
part 'expensive_map.dart';
part 'expensive_set.dart';

/**
 * Tagging interface for classes from which source spans can be generated.
 */
// TODO(johnniwinther): Find a better name.
// TODO(ahe): How about "Bolt"?
abstract class Spannable {}

class _SpannableSentinel implements Spannable {
  final String name;

  const _SpannableSentinel(this.name);

  String toString() => name;
}

/// Sentinel spannable used to mark that diagnostics should point to the
/// current element. Note that the diagnostic reporting will fail if the current
/// element is `null`.
const Spannable CURRENT_ELEMENT_SPANNABLE =
    const _SpannableSentinel("Current element");

/// Sentinel spannable used to mark that there might be no location for the
/// diagnostic. Use this only when it is not an error not to have a current
/// element.
const Spannable NO_LOCATION_SPANNABLE =
    const _SpannableSentinel("No location");

class SpannableAssertionFailure {
  final Spannable node;
  final String message;
  SpannableAssertionFailure(this.node, this.message);

  String toString() => 'Assertion failure'
                       '${message != null ? ': $message' : ''}';
}

/**
 * Helper method for printing stack traces for debugging.
 *
 * [message] is printed as the header of the stack trace.
 *
 * If [condition] is provided, the stack trace is only printed if [condition]
 * returns [:true:] on the stack trace text. This can be used to filter the
 * printed stack traces based on their content. For instance only print stack
 * traces that contain specific paths.
 */
void trace(String message, [bool condition(String stackTrace)]) {
  try {
    throw '';
  } catch (e, s) {
    String stackTrace = prettifyStackTrace(
        s, rangeStart: 1, filePrefix: stackTraceFilePrefix);
    if (condition != null) {
      if (!condition(stackTrace)) return;
    }
    print('$message\n$stackTrace');
  }
}

/**
 * File name prefix used to shorten the file name in stack traces printed by
 * [trace].
 */
String stackTraceFilePrefix = null;

/// Helper class for the processing of stack traces in [prettifyStackTrace].
class _StackTraceLine {
  final int index;
  final String file;
  final String lineNo;
  final String columnNo;
  final String method;

  _StackTraceLine(this.index, this.file, this.lineNo,
                  this.columnNo, this.method);

  String toString() {
    return 'index=$index, file=$file, '
           'lineNo=$lineNo, columnNo=$columnNo, method=$method';
  }
}

// TODO(johnniwinther): Use this format for --throw-on-error.
/**
 * Converts the normal VM stack trace into a more compact and readable format.
 *
 * The output format is [: <file> . . . <lineNo>:<columnNo> <method> :] where
 * [: <file> :] is file name, [: <lineNo> :] is the line number,
 * [: <columnNo> :] is the column number, and [: <method> :] is the method name.
 *
 * If [rangeStart] and/or [rangeEnd] are provided, only the lines within the
 * range are included.
 * If [showColumnNo] is [:false:], the [: :<columnNo> :] part is omitted.
 * If [showDots] is [:true:], the space between [: <file> :] and [: <lineNo> :]
 * is padded with dots on every other line.
 * If [filePrefix] is provided, then for  every file name thats starts with
 * [filePrefix] only the remainder is printed.
 * If [lambda] is non-null, anonymous closures are printed as [lambda].
 */
String prettifyStackTrace(StackTrace s,
                          {int rangeStart,
                           int rangeEnd,
                           bool showColumnNo: false,
                           bool showDots: true,
                           String filePrefix,
                           String lambda: r'?'}) {
  int index = -1;
  int maxFileLength = 0;
  int maxLineNoLength = 0;
  int maxColumnNoLength = 0;

  String stackTrace = '$s';
  List<_StackTraceLine> lines = <_StackTraceLine>[];
  for (String line in stackTrace.split('\n')) {
    try {
      index++;
      if (rangeStart != null && index < rangeStart) continue;
      if (rangeEnd != null && index > rangeEnd) continue;
      if (line.isEmpty) continue;

      // Strip index.
      line = line.replaceFirst(new RegExp(r'#\d+\s*'), '');

      int leftParenPos = line.indexOf('(');
      int rightParenPos = line.indexOf(')', leftParenPos);
      int lastColon = line.lastIndexOf(':', rightParenPos);
      int nextToLastColon = line.lastIndexOf(':', lastColon-1);

      String lineNo;
      String columnNo;
      if (nextToLastColon != -1) {
        lineNo = line.substring(nextToLastColon+1, lastColon);
        columnNo = line.substring(lastColon+1, rightParenPos);
        try {
          int.parse(lineNo);
        } on FormatException catch (e) {
          lineNo = columnNo;
          columnNo = '';
          nextToLastColon = lastColon;
        }
      } else {
        lineNo = line.substring(lastColon+1, rightParenPos);
        columnNo = '';
        nextToLastColon = lastColon;
      }

      if (lineNo.length > maxLineNoLength) {
        maxLineNoLength = lineNo.length;
      }
      if (columnNo.length > maxColumnNoLength) {
        maxColumnNoLength = columnNo.length;
      }

      String file = line.substring(leftParenPos+1, nextToLastColon);
      if (filePrefix != null && file.startsWith(filePrefix)) {
        file = file.substring(filePrefix.length);
      }
      if (file.length > maxFileLength) {
        maxFileLength = file.length;
      }
      String method = line.substring(0, leftParenPos-1);
      if (lambda != null) {
        method = method.replaceAll('<anonymous closure>', lambda);
      }
      lines.add(new _StackTraceLine(index, file, lineNo, columnNo, method));
    } catch (e) {
      print('Error prettifying "$line": $e');
      return stackTrace;
    }
  }

  StringBuffer sb = new StringBuffer();
  bool dots = true;
  for (_StackTraceLine line in lines) {
    String file = pad('${line.file} ', maxFileLength,
                      dots: showDots && dots ? ' .' : ' ');
    String lineNo = pad(line.lineNo, maxLineNoLength, padLeft: true);
    String columnNo =
        showColumnNo ? ':${pad(line.columnNo, maxColumnNoLength)}' : '';
    String method = line.method;
    sb.write('  $file $lineNo$columnNo $method\n');
    dots = !dots;
  }
  return sb.toString();
}

/**
 * Pads (or truncates) [text] to the [intendedLength].
 *
 * If [padLeft] is [:true:] the text is padding inserted to the left of [text].
 * A repetition of the [dots] text is used for padding.
 */
String pad(String text, int intendedLength,
           {bool padLeft: false, String dots: ' '}) {
  if (text.length == intendedLength) return text;
  if (text.length > intendedLength) return text.substring(0, intendedLength);
  if (dots == null || dots.isEmpty) dots = ' ';
  int dotsLength = dots.length;
  StringBuffer sb = new StringBuffer();
  if (!padLeft) {
    sb.write(text);
  }
  for (int index = text.length ; index < intendedLength ; index ++) {
    int dotsIndex = index % dotsLength;
    sb.write(dots.substring(dotsIndex, dotsIndex + 1));
  }
  if (padLeft) {
    sb.write(text);
  }
  return sb.toString();
}

/// Writes the characters of [string] on [buffer].  The characters
/// are escaped as suitable for JavaScript and JSON.  [buffer] is
/// anything which supports [:write:] and [:writeCharCode:], for example,
/// [StringBuffer].  Note that JS supports \xnn and \unnnn whereas JSON only
/// supports the \unnnn notation.  Therefore we use the \unnnn notation.
void writeJsonEscapedCharsOn(String string, buffer) {
  void addCodeUnitEscaped(var buffer, int code) {
    assert(code < 0x10000);
    buffer.write(r'\u');
    if (code < 0x1000) {
      buffer.write('0');
      if (code < 0x100) {
        buffer.write('0');
        if (code < 0x10) {
          buffer.write('0');
        }
      }
    }
    buffer.write(code.toRadixString(16));
  }

  void writeEscapedOn(String string, var buffer) {
    for (int i = 0; i < string.length; i++) {
      int code = string.codeUnitAt(i);
      if (code == $DQ) {
        buffer.write(r'\"');
      } else if (code == $TAB) {
        buffer.write(r'\t');
      } else if (code == $LF) {
        buffer.write(r'\n');
      } else if (code == $CR) {
        buffer.write(r'\r');
      } else if (code == $DEL) {
        addCodeUnitEscaped(buffer, $DEL);
      } else if (code == $LS) {
        // This Unicode line terminator and $PS are invalid in JS string
        // literals.
        addCodeUnitEscaped(buffer, $LS);  // 0x2028.
      } else if (code == $PS) {
        addCodeUnitEscaped(buffer, $PS);  // 0x2029.
      } else if (code == $BACKSLASH) {
        buffer.write(r'\\');
      } else {
        if (code < 0x20) {
          addCodeUnitEscaped(buffer, code);
          // We emit DEL (ASCII 0x7f) as an escape because it would be confusing
          // to have it unescaped in a string literal.  We also escape
          // everything above 0x7f because that means we don't have to worry
          // about whether the web server serves it up as Latin1 or UTF-8.
        } else if (code < 0x7f) {
          buffer.writeCharCode(code);
        } else {
          // This will output surrogate pairs in the form \udxxx\udyyy, rather
          // than the more logical \u{zzzzzz}.  This should work in JavaScript
          // (especially old UCS-2 based implementations) and is the only
          // format that is allowed in JSON.
          addCodeUnitEscaped(buffer, code);
        }
      }
    }
  }

  for (int i = 0; i < string.length; i++) {
    int code = string.codeUnitAt(i);
    if (code < 0x20 || code == $DEL || code == $DQ || code == $LS ||
        code == $PS || code == $BACKSLASH || code >= 0x80) {
      writeEscapedOn(string, buffer);
      return;
    }
  }
  buffer.write(string);
}

int computeHashCode(part1, [part2, part3, part4, part5]) {
  return (part1.hashCode
          ^ part2.hashCode
          ^ part3.hashCode
          ^ part4.hashCode
          ^ part5.hashCode) & 0x3fffffff;
}
