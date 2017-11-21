// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:source_maps/source_maps.dart';
import 'package:source_maps/src/utils.dart';

import 'annotated_code_helper.dart';

const String EXCEPTION_MARKER = '>ExceptionMarker<';
const String INPUT_FILE_NAME = 'in.dart';

class Test {
  final String code;
  final Map<String, Expectations> expectationMap;

  Test(this.code, this.expectationMap);
}

class Expectations {
  final List<StackTraceLine> expectedLines;
  final List<StackTraceLine> unexpectedLines;

  Expectations(this.expectedLines, this.unexpectedLines);
}

/// Convert the annotated [code] to a [Test] object using [configs] to split
/// the annotations by prefix.
Test processTestCode(String code, Iterable<String> configs) {
  AnnotatedCode annotatedCode =
      new AnnotatedCode.fromText(code, commentStart, commentEnd);

  Map<String, Expectations> expectationMap = <String, Expectations>{};

  splitByPrefixes(annotatedCode, configs)
      .forEach((String config, AnnotatedCode annotatedCode) {
    Map<int, StackTraceLine> stackTraceMap = <int, StackTraceLine>{};
    List<StackTraceLine> unexpectedLines = <StackTraceLine>[];

    for (Annotation annotation in annotatedCode.annotations) {
      String text = annotation.text;
      int colonIndex = text.indexOf(':');
      String indexText = text.substring(0, colonIndex);
      String methodName = text.substring(colonIndex + 1);
      StackTraceLine stackTraceLine = new StackTraceLine(
          methodName, INPUT_FILE_NAME, annotation.lineNo, annotation.columnNo);
      if (indexText == '') {
        unexpectedLines.add(stackTraceLine);
      } else {
        int stackTraceIndex = int.parse(indexText);
        assert(!stackTraceMap.containsKey(stackTraceIndex));
        stackTraceMap[stackTraceIndex] = stackTraceLine;
      }
    }

    List<StackTraceLine> expectedLines = <StackTraceLine>[];
    for (int stackTraceIndex
        in (stackTraceMap.keys.toList()..sort()).reversed) {
      expectedLines.add(stackTraceMap[stackTraceIndex]);
    }
    expectationMap[config] = new Expectations(expectedLines, unexpectedLines);
  });

  return new Test(annotatedCode.sourceCode, expectationMap);
}

/// Compile function used in [testStackTrace]. [input] is the name of the input
/// Dart file and [output] is the name of the generated JavaScript file. The
/// function returns `true` if the compilation succeeded.
typedef Future<bool> CompileFunc(String input, String output);

