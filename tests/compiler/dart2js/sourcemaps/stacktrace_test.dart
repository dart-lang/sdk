// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:expect/expect.dart';
import 'package:source_maps/source_maps.dart';
import 'package:source_maps/src/utils.dart';

import 'helpers/source_map_validator_helper.dart';
import '../annotated_code_helper.dart';

const String EXCEPTION_MARKER = '>ExceptionMarker<';
const String INPUT_FILE_NAME = 'in.dart';

class Test {
  final String code;
  final Expectations fromAst;
  final Expectations fromKernel;

  Test(this.code, this.fromAst, this.fromKernel);
}

class Expectations {
  final List<StackTraceLine> expectedLines;
  final List<StackTraceLine> unexpectedLines;

  Expectations(this.expectedLines, this.unexpectedLines);
}

const String astMarker = 'ast.';
const String kernelMarker = 'kernel.';

Test processTestCode(String code) {
  List<Map<int, StackTraceLine>> stackTraceMaps = <Map<int, StackTraceLine>>[
    <int, StackTraceLine>{},
    <int, StackTraceLine>{}
  ];
  List<List<StackTraceLine>> unexpectedLines = <List<StackTraceLine>>[
    <StackTraceLine>[],
    <StackTraceLine>[]
  ];
  AnnotatedCode annotatedCode =
      new AnnotatedCode.fromText(code, commentStart, commentEnd);

  for (Annotation annotation in annotatedCode.annotations) {
    String text = annotation.text;
    List<Map<int, StackTraceLine>> activeMaps = stackTraceMaps;
    List<List<StackTraceLine>> activeLines = unexpectedLines;
    if (text.startsWith(astMarker)) {
      text = text.substring(astMarker.length);
      activeMaps = [stackTraceMaps[0]];
      activeLines = [unexpectedLines[0]];
    } else if (text.startsWith(kernelMarker)) {
      text = text.substring(kernelMarker.length);
      activeMaps = [stackTraceMaps[1]];
      activeLines = [unexpectedLines[0]];
    }
    int colonIndex = text.indexOf(':');
    String indexText = text.substring(0, colonIndex);
    String methodName = text.substring(colonIndex + 1);
    StackTraceLine stackTraceLine = new StackTraceLine(
        methodName, INPUT_FILE_NAME, annotation.lineNo, annotation.columnNo);
    if (indexText == '') {
      for (List<StackTraceLine> unexpected in activeLines) {
        unexpected.add(stackTraceLine);
      }
    } else {
      int stackTraceIndex = int.parse(indexText);
      for (Map<int, StackTraceLine> stackTraceMap in activeMaps) {
        assert(!stackTraceMap.containsKey(stackTraceIndex));
        stackTraceMap[stackTraceIndex] = stackTraceLine;
      }
    }
  }

  List<StackTraceLine> createExpectedLines(
      Map<int, StackTraceLine> stackTraceMap) {
    List<StackTraceLine> expectedLines = <StackTraceLine>[];
    for (int stackTraceIndex
        in (stackTraceMap.keys.toList()..sort()).reversed) {
      expectedLines.add(stackTraceMap[stackTraceIndex]);
    }
    return expectedLines;
  }

  return new Test(
      annotatedCode.sourceCode,
      new Expectations(
          createExpectedLines(stackTraceMaps[0]), unexpectedLines[0]),
      new Expectations(
          createExpectedLines(stackTraceMaps[1]), unexpectedLines[1]));
}

void main(List<String> args) {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);
  argParser.addFlag('write-js', defaultsTo: false);
  argParser.addFlag('print-js', defaultsTo: false);
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: false);
  argParser.addFlag('continued', abbr: 'c', defaultsTo: false);
  ArgResults argResults = argParser.parse(args);
  Directory dataDir =
      new Directory.fromUri(Platform.script.resolve('stacktrace'));
  asyncTest(() async {
    bool continuing = false;
    await for (FileSystemEntity entity in dataDir.list()) {
      String name = entity.uri.pathSegments.last;
      if (argResults.rest.isNotEmpty &&
          !argResults.rest.contains(name) &&
          !continuing) {
        continue;
      }
      print('----------------------------------------------------------------');
      print('Checking ${entity.uri}');
      print('----------------------------------------------------------------');
      String annotatedCode = await new File.fromUri(entity.uri).readAsString();
      await testAnnotatedCode(annotatedCode,
          verbose: argResults['verbose'],
          printJs: argResults['print-js'],
          writeJs: argResults['write-js']);
      if (argResults['continued']) {
        continuing = true;
      }
    }
  });
}

