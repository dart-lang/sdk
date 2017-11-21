import 'dart:io';
import 'package:testing/testing.dart';
import 'package:path/path.dart' as path;
import 'package:expect/minitest.dart';
import 'package:source_maps/source_maps.dart';
import 'annotated_code_helper.dart';

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

  DartStackTraceDataEntry(this.file, this.line, this.column)
      : errorString = null;
  DartStackTraceDataEntry.error(this.errorString)
      : file = null,
        line = -1,
        column = -1;

  get isError => errorString != null;

  String toString() => isError ? errorString : "$file:$line:$column";
}

abstract class ChainContextWithCleanupHelper extends ChainContext {
  Map<TestDescription, Data> cleanupHelper = {};

  void cleanUp(TestDescription description, Result result) {
    Data data = cleanupHelper.remove(description);
    data?.outDir?.deleteSync(recursive: true);
  }
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

    ProcessResult runResult = runD8(
        outInspectorPath, outWrapperPath, "Debugger.stepInto", breakpoints);
    data.d8Output = runResult.stdout.split("\n");
    return pass(data);
  }
}

class CheckSteps extends Step<Data, Data, ChainContext> {
  const CheckSteps();

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

    List<String> recordStops = trace
        .where((entry) => !entry.isError)
        .map((entry) => "$entry")
        .toList();

    Set<int> recordStopLines = trace
        .where((entry) => !entry.isError)
        .map((entry) => entry.line)
        .toSet();

    List<String> expectedStops = [];
    for (Annotation annotation in data.code.annotations.where((annotation) =>
        annotation.text.trim().startsWith("s:") ||
        annotation.text.trim().startsWith("bc:"))) {
      String text = annotation.text.trim();
      int stopNum = int.parse(text.substring(text.indexOf(":") + 1));
      if (expectedStops.length < stopNum) expectedStops.length = stopNum;
      expectedStops[stopNum - 1] =
          "test.dart:${annotation.lineNo}:${annotation.columnNo}";
    }

    checkRecordedStops(recordStops, expectedStops);

    for (Annotation annotation in data.code.annotations
        .where((annotation) => annotation.text.trim().startsWith("nb"))) {
      // Check that we didn't break where we're not allowed to.
      if (recordStopLines.contains(annotation.lineNo)) {
        fail("Was not allowed to stop on line ${annotation.lineNo}, but did!");
      }
    }

    return pass(data);
  }
}

/**
 * Input and output is expected to be 0-based.
 *
 * The "magic 4" below is taken from https://github.com/ChromeDevTools/devtools-
 * frontend/blob/fa18d70a995f06cb73365b2e5b8ae974cf60bd3a/front_end/sources/
 * JavaScriptSourceFrame.js#L1520-L1523
 */
String getJsBreakpointLine(SingleMapping sourceMap, int breakOnLine) {
  String first;
  String last;
  for (var line in sourceMap.lines) {
    for (var entry in line.entries) {
      if (entry.sourceLine == breakOnLine && first == null) {
        first = "${line.line}:${entry.column}";
        last = first;
      } else if (entry.sourceLine >= breakOnLine &&
          entry.sourceLine < breakOnLine + 4) {
        last = "${line.line}:${entry.column}";
        if (first == null) first = last;
      } else if (entry.sourceLine >= breakOnLine) {
        break;
      }
    }
  }
  if (first != null && last != null) return "$first:$last";
  return null;
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
      result.add(new DartStackTraceDataEntry.error(
          "Source map not found for '$line'"));
      continue;
    }
    var file = span.sourceUrl?.pathSegments?.last ?? "(unknown file)";
    result.add(new DartStackTraceDataEntry(
        file, span.start.line + 1, span.start.column + 1));
  }
  return result;
}

// Copied from observatory tests.
void checkRecordedStops(List<String> recordStops, List<String> expectedStops) {
  // We want to find all expected lines in recorded lines in order, but allow
  // more in between in the recorded lines.

  int expectedIndex = 0;
  for (String recorded in recordStops) {
    if (expectedIndex == expectedStops.length) break;
    if (recorded == expectedStops[expectedIndex]) {
      ++expectedIndex;
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

String get d8Executable {
  return getD8File().path;
}

String get dartExecutable {
  return Platform.executable;
}
