// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/apiimpl.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:expect/expect.dart';
import 'package:source_maps/source_maps.dart';
import 'package:source_maps/src/utils.dart';

import '../source_map_validator_helper.dart';

const String EXCEPTION_MARKER = '>ExceptionMarker<';
const String INPUT_FILE_NAME = 'in.dart';

const List<String> TESTS = const <String>[
  '''
main() {
  @{1:main}throw '$EXCEPTION_MARKER';
}
''',
  '''
import 'package:expect/expect.dart';
main() {
  @{1:main}test();
}
@NoInline()
test() {
  @{2:test}throw '$EXCEPTION_MARKER';
}
''',
  '''
import 'package:expect/expect.dart';
main() {
  @{1:main}Class.test();
}
class Class {
  @NoInline()
  static test() {
    @{2:Class.test}throw '$EXCEPTION_MARKER';
  }
}
''',
  '''
import 'package:expect/expect.dart';
main() {
  var c = new Class();
  c.@{1:main}test();
}
class Class {
  @NoInline()
  test() {
    @{2:Class.test}throw '$EXCEPTION_MARKER';
  }
}
''',
  '''
import 'package:expect/expect.dart';
main() {
  var c = @{1:main}new Class();
}
class Class {
  @NoInline()
  Class() {
    @{2:Class}throw '$EXCEPTION_MARKER';
  }
}
''',
  '''
import 'package:expect/expect.dart';
main() {
  @{1:main}test();
}
@NoInline()
test() {
  try {
    @{2:test}throw '$EXCEPTION_MARKER';
  } finally {
  }
}
''',
  '''
import 'package:expect/expect.dart';
main() {
  @{1:main}test();
}
@NoInline()
test() {
  try {
    @{2:test}throw '$EXCEPTION_MARKER';
  } on Error catch (e) {
  }
}
''',
  '''
import 'package:expect/expect.dart';
main() {
  @{1:main}test();
}
@NoInline()
test() {
  try {
    @{2:test}throw '$EXCEPTION_MARKER';
  } on String catch (e) {
    rethrow;
  }
}
''',
  '''
import 'package:expect/expect.dart';
main() {
  // This call is no longer on the stack when the error is thrown.
  @{:main}test();
}
@NoInline()
test() async {
  @{1:test}throw '$EXCEPTION_MARKER';
}
''',
  '''
import 'package:expect/expect.dart';
main() {
  test1();
}
@NoInline()
test1() async {
  // This call is no longer on the stack when the error is thrown.
  await @{:test1}test2();
}
@NoInline()
test2() async {
  @{1:test2}throw '$EXCEPTION_MARKER';
}
''',
  '''
import 'package:expect/expect.dart';
main() {
  test1();
}
@NoInline()
test1() async {
  @{1:test1}test2();
}
@NoInline()
test2() {
  @{2:test2}throw '$EXCEPTION_MARKER';
}
''',
  '''
import 'package:expect/expect.dart';
main() {
  // This call is no longer on the stack when the error is thrown.
  @{:main}test();
}
test() async {
  var c = @{1:test}new Class();
}
class Class {
  @NoInline()
  Class() {
    @{2:Class}throw '$EXCEPTION_MARKER';
  }
}
''',
];

class Test {
  final String code;
  final List<StackTraceLine> expectedLines;
  final List<StackTraceLine> unexpectedLines;

  Test(this.code, this.expectedLines, this.unexpectedLines);
}

const int _LF = 0x0A;
const int _CR = 0x0D;
const int _LBRACE = 0x7B;

Test processTestCode(String code) {
  StringBuffer codeBuffer = new StringBuffer();
  Map<int, StackTraceLine> stackTraceMap = <int, StackTraceLine>{};
  List<StackTraceLine> unexpectedLines = <StackTraceLine>[];
  int index = 0;
  int lineNo = 1;
  int columnNo = 1;
  while (index < code.length) {
    int charCode = code.codeUnitAt(index);
    switch (charCode) {
      case _LF:
        codeBuffer.write('\n');
        lineNo++;
        columnNo = 1;
        break;
      case _CR:
        if (index + 1 < code.length && code.codeUnitAt(index + 1) == _LF) {
          index++;
        }
        codeBuffer.write('\n');
        lineNo++;
        columnNo = 1;
        break;
      case 0x40:
        if (index + 1 < code.length && code.codeUnitAt(index + 1) == _LBRACE) {
          int colonIndex = code.indexOf(':', index);
          int endIndex = code.indexOf('}', index);
          String methodName = code.substring(colonIndex + 1, endIndex);
          String indexText = code.substring(index + 2, colonIndex);
          StackTraceLine stackTraceLine =
              new StackTraceLine(methodName, INPUT_FILE_NAME, lineNo, columnNo);
          if (indexText == '') {
            unexpectedLines.add(stackTraceLine);
          } else {
            int stackTraceIndex = int.parse(indexText);
            assert(!stackTraceMap.containsKey(stackTraceIndex));
            stackTraceMap[stackTraceIndex] = stackTraceLine;
          }
          index = endIndex;
        } else {
          codeBuffer.writeCharCode(charCode);
          columnNo++;
        }
        break;
      default:
        codeBuffer.writeCharCode(charCode);
        columnNo++;
    }
    index++;
  }
  List<StackTraceLine> expectedLines = <StackTraceLine>[];
  for (int stackTraceIndex in (stackTraceMap.keys.toList()..sort()).reversed) {
    expectedLines.add(stackTraceMap[stackTraceIndex]);
  }
  return new Test(codeBuffer.toString(), expectedLines, unexpectedLines);
}