Future testAnnotatedCode(String code,
    {bool printJs: false, bool writeJs: false, bool verbose: false}) async {
  Test test = processTestCode(code);
  print(test.code);
  print('---from ast---------------------------------------------------------');
  await runTest(test, printJs: printJs, writeJs: writeJs, verbose: verbose);
  print('---from kernel------------------------------------------------------');
  await runTest(test,
      printJs: printJs, writeJs: writeJs, verbose: verbose, useKernel: true);
}

Future runTest(Test test,
    {bool printJs: false,
    bool writeJs: false,
    bool verbose: false,
    bool useKernel: false,
    List<String> options: const <String>[]}) async {
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
  ]..addAll(options);
  if (useKernel) {
    arguments.add(Flags.useKernel);
  }
  print("Compiling dart2js ${arguments.join(' ')}");
  CompilationResult compilationResult = await entry.internalMain(arguments);
  Expect.isTrue(compilationResult.isSuccess,
      "Unsuccessful compilation of test:\n${test.code}");
  File sourceMapFile = new File('$output.map');
  Expect.isTrue(
      sourceMapFile.existsSync(), "Source map not generated for $arguments");
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
  ProcessResult runResult = Process.runSync(d8executable,
      ['sdk/lib/_internal/js_runtime/lib/preambles/d8.js', output]);
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

  List<StackTraceLine> testExpectedLines =
      useKernel ? test.fromKernel.expectedLines : test.fromAst.expectedLines;
  List<StackTraceLine> testUnexpectedLines = useKernel
      ? test.fromKernel.unexpectedLines
      : test.fromAst.unexpectedLines;

  int expectedIndex = 0;
  List<StackTraceLine> unexpectedLines = <StackTraceLine>[];
  List<StackTraceLine> unexpectedBeforeLines = <StackTraceLine>[];
  List<StackTraceLine> unexpectedAfterLines = <StackTraceLine>[];
  for (StackTraceLine line in dartStackTrace) {
    bool found = false;
    if (expectedIndex < testExpectedLines.length) {
      StackTraceLine expectedLine = testExpectedLines[expectedIndex];
      if (line.methodName == expectedLine.methodName &&
          line.lineNo == expectedLine.lineNo &&
          line.columnNo == expectedLine.columnNo) {
        found = true;
        expectedIndex++;
      }
    }
    for (StackTraceLine unexpectedLine in testUnexpectedLines) {
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
        if (useKernel && fileName == 'async_patch.dart') {
          // TODO(johnniwinther): Remove this when fasta uses patching.
          fileName = 'async.dart';
        }
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
      testExpectedLines.length,
      "Missing stack trace lines for test:\n${test.code}\n"
      "Actual:\n${dartStackTrace.join('\n')}\n"
      "Expected:\n${testExpectedLines.join('\n')}\n");
  Expect.isTrue(
      unexpectedLines.isEmpty,
      "Unexpected stack trace lines for test:\n${test.code}\n"
      "Actual:\n${dartStackTrace.join('\n')}\n"
      "Unexpected:\n${testUnexpectedLines.join('\n')}\n");
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

/// Lines allowed before the intended stack trace. Typically from helper
/// methods.
const List<LineException> beforeExceptions = const [
  const LineException('wrapException', 'js_helper.dart'),
];

/// Lines allowed after the intended stack trace. Typically from the event
/// queue.
const List<LineException> afterExceptions = const [
  const LineException('_wrapJsFunctionForAsync', 'async_patch.dart'),
  const LineException(
      '_wrapJsFunctionForAsync.<anonymous function>', 'async_patch.dart'),
  const LineException(
      '_awaitOnObject.<anonymous function>', 'async_patch.dart'),
  const LineException('_asyncAwait.<anonymous function>', 'async_patch.dart'),
  const LineException('_asyncStart.<anonymous function>', 'async_patch.dart'),
  const LineException('_RootZone.runUnary', 'zone.dart'),
  const LineException('_FutureListener.handleValue', 'future_impl.dart'),
  const LineException('_Future._completeWithValue', 'future_impl.dart'),
  const LineException(
      '_Future._propagateToListeners.handleValueCallback', 'future_impl.dart'),
  const LineException('_Future._propagateToListeners', 'future_impl.dart'),
  const LineException(
      '_Future._addListener.<anonymous function>', 'future_impl.dart'),
];