/// Tests the stack trace of [test] using the expectations for [config].
///
/// The [compile] function is called to compile the Dart code in [test] to
/// JavaScript.
///
/// The [jsPreambles] contains the path of additional JavaScript files needed
/// to run the generated JavaScript file.
///
/// The [beforeExceptions] lines are allowed before the intended stack trace.
/// The [afterExceptions] lines are allowed after the intended stack trace.
///
/// If [printJs] is `true`, the generated JavaScript code is print to the
/// console. If [writeJs] is `true` the generated JavaScript code and the
/// generated source map are saved in the current working directory (as 'out.js'
/// and 'out.js.map', respectively).
Future testStackTrace(Test test, String config, CompileFunc compile,
    {bool printJs: false,
    bool writeJs: false,
    bool verbose: false,
    List<String> jsPreambles: const <String>[],
    List<LineException> beforeExceptions: const <LineException>[],
    List<LineException> afterExceptions: const <LineException>[]}) async {
  Expect.isTrue(test.expectationMap.keys.contains(config),
      "No expectations found for '$config' in ${test.expectationMap.keys}");

  Directory tmpDir = await Directory.systemTemp.createTemp('stacktrace-test');
  String input = '${tmpDir.path}/$INPUT_FILE_NAME';
  new File(input).writeAsStringSync(test.code);
  String output = '${tmpDir.path}/out.js';

  Expect.isTrue(await compile(input, output),
      "Unsuccessful compilation of test:\n${test.code}");
  File sourceMapFile = new File('$output.map');
  Expect.isTrue(
      sourceMapFile.existsSync(), "Source map not generated for $input");
  String sourceMapText = sourceMapFile.readAsStringSync();
  SingleMapping sourceMap = parse(sourceMapText);

  if (printJs) {
    print('JavaScript output:');
    print(new File(output).readAsStringSync());
  }
  if (writeJs) {
    new File('out.js').writeAsStringSync(new File(output).readAsStringSync());
    new File('out.js.map').writeAsStringSync(sourceMapText);
  }
  print("Running d8 $output");
  List<String> d8Arguments = <String>[];
  d8Arguments.addAll(jsPreambles);
  d8Arguments.add(output);
  ProcessResult runResult = Process.runSync(d8executable, d8Arguments);
  String out = '${runResult.stderr}\n${runResult.stdout}';
  if (verbose) {
    print('d8 output:');
    print(out);
  }
  List<String> lines = out.split(new RegExp(r'(\r|\n|\r\n)'));
  List<StackTraceLine> jsStackTrace = <StackTraceLine>[];
  for (String line in lines) {
    if (line.startsWith('    at ')) {
      jsStackTrace.add(new StackTraceLine.fromText(line));
    }
  }

  List<StackTraceLine> dartStackTrace = <StackTraceLine>[];
  for (StackTraceLine line in jsStackTrace) {
    TargetEntry targetEntry = _findColumn(line.lineNo - 1, line.columnNo - 1,
        _findLine(sourceMap, line.lineNo - 1));
    if (targetEntry == null || targetEntry.sourceUrlId == null) {
      dartStackTrace.add(line);
    } else {
      String methodName;
      if (targetEntry.sourceNameId != null) {
        methodName = sourceMap.names[targetEntry.sourceNameId];
      }
      String fileName;
      if (targetEntry.sourceUrlId != null) {
        fileName = sourceMap.urls[targetEntry.sourceUrlId];
      }
      dartStackTrace.add(new StackTraceLine(methodName, fileName,
          targetEntry.sourceLine + 1, targetEntry.sourceColumn + 1,
          isMapped: true));
    }
  }

  Expectations expectations = test.expectationMap[config];

  int expectedIndex = 0;
  List<StackTraceLine> unexpectedLines = <StackTraceLine>[];
  List<StackTraceLine> unexpectedBeforeLines = <StackTraceLine>[];
  List<StackTraceLine> unexpectedAfterLines = <StackTraceLine>[];
  for (StackTraceLine line in dartStackTrace) {
    bool found = false;
    if (expectedIndex < expectations.expectedLines.length) {
      StackTraceLine expectedLine = expectations.expectedLines[expectedIndex];
      if (line.methodName == expectedLine.methodName &&
          line.lineNo == expectedLine.lineNo &&
          line.columnNo == expectedLine.columnNo) {
        found = true;
        expectedIndex++;
      }
    }
    for (StackTraceLine unexpectedLine in expectations.unexpectedLines) {
      if (line.methodName == unexpectedLine.methodName &&
          line.lineNo == unexpectedLine.lineNo &&
          line.columnNo == unexpectedLine.columnNo) {
        unexpectedLines.add(line);
      }
    }
    if (line.isMapped && !found) {
      List<LineException> exceptions =
          expectedIndex == 0 ? beforeExceptions : afterExceptions;
      for (LineException exception in exceptions) {
        String fileName = exception.fileName;
        if (line.methodName == exception.methodName &&
            line.fileName.endsWith(fileName)) {
          found = true;
        }
      }
      if (!found) {
        if (expectedIndex == 0) {
          unexpectedBeforeLines.add(line);
        } else {
          unexpectedAfterLines.add(line);
        }
      }
    }
  }
  if (verbose) {
    print('JavaScript stacktrace:');
    print(jsStackTrace.join('\n'));
    print('Dart stacktrace:');
    print(dartStackTrace.join('\n'));
  }
  Expect.equals(
      expectedIndex,
      expectations.expectedLines.length,
      "Missing stack trace lines for test:\n${test.code}\n"
      "Actual:\n${dartStackTrace.join('\n')}\n"
      "Expected:\n${expectations.expectedLines.join('\n')}\n");
  Expect.isTrue(
      unexpectedLines.isEmpty,
      "Unexpected stack trace lines for test:\n${test.code}\n"
      "Actual:\n${dartStackTrace.join('\n')}\n"
      "Unexpected:\n${expectations.unexpectedLines.join('\n')}\n");
  Expect.isTrue(
      unexpectedBeforeLines.isEmpty && unexpectedAfterLines.isEmpty,
      "Unexpected stack trace lines:\n${test.code}\n"
      "Actual:\n${dartStackTrace.join('\n')}\n"
      "Unexpected before:\n${unexpectedBeforeLines.join('\n')}\n"
      "Unexpected after:\n${unexpectedAfterLines.join('\n')}\n");

  print("Deleting '${tmpDir.path}'.");
  tmpDir.deleteSync(recursive: true);
}

