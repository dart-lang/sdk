// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/minitest.dart';
import 'package:path/path.dart' as path;
import 'package:source_maps/source_maps.dart';
import 'package:sourcemap_testing/src/annotated_code_helper.dart';
import 'package:testing/testing.dart';

class Data {
  Uri uri;
  Directory outDir;
  AnnotatedCode code;
  List<String> d8Output;
}

class DartStackTraceDataEntry {
  final String file;
  final int line;
  final int column;
  final errorString;
  final int jsLine;
  final int jsColumn;

  DartStackTraceDataEntry(
      this.file, this.line, this.column, this.jsLine, this.jsColumn)
      : errorString = null;
  DartStackTraceDataEntry.error(this.errorString)
      : file = null,
        line = -1,
        column = -1,
        jsLine = -1,
        jsColumn = -1;
  DartStackTraceDataEntry.errorWithJsPosition(
      this.errorString, this.jsLine, this.jsColumn)
      : file = null,
        line = -1,
        column = -1;

  get isError => errorString != null;

  String toString() => isError ? errorString : "$file:$line:$column";
}

abstract class ChainContextWithCleanupHelper extends ChainContext {
  Map<TestDescription, Data> cleanupHelper = {};

  void cleanUp(TestDescription description, Result result) {
    if (debugging() && result.outcome != Expectation.Pass) {
      print("Not cleaning up: Running in debug-mode for non-passing test.");
      return;
    }

    Data data = cleanupHelper.remove(description);
    data?.outDir?.deleteSync(recursive: true);
  }

  bool debugging() => false;
}

class Setup extends Step<TestDescription, Data, ChainContext> {
  const Setup();

  String get name => "setup";

  Future<Result<Data>> run(TestDescription input, ChainContext context) async {
    Data data = new Data()..uri = input.uri;
    if (context is ChainContextWithCleanupHelper) {
      context.cleanupHelper[input] = data;
    }
    return pass(data);
  }
}

class SetCwdToSdkRoot extends Step<Data, Data, ChainContext> {
  const SetCwdToSdkRoot();

  String get name => "setCWD";

  Future<Result<Data>> run(Data input, ChainContext context) async {
    // stacktrace_helper assumes CWD is the sdk root dir.
    var outerDir = getD8File().parent.parent.parent.parent;
    Directory.current = outerDir;
    return pass(input);
  }
}

class StepWithD8 extends Step<Data, Data, ChainContext> {
  const StepWithD8();

  String get name => "step";

  Future<Result<Data>> run(Data data, ChainContext context) async {
    var outputPath = data.outDir.path;
    var outputFilename = "js.js";
    var outputFile = path.join(outputPath, outputFilename);
    var outWrapperPath = path.join(outputPath, "wrapper.js");
    var outInspectorPath = path.join(outputPath, "inspector.js");

    SingleMapping sourceMap =
        parse(new File("${outputFile}.map").readAsStringSync());

    Set<int> mappedToLines = sourceMap.lines
        .map((entry) => entry.entries.map((entry) => entry.sourceLine).toSet())
        .fold(new Set<int>(), (prev, e) => prev..addAll(e));

    for (Annotation annotation
        in data.code.annotations.where((a) => a.text.trim() == "nm")) {
      if (mappedToLines.contains(annotation.lineNo - 1)) {
        fail("Was not allowed to have a mapping to line "
            "${annotation.lineNo}, but did.\n"
            "Sourcemap looks like this (note 0-indexed):\n"
            "${sourceMap.debugString}");
      }
    }

    List<String> breakpoints = [];
    // Annotations are 1-based, js breakpoints are 0-based.
    for (Annotation breakAt
        in data.code.annotations.where((a) => a.text.trim() == "bl")) {
      breakpoints.add(getJsBreakpointLine(sourceMap, breakAt.lineNo - 1));
    }
    for (Annotation breakAt in data.code.annotations
        .where((a) => a.text.trim().startsWith("bc:"))) {
      breakpoints.add(getJsBreakpointLineAndColumn(
          sourceMap, breakAt.lineNo - 1, breakAt.columnNo - 1));
    }

    String inspectorPath = new File.fromUri(Platform.script).parent.path +
        Platform.pathSeparator +
        "jsHelpers" +
        Platform.pathSeparator +
        "inspector.js";
    new File(inspectorPath).copySync(outInspectorPath);
    String debugAction = "Debugger.stepInto";
    if (data.code.annotations
        .any((a) => a.text.trim() == "Debugger:stepOver")) {
      debugAction = "Debugger.stepOver";
    }

    ProcessResult runResult =
        runD8(outInspectorPath, outWrapperPath, debugAction, breakpoints);
    data.d8Output = runResult.stdout.split("\n");
    return pass(data);
  }
}

