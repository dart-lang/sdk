// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.helpers;

/// Function signature for [trace].
typedef void Trace(String message,
                   {bool condition(String stackTrace),
                    int limit,
                    bool throwOnPrint});

/**
 * Helper method for printing stack traces for debugging.
 *
 * [message] is printed as the header of the stack trace.
 *
 * If [condition] is provided, the stack trace is only printed if [condition]
 * returns [:true:] on the stack trace text. This can be used to filter the
 * printed stack traces based on their content. For instance only print stack
 * traces that contain specific paths.
 *
 * If [limit] is provided, the stack trace is limited to [limit] entries.
 *
 * If [throwOnPrint] is `true`, [message] will be thrown after the stack trace
 * has been printed. Together with [condition] this can be used to discover
 * unknown call-sites in tests by filtering known call-sites and throwning
 * otherwise.
 */
Trace get trace {
  enableDebugMode();
  return _trace;
}

void _trace(String message, {bool condition(String stackTrace), int limit,
                             bool throwOnPrint: false}) {
  try {
    throw '';
  } catch (e, s) {
    String stackTrace;
    try {
      stackTrace = prettifyStackTrace(
          s, rangeStart: 1, rangeEnd: limit, filePrefix: stackTraceFilePrefix);
    } catch (e) {
      print(e);
      stackTrace = '$s';
    }
    if (condition != null) {
      if (!condition(stackTrace)) return;
    }
    print('$message\n$stackTrace');
    if (throwOnPrint) throw message;
  }
}

/// Function signature of [traceAndReport].
typedef void TraceAndReport(Compiler compiler, Spannable node, String message,
                            {bool condition(String stackTrace), int limit,
                             bool throwOnPrint});

/// Calls [reportHere] and [trace] with the same message.
TraceAndReport get traceAndReport {
  enableDebugMode();
  return _traceAndReport;
}

/// Calls [reportHere] and [trace] with the same message.
TraceAndReport get reportAndTrace => traceAndReport;

/// Implementation of [traceAndReport].
void _traceAndReport(Compiler compiler, Spannable node, String message,
                     {bool condition(String stackTrace), int limit,
                      bool throwOnPrint: false}) {

  trace(message, limit: limit, throwOnPrint: throwOnPrint,
        condition: (String stackTrace) {
    bool result = condition != null ? condition(stackTrace) : true;
    if (result) {
      reportHere(compiler, node, message);
    }
    return result;
  });
}

/// Returns the [StackTraceLines] for the current call stack.
///
/// Use [offset] to discard the first [offset] calls of the call stack. Defaults
/// to `1`, that is, discard the call to [stackTrace] itself. Use [limit] to
/// limit the length of the stack trace lines.
StackTraceLines stackTrace({int offset: 1,
                            int limit: null}) {
  int rangeStart = offset;
  int rangeEnd = limit == null ? null : rangeStart + limit;
  try {
    throw '';
  } catch (_, stackTrace) {
    return new StackTraceLines.fromTrace(stackTrace,
        rangeStart: offset, rangeEnd: rangeEnd,
        filePrefix: stackTraceFilePrefix);
  }
  return null;
}

/// A stack trace as a sequence of [StackTraceLine]s.
class StackTraceLines {
  final List<StackTraceLine> lines;
  final int maxFileLength;
  final int maxLineNoLength;
  final int maxColumnNoLength;

  factory StackTraceLines.fromTrace(StackTrace s,
                                    {int rangeStart,
                                     int rangeEnd,
                                     String filePrefix,
                                     String lambda: r'?'}) {
    final RegExp indexPattern = new RegExp(r'#\d+\s*');
    int index = -1;
    int maxFileLength = 0;
    int maxLineNoLength = 0;
    int maxColumnNoLength = 0;

    String stackTrace = '$s';
    List<StackTraceLine> lines = <StackTraceLine>[];
    // Parse each line in the stack trace. The supported line formats from the
    // Dart VM are:
    //    #n     <method-name> (<uri>:<line-no>:<column-no>)
    //    #n     <method-name> (<uri>:<line-no>)
    // in which '<anonymous closure>' is the name used for an (unnamed) function
    // expression.
    for (String line in stackTrace.split('\n')) {
      try {
        index++;
        if (rangeStart != null && index < rangeStart) continue;
        if (rangeEnd != null && index > rangeEnd) break;
        if (line.isEmpty) continue;

        // Strip index.
        line = line.replaceFirst(indexPattern, '');

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
        lines.add(new StackTraceLine(index, file, lineNo, columnNo, method));
      } catch (e) {
        throw 'Error prettifying "$line": $e';
      }
    }
    return new StackTraceLines.fromLines(
        lines, maxFileLength, maxLineNoLength, maxColumnNoLength);
  }

  StackTraceLines.fromLines(this.lines,
                            this.maxFileLength,
                            this.maxLineNoLength,
                            this.maxColumnNoLength);

  StackTraceLines subtrace(int offset) {
    return new StackTraceLines.fromLines(
        lines.sublist(offset),
        maxFileLength,
        maxLineNoLength,
        maxColumnNoLength);
  }

  String prettify({bool showColumnNo: false,
                   bool showDots: true}) {
    StringBuffer sb = new StringBuffer();
    bool dots = true;
    for (StackTraceLine line in lines) {
      sb.write('  ');
      line.printOn(sb,
        fileLength: maxFileLength,
        padding: showDots && dots ? ' .' : ' ',
        lineNoLength: maxLineNoLength,
        showColumnNo: showColumnNo,
        columnNoLength: maxColumnNoLength);

      dots = !dots;
    }
    return sb.toString();
  }

  String toString() {
    return prettify();
  }
}

/// A parsed line from a stack trace.
class StackTraceLine {
  final int index;
  final String file;
  final String lineNo;
  final String columnNo;
  final String method;

  StackTraceLine(this.index, this.file, this.lineNo,
                  this.columnNo, this.method);

  void printOn(StringBuffer sb,
               {String padding: ' ',
                int fileLength,
                int lineNoLength,
                int columnNoLength,
                bool showColumnNo: false}) {
    String fileText = '${file} ';
    if (fileLength != null) {
      fileText = pad(fileText, fileLength, dots: padding);
    }
    String lineNoText = lineNo;
    if (lineNoLength != null) {
      lineNoText = pad(lineNoText, lineNoLength, padLeft: true);
    }
    String columnNoText = showColumnNo ? '': columnNo;
    if (columnNoLength != null) {
        columnNoText = ':${pad(columnNoText, columnNoLength)}';
    }
    sb.write('$fileText $lineNoText$columnNoText $method\n');
  }

  int get hashCode {
    return 13 * index +
           17 * file.hashCode +
           19 * lineNo.hashCode +
           23 * columnNo.hashCode +
           29 * method.hashCode;
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! StackTraceLine) return false;
    return index == other.index &&
           file == other.file &&
           lineNo == other.lineNo &&
           columnNo == other.columnNo &&
           method == other.method;
  }

  String toString() => "$method @ $file [$lineNo:$columnNo]";
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
String prettifyStackTrace(StackTrace stackTrace,
                          {int rangeStart,
                           int rangeEnd,
                           bool showColumnNo: false,
                           bool showDots: true,
                           String filePrefix,
                           String lambda: r'?'}) {
  return new StackTraceLines.fromTrace(stackTrace,
      rangeStart: rangeStart, rangeEnd: rangeEnd,
      filePrefix: filePrefix, lambda: lambda)
    .prettify(showColumnNo: showColumnNo, showDots: showDots);
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