class StackTraceLine {
  String methodName;
  String fileName;
  int lineNo;
  int columnNo;
  bool isMapped;

  StackTraceLine(this.methodName, this.fileName, this.lineNo, this.columnNo,
      {this.isMapped: false});

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
  factory StackTraceLine.fromText(String text) {
    text = text.trim();
    assert(text.startsWith('at '));
    text = text.substring('at '.length);
    String methodName;
    if (text.endsWith(')')) {
      int nameEnd = text.indexOf(' (');
      methodName = text.substring(0, nameEnd);
      text = text.substring(nameEnd + 2, text.length - 1);
    }
    int lineNo;
    int columnNo;
    String fileName;
    int lastColon = text.lastIndexOf(':');
    if (lastColon != -1) {
      int lastValue =
          int.parse(text.substring(lastColon + 1), onError: (_) => null);
      if (lastValue != null) {
        int secondToLastColon = text.lastIndexOf(':', lastColon - 1);
        if (secondToLastColon != -1) {
          int secondToLastValue = int.parse(
              text.substring(secondToLastColon + 1, lastColon),
              onError: (_) => null);
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
    return new StackTraceLine(methodName, fileName, lineNo, columnNo);
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
}

/// Returns [TargetLineEntry] which includes the location in the target [line]
/// number. In particular, the resulting entry is the last entry whose line
/// number is lower or equal to [line].
///
/// Copied from [SingleMapping._findLine].
TargetLineEntry _findLine(SingleMapping sourceMap, int line) {
  int index = binarySearch(sourceMap.lines, (e) => e.line > line);
  return (index <= 0) ? null : sourceMap.lines[index - 1];
}

/// Returns [TargetEntry] which includes the location denoted by
/// [line], [column]. If [lineEntry] corresponds to [line], then this will be
/// the last entry whose column is lower or equal than [column]. If
/// [lineEntry] corresponds to a line prior to [line], then the result will be
/// the very last entry on that line.
///
/// Copied from [SingleMapping._findColumn].
TargetEntry _findColumn(int line, int column, TargetLineEntry lineEntry) {
  if (lineEntry == null || lineEntry.entries.length == 0) return null;
  if (lineEntry.line != line) return lineEntry.entries.last;
  var entries = lineEntry.entries;
  int index = binarySearch(entries, (e) => e.column > column);
  return (index <= 0) ? null : entries[index - 1];
}

/// Returns the path of the d8 executable.
String get d8executable {
  if (Platform.isWindows) {
    return 'third_party/d8/windows/d8.exe';
  } else if (Platform.isLinux) {
    return 'third_party/d8/linux/d8';
  } else if (Platform.isMacOS) {
    return 'third_party/d8/macos/d8';
  }
  throw new UnsupportedError('Unsupported platform.');
}

/// A line allowed in the mapped stack trace.
class LineException {
  final String methodName;
  final String fileName;

  const LineException(this.methodName, this.fileName);
}
