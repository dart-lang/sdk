// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Representation of stack traces and logic to parse d8 stack traces.
// TODO(sigmund): we should delete this implementation and instead:
// - switch to use the stack_trace package
// - add support non-d8 frames
// - add support for secondary regexps to detect stranger frames (like eval frames)

import 'package:path/path.dart' as p;

import 'util.dart';

/// Represents a stack trace line.
class StackTraceLine {
  String methodName;
  String fileName;
  int lineNo;
  int columnNo;

  StackTraceLine(this.methodName, this.fileName, this.lineNo, this.columnNo);

  /// Creates a [StackTraceLine] by parsing a d8 stack trace line [text]. The
  /// expected formats are
  ///
  ///     at <methodName>(<fileName>:<lineNo>:<columnNo>)
  ///     at <methodName>(<fileName>:<lineNo>)
  ///     at <methodName>(<fileName>)
  ///     at <fileName>:<lineNo>:<columnNo>
  ///     at <fileName>:<lineNo>
  ///     at <fileName>
  ///
  factory StackTraceLine.fromText(String text, {Logger logger}) {
    text = text.trim();
    assert(text.startsWith('at '));
    text = text.substring('at '.length);
    String methodName;
    int endParen = text.indexOf(')');
    if (endParen > 0) {
      int nameEnd = text.indexOf('(');
      if (nameEnd != -1) {
        methodName = text.substring(0, nameEnd).trim();
        text = text.substring(nameEnd + 1, endParen).trim();
      } else {
        logger?.log('Missing left-paren in: $text');
      }
    }
    int lineNo;
    int columnNo;
    String fileName;
    int lastColon = text.lastIndexOf(':');
    if (lastColon != -1) {
      int lastValue = int.tryParse(text.substring(lastColon + 1));
      if (lastValue != null) {
        int secondToLastColon = text.lastIndexOf(':', lastColon - 1);
        if (secondToLastColon != -1) {
          int secondToLastValue =
              int.tryParse(text.substring(secondToLastColon + 1, lastColon));
          if (secondToLastValue != null) {
            lineNo = secondToLastValue;
            columnNo = lastValue;
            fileName = text.substring(0, secondToLastColon);
          } else {
            lineNo = lastValue;
            fileName = text.substring(0, lastColon);
          }
        } else {
          lineNo = lastValue;
          fileName = text.substring(0, lastColon);
        }
      } else {
        fileName = text;
      }
    } else {
      fileName = text;
    }
    return new StackTraceLine(methodName, fileName, lineNo, columnNo ?? 1);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('  at ');
    if (methodName != null) {
      sb.write(methodName);
      sb.write(' (');
      sb.write(fileName ?? '?');
      sb.write(':');
      sb.write(lineNo);
      sb.write(':');
      sb.write(columnNo);
      sb.write(')');
    } else {
      sb.write(fileName ?? '?');
      sb.write(':');
      sb.write(lineNo);
      sb.write(':');
      sb.write(columnNo);
    }
    return sb.toString();
  }

  String get inlineString {
    StringBuffer sb = new StringBuffer();
    var padding = 20;
    if (methodName != null) {
      sb.write(methodName);
      padding -= (methodName.length);
      if (padding <= 0) {
        sb.write('\n');
        padding = 20;
      }
    }
    sb.write(' ' * padding);
    if (fileName != null) {
      sb.write(p.url.basename(fileName));
      sb.write(' ');
      sb.write(lineNo);
      sb.write(':');
      sb.write(columnNo);
    }
    return sb.toString();
  }
}

List<StackTraceLine> parseStackTrace(String trace, {Logger logger}) {
  List<String> lines = trace.split(new RegExp(r'(\r|\n|\r\n)'));
  List<StackTraceLine> jsStackTrace = <StackTraceLine>[];
  for (String line in lines) {
    line = line.trim();
    if (line.startsWith('at ')) {
      jsStackTrace.add(new StackTraceLine.fromText(line, logger: logger));
    }
  }
  return jsStackTrace;
}

/// Returns the portion of the output that corresponds to the error message.
///
/// Note: some errors can span multiple lines.
String extractErrorMessage(String trace) {
  var firstStackFrame = trace.indexOf(new RegExp('\n +at'));
  if (firstStackFrame == -1) return null;
  var errorMarker = trace.indexOf('^') + 1;
  return trace.substring(errorMarker, firstStackFrame).trim();
}
