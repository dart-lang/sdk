import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/annotated_code_helper.dart';
import 'package:expect/minitest.dart';
import 'package:path/path.dart' as path;
import 'package:source_maps/source_maps.dart';

/**
 * Runs D8 and steps as the AnnotatedCode dictates.
 *
 * Note that the compiled javascript is expected to be called "js.js" inside the
 * outputPath directory. It is also expected that there is a "js.js.map" file.
 * It is furthermore expected that the js has been compiled from a file in the
 * same folder called test.dart.
 */
ProcessResult runD8AndStep(String outputPath, String testFileName,
    AnnotatedCode code, List<String> scriptD8Command) {
  var outputFile = path.join(outputPath, "js.js");
  SingleMapping sourceMap =
      parse(new File("${outputFile}.map").readAsStringSync());

  Set<int> mappedToLines = sourceMap.lines
      .map((entry) => entry.entries.map((entry) => entry.sourceLine).toSet())
      .fold(new Set<int>(), (prev, e) => prev..addAll(e));

  for (Annotation annotation
      in code.annotations.where((a) => a.text.trim() == "nm")) {
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
      in code.annotations.where((a) => a.text.trim() == "bl")) {
    breakpoints
        .add(_getJsBreakpointLine(testFileName, sourceMap, breakAt.lineNo - 1));
  }
  for (Annotation breakAt
      in code.annotations.where((a) => a.text.trim().startsWith("bc:"))) {
    breakpoints.add(_getJsBreakpointLineAndColumn(
        testFileName, sourceMap, breakAt.lineNo - 1, breakAt.columnNo - 1));
  }

  File inspectorFile = new File.fromUri(
      sdkRoot.uri.resolve("pkg/sourcemap_testing/lib/src/js/inspector.js"));
  if (!inspectorFile.existsSync()) throw "Couldn't find 'inspector.js'";
  var outInspectorPath = path.join(outputPath, "inspector.js");
  inspectorFile.copySync(outInspectorPath);
  String debugAction = "Debugger.stepInto";
  if (code.annotations.any((a) => a.text.trim() == "Debugger:stepOver")) {
    debugAction = "Debugger.stepOver";
  }
  return _runD8(outInspectorPath, scriptD8Command, debugAction, breakpoints);
}

/**
 * Translates the D8 js steps and checks against expectations.
 *
 * Note that the compiled javascript is expected to be called "js.js" inside the
 * outputPath directory. It is also expected that there is a "js.js.map" file.
 * It is furthermore expected that the js has been compiled from a file in the
 * same folder called test.dart.
 */