class CheckSteps extends Step<Data, Data, ChainContext> {
  final bool debug;

  CheckSteps(this.debug);

  String get name => "check";

  Future<Result<Data>> run(Data data, ChainContext context) async {
    var outputPath = data.outDir.path;
    var outputFilename = "js.js";
    var outputFile = path.join(outputPath, outputFilename);

    SingleMapping sourceMap =
        parse(new File("${outputFile}.map").readAsStringSync());

    List<List<DartStackTraceDataEntry>> result =
        extractStackTraces(data.d8Output, sourceMap, outputFilename);

    List<DartStackTraceDataEntry> trace =
        result.map((entry) => entry.first).toList();
    if (debug) debugPrint(trace, outputPath);

    List<String> recordStops = trace
        .where((entry) => !entry.isError)
        .map((entry) => "$entry")
        .toList();

    Set<int> recordStopLines = trace
        .where((entry) => !entry.isError)
        .map((entry) => entry.line)
        .toSet();
    Set<String> recordStopLineColumns = trace
        .where((entry) => !entry.isError)
        .map((entry) => "${entry.line}:${entry.column}")
        .toSet();

    List<String> expectedStops = [];
    for (Annotation annotation in data.code.annotations.where((annotation) =>
        annotation.text.trim().startsWith("s:") ||
        annotation.text.trim().startsWith("sl:") ||
        annotation.text.trim().startsWith("bc:"))) {
      String text = annotation.text.trim();
      int stopNum = int.parse(text.substring(text.indexOf(":") + 1));
      if (expectedStops.length < stopNum) expectedStops.length = stopNum;
      if (text.startsWith("sl:")) {
        expectedStops[stopNum - 1] = "test.dart:${annotation.lineNo}:";
      } else {
        expectedStops[stopNum - 1] =
            "test.dart:${annotation.lineNo}:${annotation.columnNo}:";
      }
    }

    List<List<String>> noBreaksStart = [];
    List<List<String>> noBreaksEnd = [];
    for (Annotation annotation in data.code.annotations
        .where((annotation) => annotation.text.trim().startsWith("nbb:"))) {
      String text = annotation.text.trim();
      var split = text.split(":");
      int stopNum1 = int.parse(split[1]);
      int stopNum2 = int.parse(split[2]);
      if (noBreaksStart.length <= stopNum1) noBreaksStart.length = stopNum1 + 1;
      noBreaksStart[stopNum1] ??= [];
      if (noBreaksEnd.length <= stopNum2) noBreaksEnd.length = stopNum2 + 1;
      noBreaksEnd[stopNum2] ??= [];

      noBreaksStart[stopNum1].add("test.dart:${annotation.lineNo}:");
      noBreaksEnd[stopNum2].add("test.dart:${annotation.lineNo}:");
    }

    checkRecordedStops(recordStops, expectedStops, noBreaksStart, noBreaksEnd);

    for (Annotation annotation in data.code.annotations
        .where((annotation) => annotation.text.trim() == "nb")) {
      // Check that we didn't break where we're not allowed to.
      if (recordStopLines.contains(annotation.lineNo)) {
        fail("Was not allowed to stop on line ${annotation.lineNo}, but did!");
      }
    }
    for (Annotation annotation in data.code.annotations
        .where((annotation) => annotation.text.trim() == "nbc")) {
      // Check that we didn't break where we're not allowed to.
      if (recordStopLineColumns
          .contains("${annotation.lineNo}:${annotation.columnNo}")) {
        fail(
            "Was not allowed to stop on line ${annotation.lineNo} column ${annotation.columnNo}, but did!");
      }
    }

    if (data.code.annotations.any((a) => a.text.trim() == "fail")) {
      fail("Test contains 'fail' annotation.");
    }

    return pass(data);
  }