void main(List<String> arguments) {
  bool verbose = false;
  bool printJs = false;
  List<int> indices;
  for (String arg in arguments) {
    if (arg == '-v') {
      verbose = true;
    } else if (arg == '--print-js') {
      printJs = true;
    } else {
      int index = int.parse(arg, onError: (_) => null);
      if (index != null) {
        indices ??= <int>[];
        if (index < 0 || index >= TESTS.length) {
          print('Index $index out of bounds: [0;${TESTS.length - 1}]');
        } else {
          indices.add(index);
        }
      }
    }
  }
  if (indices == null) {
    indices = new List<int>.generate(TESTS.length, (i) => i);
  }
  asyncTest(() async {
    for (int index in indices) {
      await runTest(index, processTestCode(TESTS[index]),
          printJs: printJs, verbose: verbose);
    }
  });
}

Future runTest(int index, Test test,
    {bool printJs: false, bool verbose: false}) async {
  Directory tmpDir = await createTempDir();
  String input = '${tmpDir.path}/$INPUT_FILE_NAME';
  new File(input).writeAsStringSync(test.code);
  String output = '${tmpDir.path}/out.js';
  List<String> arguments = [
    '-o$output',
    '--library-root=sdk',
    '--packages=${Platform.packageConfig}',
    Flags.useNewSourceInfo,
    input,
  ];
  print("--$index------------------------------------------------------------");
  print("Compiling dart2js ${arguments.join(' ')}\n${test.code}");
  CompilationResult compilationResult = await entry.internalMain(arguments);
  Expect.isTrue(compilationResult.isSuccess,
      "Unsuccessful compilation of test:\n${test.code}");
  CompilerImpl compiler = compilationResult.compiler;
  SingleMapping sourceMap = new SingleMapping.fromJson(
      JSON.decode(new File('$output.map').readAsStringSync()));

  if (printJs) {
    print('JavaScript output:');
    print(new File(output).readAsStringSync());
  }
  print("Running d8 $output");
  ProcessResult runResult = Process.runSync(d8executable,
      ['sdk/lib/_internal/js_runtime/lib/preambles/d8.js', output]);
  String out = '${runResult.stderr}\n${runResult.stdout}';
  if (verbose) {
    print('d8 output:');
    print(out);
  }
  List<String> lines = out.split(new RegExp(r'(\r|\n|\r\n)'));
  List<StackTraceLine> jsStackTrace = <StackTraceLine>[];
  bool seenMarker = false;
  for (String line in lines) {
    if (seenMarker) {
      line = line.trim();
      if (line.startsWith('at ')) {
        jsStackTrace.add(new StackTraceLine.fromText(line));
      }
    } else if (line == EXCEPTION_MARKER) {
      seenMarker = true;
    }
  }

  List<StackTraceLine> dartStackTrace = <StackTraceLine>[];
  for (StackTraceLine line in jsStackTrace) {
    TargetEntry targetEntry = _findColumn(line.lineNo - 1, line.columnNo - 1,
        _findLine(sourceMap, line.lineNo - 1));
    if (targetEntry == null) {
      dartStackTrace.add(line);
    } else {
      String methodName;
      if (targetEntry.sourceNameId != 0) {
        methodName = sourceMap.names[targetEntry.sourceNameId];
      }
      String fileName;
      if (targetEntry.sourceUrlId != 0) {
        fileName = sourceMap.urls[targetEntry.sourceUrlId];
      }
      dartStackTrace.add(new StackTraceLine(methodName, fileName,
          targetEntry.sourceLine + 1, targetEntry.sourceColumn + 1));
    }
  }

  int expectedIndex = 0;
  List<StackTraceLine> unexpectedLines = <StackTraceLine>[];
  for (StackTraceLine line in dartStackTrace) {
    if (expectedIndex < test.expectedLines.length) {
      StackTraceLine expectedLine = test.expectedLines[expectedIndex];
      if (line.methodName == expectedLine.methodName &&
          line.lineNo == expectedLine.lineNo &&
          line.columnNo == expectedLine.columnNo) {
        expectedIndex++;
      }
    }
    for (StackTraceLine unexpectedLine in test.unexpectedLines) {
      if (line.methodName == unexpectedLine.methodName &&
          line.lineNo == unexpectedLine.lineNo &&
          line.columnNo == unexpectedLine.columnNo) {
        unexpectedLines.add(line);
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
      test.expectedLines.length,
      "Missing stack trace lines for test:\n${test.code}\n"
      "Actual:\n${dartStackTrace.join('\n')}\n"
      "Expected:\n${test.expectedLines.join('\n')}\n");
  Expect.isTrue(
      unexpectedLines.isEmpty,
      "Unexpected stack trace lines for test:\n${test.code}\n"
      "Actual:\n${dartStackTrace.join('\n')}\n"
      "Unexpected:\n${test.unexpectedLines.join('\n')}\n");

  print("Deleting '${tmpDir.path}'.");
  tmpDir.deleteSync(recursive: true);
}

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