void checkD8Steps(String outputPath, List<String> d8Output, AnnotatedCode code,
    {bool debug: false}) {
  var outputFilename = "js.js";
  var outputFile = path.join(outputPath, outputFilename);
  SingleMapping sourceMap =
      parse(new File("${outputFile}.map").readAsStringSync());

  List<List<_DartStackTraceDataEntry>> result =
      _extractStackTraces(d8Output, sourceMap, outputFilename);

  List<_DartStackTraceDataEntry> trace =
      result.map((entry) => entry.first).toList();
  if (debug) _debugPrint(trace, outputPath);

  List<String> recordStops =
      trace.where((entry) => !entry.isError).map((entry) => "$entry").toList();

  Set<int> recordStopLines =
      trace.where((entry) => !entry.isError).map((entry) => entry.line).toSet();
  Set<String> recordStopLineColumns = trace
      .where((entry) => !entry.isError)
      .map((entry) => "${entry.line}:${entry.column}")
      .toSet();

  List<String> expectedStops = [];
  for (Annotation annotation in code.annotations.where((annotation) =>
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
  for (Annotation annotation in code.annotations
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

  _checkRecordedStops(
      recordStops, expectedStops, noBreaksStart, noBreaksEnd, debug);

  for (Annotation annotation in code.annotations
      .where((annotation) => annotation.text.trim() == "nb")) {
    // Check that we didn't break where we're not allowed to.
    if (recordStopLines.contains(annotation.lineNo)) {
      fail("Was not allowed to stop on line ${annotation.lineNo}, but did!"
          "  Actual line stops: $recordStopLines${_debugHint(debug)}");
    }
  }
  for (Annotation annotation in code.annotations
      .where((annotation) => annotation.text.trim() == "nbc")) {
    // Check that we didn't break where we're not allowed to.
    if (recordStopLineColumns
        .contains("${annotation.lineNo}:${annotation.columnNo}")) {
      fail("Was not allowed to stop on line ${annotation.lineNo} "
          "column ${annotation.columnNo}, but did!"
          "  Actual line stops: $recordStopLineColumns${_debugHint(debug)}");
    }
  }

  if (code.annotations.any((a) => a.text.trim() == "fail")) {
    fail("Test contains 'fail' annotation.");
  }
}

void _checkRecordedStops(
    List<String> recordStops,
    List<String> expectedStops,
    List<List<String>> noBreaksStart,
    List<List<String>> noBreaksEnd,
    bool debug) {
  // We want to find all expected lines in recorded lines in order, but allow
  // more in between in the recorded lines.
  // noBreaksStart and noBreaksStart gives instructions on what's *NOT* allowed
  // to be between those points though.

  int expectedIndex = 0;
  Set<String> aliveNoBreaks = new Set<String>();
  if (noBreaksStart.length > 0 && noBreaksStart[0] != null) {
    aliveNoBreaks.addAll(noBreaksStart[0]);
  }
  int stopNumber = 0;
  for (String recorded in recordStops) {
    stopNumber++;
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
    } else {
      if (debug) {
        // One of the most helpful debugging tools is to see stops that weren't
        // matched. The most common failure is we didn't match one particular
        // stop location (e.g. because of the column). This gets reported
        // as an aliveNoBreaks failure (if the test is using no-breaks like
        // `nbb`) or it's reported as "stops don't match" message.
        //
        // Both failures are difficult to debug without seeing the stops that
        // didn't match. No breaks failures are misleading (the problem isn't
        // an incorrect break, but we missed a stop, so the aliveNoBreaks is
        // wrong), and the normal failure list dumps the enitre stop list,
        // making it difficult to see where the mismatch was.
        //
        // Also we add 1 to expectedIndex, because the stop annotations are
        // 1-based in the source files (e.g. `/*s:1*/` is expectedIndex 0)
        print("Skipping stop `$recorded` that didn't match expected stop "
            "${expectedIndex + 1} `${expectedStops[expectedIndex]}`");
      }
      if (aliveNoBreaks
          .contains("${(recorded.split(":")..removeLast()).join(":")}:")) {
        fail("Break '$recorded' was found when it wasn't allowed "
            "(js step $stopNumber, after stop ${expectedIndex + 1}). "
            "This can happen when an expected stop was not matched"
            "${_debugHint(debug)}.");
      }
    }
  }
  if (expectedIndex != expectedStops.length) {
    // Didn't find everything.
    fail("Expected to find $expectedStops but found $recordStops"
        "${_debugHint(debug)}");
  }
}

/// If we're not in debug mode, this returns a message string with information
/// about how to enable debug mode in the test runner.
String _debugHint(bool debug) {
  if (debug) return ''; // already in debug mode
  return ' (pass -Ddebug=1 to the test runner to see debug information)';
}

void _debugPrint(List<_DartStackTraceDataEntry> trace, String outputPath) {
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
    List<String> result = new List<String>.filled(a.length, null);
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
    var view = sideBySide(jsSnippet, dartSnippet, 50);
    sb.writeAll(view, "\n");
  }

  print(sb.toString());
}

List<List<_DartStackTraceDataEntry>> _extractStackTraces(
    lines, SingleMapping sourceMap, String outputFilename) {
  List<List<_DartStackTraceDataEntry>> result = [];
  bool inStackTrace = false;
  List<String> currentStackTrace = <String>[];
  for (var line in lines) {
    if (line.trim() == "--- Debugger stacktrace start ---") {
      inStackTrace = true;
    } else if (line.trim() == "--- Debugger stacktrace end ---") {
      result.add(
          _extractStackTrace(currentStackTrace, sourceMap, outputFilename));
      currentStackTrace.clear();
      inStackTrace = false;
    } else if (inStackTrace) {
      currentStackTrace.add(line.trim());
    }
  }
  return result;
}

List<_DartStackTraceDataEntry> _extractStackTrace(
    List<String> js, SingleMapping sourceMap, String wantedFile) {
  List<_DartStackTraceDataEntry> result = [];
  for (String line in js) {
    if (!line.contains("$wantedFile:")) {
      result.add(
          new _DartStackTraceDataEntry.error("Not correct file @ '$line'"));
      continue;
    }
    Iterable<Match> ms = new RegExp(r"(\d+):(\d+)").allMatches(line);
    if (ms.isEmpty) {
      result.add(new _DartStackTraceDataEntry.error(
          "Line and column not found for '$line'"));
      continue;
    }
    Match m = ms.first;
    int l = int.parse(m.group(1));
    int c = int.parse(m.group(2));
    SourceMapSpan span = _getColumnOrPredecessor(sourceMap, l, c);
    if (span?.start == null) {
      result.add(new _DartStackTraceDataEntry.errorWithJsPosition(
          "Source map not found for '$line'", l, c));
      continue;
    }
    var file = span.sourceUrl?.pathSegments?.last ?? "(unknown file)";
    result.add(new _DartStackTraceDataEntry(
        file, span.start.line + 1, span.start.column + 1, l, c));
  }
  return result;
}

SourceMapSpan _getColumnOrPredecessor(
    SingleMapping sourceMap, int line, int column) {
  SourceMapSpan span = sourceMap.spanFor(line, column);
  if (span == null && line > 0) {
    span = sourceMap.spanFor(line - 1, 999999);
  }
  return span;
}

class _DartStackTraceDataEntry {
  final String file;
  final int line;
  final int column;
  final errorString;
  final int jsLine;
  final int jsColumn;

  _DartStackTraceDataEntry(
      this.file, this.line, this.column, this.jsLine, this.jsColumn)
      : errorString = null;
  _DartStackTraceDataEntry.error(this.errorString)
      : file = null,
        line = -1,
        column = -1,
        jsLine = -1,
        jsColumn = -1;
  _DartStackTraceDataEntry.errorWithJsPosition(
      this.errorString, this.jsLine, this.jsColumn)
      : file = null,
        line = -1,
        column = -1;

  get isError => errorString != null;

  String toString() => isError ? errorString : "$file:$line:$column";
}

class _PointMapping {
  final int fromLine;
  final int fromColumn;
  final int toLine;
  final int toColumn;

  _PointMapping(this.fromLine, this.fromColumn, this.toLine, this.toColumn);
}

/**
 * Input and output is expected to be 0-based.
 *
 * The "magic 4" below is taken from https://github.com/ChromeDevTools/devtools-
 * frontend/blob/fa18d70a995f06cb73365b2e5b8ae974cf60bd3a/front_end/sources/
 * JavaScriptSourceFrame.js#L1520-L1523
 */
String _getJsBreakpointLine(
    String testFileName, SingleMapping sourceMap, int breakOnLine) {
  List<_PointMapping> mappingsOnLines = [];
  for (var line in sourceMap.lines) {
    for (var entry in line.entries) {
      if (entry.sourceLine == null) continue;
      if (entry.sourceLine >= breakOnLine &&
          entry.sourceLine < breakOnLine + 4 &&
          entry.sourceUrlId != null &&
          sourceMap.urls[entry.sourceUrlId] == testFileName) {
        mappingsOnLines.add(new _PointMapping(
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
  _PointMapping first = mappingsOnLines.first;
  mappingsOnLines.retainWhere((p) => p.toLine >= first.toLine);

  _PointMapping last = mappingsOnLines.last;
  return "${first.toLine}:${first.toColumn}:${last.toLine}:${first.toColumn}";
}

/**
 * Input and output is expected to be 0-based.
 */
String _getJsBreakpointLineAndColumn(String testFileName,
    SingleMapping sourceMap, int breakOnLine, int breakOnColumn) {
  for (var line in sourceMap.lines) {
    for (var entry in line.entries) {
      if (entry.sourceLine == breakOnLine &&
          entry.sourceColumn == breakOnColumn &&
          entry.sourceUrlId != null &&
          sourceMap.urls[entry.sourceUrlId] == testFileName)
        return "${line.line}:${entry.column}";
    }
  }
  return null;
}

ProcessResult _runD8(String outInspectorPath, List<String> scriptD8Command,
    String debugAction, List<String> breakpoints) {
  var outInspectorPathRelative = path.relative(outInspectorPath);
  ProcessResult runResult = Process.runSync(
      d8Executable,
      ['--enable-inspector', outInspectorPathRelative]
        ..addAll(scriptD8Command)
        ..addAll(["--", debugAction])
        ..addAll(breakpoints.where((s) => s != null)));
  if (runResult.exitCode != 0) {
    print(runResult.stderr);
    print(runResult.stdout);
    throw "Exit code: ${runResult.exitCode} from d8";
  }
  return runResult;
}

File _cachedD8File;
Directory _cachedSdkRoot;
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
            if (possibleD8.existsSync()) {
              _cachedSdkRoot = dir;
              return possibleD8;
            }
          }
        }
      }
      dir = dir.parent;
    }

    throw "Cannot find D8 directory.";
  }

  return _cachedD8File ??= search();
}

Directory get sdkRoot {
  getD8File();
  return _cachedSdkRoot;
}

String get d8Executable {
  return getD8File().path;
}