  void debugPrint(List<DartStackTraceDataEntry> trace, String outputPath) {
    StringBuffer sb = new StringBuffer();
    var jsFile =
        new File(path.join(outputPath, "js.js")).readAsStringSync().split("\n");
    var dartFile = new File(path.join(outputPath, "test.dart"))
        .readAsStringSync()
        .split("\n");

    List<String> getSnippet(List<String> data, int line, int column) {
      List<String> result = new List<String>.filled(5, "");
      if (line < 0 || column < 0) return result;

      for (int i = 0; i < 5; ++i) {
        int j = line - 2 + i;
        if (j < 0 || j >= data.length) continue;
        result[i] = data[j];
      }
      if (result[2].length >= column) {
        result[2] = result[2].substring(0, column) +
            "/*STOP*/" +
            result[2].substring(column);
      }
      return result;
    }

    List<String> sideBySide(List<String> a, List<String> b, int columns) {
      List<String> result = new List<String>(a.length);
      for (int i = 0; i < a.length; ++i) {
        String left = a[i].padRight(columns).substring(0, columns);
        String right = b[i].padRight(columns).substring(0, columns);
        result[i] = left + "  |  " + right;
      }
      return result;
    }

    for (int i = 0; i < trace.length; ++i) {
      sb.write("\n\nStop #${i + 1}\n\n");
      if (trace[i].isError && trace[i].jsLine < 0) {
        sb.write("${trace[i].errorString}\n");
        continue;
      }
      var jsSnippet = getSnippet(jsFile, trace[i].jsLine, trace[i].jsColumn);
      var dartSnippet =
          getSnippet(dartFile, trace[i].line - 1, trace[i].column - 1);
      var view = sideBySide(jsSnippet, dartSnippet, 60);
      sb.writeAll(view, "\n");
    }

    print(sb.toString());
  }
}

class PointMapping {
  final int fromLine;
  final int fromColumn;
  final int toLine;
  final int toColumn;

  PointMapping(this.fromLine, this.fromColumn, this.toLine, this.toColumn);
}

/**
 * Input and output is expected to be 0-based.
 *
 * The "magic 4" below is taken from https://github.com/ChromeDevTools/devtools-
 * frontend/blob/fa18d70a995f06cb73365b2e5b8ae974cf60bd3a/front_end/sources/
 * JavaScriptSourceFrame.js#L1520-L1523
 */
String getJsBreakpointLine(SingleMapping sourceMap, int breakOnLine) {
  List<PointMapping> mappingsOnLines = [];
  for (var line in sourceMap.lines) {
    for (var entry in line.entries) {
      if (entry.sourceLine >= breakOnLine &&
          entry.sourceLine < breakOnLine + 4) {
        mappingsOnLines.add(new PointMapping(
            entry.sourceLine, entry.sourceColumn, line.line, entry.column));
      }
    }
  }

  if (mappingsOnLines.isEmpty) return null;

  mappingsOnLines.sort((a, b) {
    if (a.fromLine != b.fromLine) return a.fromLine - b.fromLine;
    if (a.fromColumn != b.fromColumn) return a.fromColumn - b.fromColumn;
    if (a.toLine != b.toLine) return a.toLine - b.toLine;
    return a.toColumn - b.toColumn;
  });
  PointMapping first = mappingsOnLines.first;
  mappingsOnLines.retainWhere((p) => p.toLine >= first.toLine);

  PointMapping last = mappingsOnLines.last;
  return "${first.toLine}:${first.toColumn}:${last.toLine}:${first.toColumn}";
}

/**
 * Input and output is expected to be 0-based.
 */
String getJsBreakpointLineAndColumn(
    SingleMapping sourceMap, int breakOnLine, int breakOnColumn) {
  for (var line in sourceMap.lines) {
    for (var entry in line.entries) {
      if (entry.sourceLine == breakOnLine &&
          entry.sourceColumn == breakOnColumn)
        return "${line.line}:${entry.column}";
    }
  }
  return null;
}

ProcessResult runD8(String outInspectorPath, String outWrapperPath,
    String debugAction, List<String> breakpoints) {
  var outInspectorPathRelative = path.relative(outInspectorPath);
  var outWrapperPathRelative = path.relative(outWrapperPath);
  ProcessResult runResult = Process.runSync(
      d8Executable,
      [
        '--enable-inspector',
        outInspectorPathRelative,
        '--module',
        outWrapperPathRelative,
        "--",
        debugAction
      ]..addAll(breakpoints.where((s) => s != null)));
  if (runResult.exitCode != 0) {
    print(runResult.stderr);
    print(runResult.stdout);
    throw "Exit code: ${runResult.exitCode} from d8";
  }
  return runResult;
}

List<List<DartStackTraceDataEntry>> extractStackTraces(
    lines, SingleMapping sourceMap, String outputFilename) {
  List<List<DartStackTraceDataEntry>> result = [];
  bool inStackTrace = false;
  List<String> currentStackTrace = <String>[];
  for (var line in lines) {
    if (line.trim() == "--- Debugger stacktrace start ---") {
      inStackTrace = true;
    } else if (line.trim() == "--- Debugger stacktrace end ---") {
      result
          .add(extractStackTrace(currentStackTrace, sourceMap, outputFilename));
      currentStackTrace.clear();
      inStackTrace = false;
    } else if (inStackTrace) {
      currentStackTrace.add(line.trim());
    }
  }
  return result;
}

