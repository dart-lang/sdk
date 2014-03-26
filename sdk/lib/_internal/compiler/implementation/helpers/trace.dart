// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.helpers;

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

void traceAndReport(Compiler compiler, Spannable node,
                    String message, [bool condition(String stackTrace)]) {

  trace(message, (String stackTrace) {
    bool result = condition != null ? condition(stackTrace) : true;
    if (result) {
      reportHere(compiler, node, message);
    }
    return result;
  });
}

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