List<DartStackTraceDataEntry> extractStackTrace(
    List<String> js, SingleMapping sourceMap, String wantedFile) {
  List<DartStackTraceDataEntry> result = [];
  for (String line in js) {
    if (!line.contains("$wantedFile:")) {
      result
          .add(new DartStackTraceDataEntry.error("Not correct file @ '$line'"));
      continue;
    }
    Iterable<Match> ms = new RegExp(r"(\d+):(\d+)").allMatches(line);
    if (ms.isEmpty) {
      result.add(new DartStackTraceDataEntry.error(
          "Line and column not found for '$line'"));
      continue;
    }
    Match m = ms.first;
    int l = int.parse(m.group(1));
    int c = int.parse(m.group(2));
    SourceMapSpan span = sourceMap.spanFor(l, c);
    if (span?.start == null) {
      result.add(new DartStackTraceDataEntry.errorWithJsPosition(
          "Source map not found for '$line'", l, c));
      continue;
    }
    var file = span.sourceUrl?.pathSegments?.last ?? "(unknown file)";
    result.add(new DartStackTraceDataEntry(
        file, span.start.line + 1, span.start.column + 1, l, c));
  }
  return result;
}

void checkRecordedStops(List<String> recordStops, List<String> expectedStops,
    List<List<String>> noBreaksStart, List<List<String>> noBreaksEnd) {
  // We want to find all expected lines in recorded lines in order, but allow
  // more in between in the recorded lines.
  // noBreaksStart and noBreaksStart gives instructions on what's *NOT* allowed
  // to be between those points though.

  int expectedIndex = 0;
  Set<String> aliveNoBreaks = new Set<String>();
  if (noBreaksStart.length > 0 && noBreaksStart[0] != null) {
    aliveNoBreaks.addAll(noBreaksStart[0]);
  }
  for (String recorded in recordStops) {
    if (expectedIndex == expectedStops.length) break;
    if ("$recorded:".contains(expectedStops[expectedIndex])) {
      ++expectedIndex;
      if (noBreaksStart.length > expectedIndex &&
          noBreaksStart[expectedIndex] != null) {
        aliveNoBreaks.addAll(noBreaksStart[expectedIndex]);
      }
      if (noBreaksEnd.length > expectedIndex &&
          noBreaksEnd[expectedIndex] != null) {
        aliveNoBreaks.removeAll(noBreaksEnd[expectedIndex]);
      }
    } else if (aliveNoBreaks
        .contains("${(recorded.split(":")..removeLast()).join(":")}:")) {
      fail("Break '$recorded' was found when it wasn't allowed");
    }
  }
  if (expectedIndex != expectedStops.length) {
    // Didn't find everything.
    fail("Expected to find $expectedStops but found $recordStops");
  }
}

File _cachedD8File;
File getD8File() {
  File attemptFileFromDir(Directory dir) {
    if (Platform.isWindows) {
      return new File(dir.path + Platform.pathSeparator + "d8/windows/d8.exe");
    } else if (Platform.isLinux) {
      return new File(dir.path + Platform.pathSeparator + "d8/linux/d8");
    } else if (Platform.isMacOS) {
      return new File(dir.path + Platform.pathSeparator + "d8/macos/d8");
    }
    throw new UnsupportedError('Unsupported platform.');
  }

  File search() {
    Directory dir = new File.fromUri(Platform.script).parent;
    while (dir.path.length > 1) {
      for (var entry in dir.listSync()) {
        if (entry is! Directory) continue;
        if (entry.path.endsWith("third_party")) {
          List<String> segments = entry.uri.pathSegments;
          if (segments[segments.length - 2] == "third_party") {
            File possibleD8 = attemptFileFromDir(entry);
            if (possibleD8.existsSync()) return possibleD8;
          }
        }
      }
      dir = dir.parent;
    }

    throw "Cannot find D8 directory.";
  }

  return _cachedD8File ??= search();
}

File findInOutDir(String relative) {
  var outerDir = getD8File().parent.parent.parent.parent.path;
  for (var outDir in const ["out/ReleaseX64", "xcodebuild/ReleaseX64"]) {
    var tryPath = path.join(outerDir, outDir, relative);
    File file = new File(tryPath);
    if (file.existsSync()) return file;
  }
  throw "Couldn't find $relative. Try building more targets.";
}

String get d8Executable {
  return getD8File().path;
}

String get dartExecutable {
  return Platform.resolvedExecutable;
}
