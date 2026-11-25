import 'dart:async';
import 'dart:convert' show jsonDecode;
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/annotated_code_helper.dart';
import 'package:dart2js_tools/src/util.dart';
import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use
import 'package:path/path.dart' as path;
import 'package:source_maps/source_maps.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    as wip;

import 'chrome_helper.dart';

/// The name of the compiled JavaScript file that the stepping helpers expect in
/// the output directory, next to a `<jsFileName>.map` source map.
const String jsFileName = 'js.js';

/// URL path prefix under which [runChromeAndStep] serves its `outputPath`.
const String chromeOutputRoot = 'root_build';

/// URL path prefix under which [runChromeAndStep] serves the SDK checkout.
const String chromeSdkRoot = 'root_dart';

/// Returns the absolute URL path (e.g. `/root_dart/out/ReleaseX64/foo.js`) at
/// which [runChromeAndStep] serves [filePath].
///
/// [filePath] must be inside the SDK checkout. Bootstrap pages and the
/// scripts they load should use these paths to reference SDK files, e.g. the
/// DDC SDK module.
String chromeUrlPathForSdkFile(String filePath) {
  var root = path.normalize(path.absolute(sdkRoot!.path));
  var file = path.normalize(path.absolute(filePath));
  if (!path.isWithin(root, file)) {
    throw ArgumentError.value(filePath, 'filePath', 'Not inside $root');
  }
  var segments = path.split(path.relative(file, from: root));
  return '/${Uri(pathSegments: [chromeSdkRoot, ...segments]).path}';
}

/// Runs the compiled program in Chrome and steps as the [code] dictates.
///
/// Returns the recorded pauses as stack-trace blocks, to be passed to
/// [checkSteps].
///
/// The compiled JavaScript is expected to be called [jsFileName] inside
/// [outputPath], with a source map next to it, compiled from a file called
/// [testFileName].
///
/// [outputPath] is served over HTTP under `/root_build/` and the SDK checkout
/// under `/root_dart/` (see [chromeUrlPathForSdkFile]). Chrome is navigated to
/// `/root_build/<bootstrapFileName>`. That page must:
///
/// * Load [jsFileName] (directly or through imports), so that the script URL
///   ends in [jsFileName].
/// * Not run the program's `main`, but define a global function
///   `scheduleMain()` that runs it. It is called once the page has loaded and
///   all breakpoints have been set, so that no breakpoint is missed.
///
/// The program is considered finished once `scheduleMain()` has returned and
/// all microtasks it queued have run. Programs that use timers are not
/// supported.
Future<List<String>> runChromeAndStep(
  String outputPath,
  String testFileName,
  AnnotatedCode code, {
  String bootstrapFileName = 'bootstrap.html',
  Duration timeout = const Duration(seconds: 60),
}) async {
  var (:breakpoints, :debugAction) = _prepareStepping(
    outputPath,
    testFileName,
    code,
  );
  var server = await StaticFileServer.start({
    chromeOutputRoot: outputPath,
    chromeSdkRoot: sdkRoot!.path,
  });
  ChromeSession? chrome;
  try {
    chrome = await ChromeSession.start();
    var stepper = _ChromeStepper(
      chrome.connection,
      breakpoints.nonNulls.toList(),
      debugAction,
    );
    var bootstrapUrl = server.urlFor('/$chromeOutputRoot/$bootstrapFileName');
    try {
      await stepper.run(bootstrapUrl).timeout(timeout);
    } on TimeoutException {
      throw Exception(
        'Timed out after $timeout running $bootstrapUrl in Chrome.\n'
        '${stepper.diagnostics}',
      );
    }
    return stepper.output;
  } finally {
    await chrome?.close();
    await server.close();
  }
}

/// Validates the `nm` annotations and computes the breakpoints and step
/// action requested by [code].
({List<String?> breakpoints, String debugAction}) _prepareStepping(
  String outputPath,
  String testFileName,
  AnnotatedCode code,
) {
  var sourcemapText = File(
    path.join(outputPath, '$jsFileName.map'),
  ).readAsStringSync();
  SingleMapping sourceMap = parseSingleMapping(jsonDecode(sourcemapText));

  Set<int?> mappedToLines = sourceMap.lines
      .map((entry) => entry.entries.map((entry) => entry.sourceLine).toSet())
      .fold(<int?>{}, (prev, e) => prev..addAll(e));

  for (Annotation annotation in code.annotations.where(
    (a) => a.text.trim() == 'nm',
  )) {
    if (mappedToLines.contains(annotation.lineNo - 1)) {
      fail(
        'Was not allowed to have a mapping to line '
        '${annotation.lineNo}, but did.\n'
        'Sourcemap looks like this (note 0-indexed):\n'
        '${sourceMap.debugString}',
      );
    }
  }

  List<String?> breakpoints = [];
  // Annotations are 1-based, js breakpoints are 0-based.
  for (Annotation breakAt in code.annotations.where(
    (a) => a.text.trim() == 'bl',
  )) {
    breakpoints.add(
      _getJsBreakpointLine(testFileName, sourceMap, breakAt.lineNo - 1),
    );
  }
  for (Annotation breakAt in code.annotations.where(
    (a) => a.text.trim().startsWith('bc:'),
  )) {
    breakpoints.add(
      _getJsBreakpointLineAndColumn(
        testFileName,
        sourceMap,
        breakAt.lineNo - 1,
        breakAt.columnNo - 1,
      ),
    );
  }

  String debugAction = 'Debugger.stepInto';
  if (code.annotations.any((a) => a.text.trim() == 'Debugger:stepOver')) {
    debugAction = 'Debugger.stepOver';
  }
  return (breakpoints: breakpoints, debugAction: debugAction);
}

/// Drives a single run of a bootstrap page in Chrome.
///
/// Sets the breakpoints once [jsFileName] is parsed, then records every pause
/// in [jsFileName] and steps with the requested action. Pauses anywhere else
/// are stepped out of.
class _ChromeStepper {
  /// Logged by the page once the program has finished.
  static const _doneSentinel = '--- sourcemap_testing: program finished ---';

  /// Runs `scheduleMain()` in a fresh task, then logs [_doneSentinel] in the
  /// task after it.
  ///
  /// The outer `setTimeout` makes `Runtime.evaluate` return straight away, and
  /// makes errors thrown by `main` uncaught page errors (see
  /// [_onExceptionThrown]) instead of part of the evaluation result.
  ///
  /// The inner one fires the sentinel only once all microtasks have run, i.e.
  /// after any asynchronous work started by `main` that doesn't use timers.
  /// While the program is paused no new tasks start either, so stepping can't
  /// race with the sentinel.
  static const _runMainExpression =
      '''
setTimeout(function() {
  try {
    scheduleMain();
  } finally {
    setTimeout(function() { console.log('$_doneSentinel'); }, 0);
  }
}, 0);
''';

  final wip.WipConnection _connection;
  final List<String> _breakpoints;
  final String _debugAction;

  /// The recorded pauses, in the format that [checkSteps] parses.
  final List<String> output = [];

  /// Console messages logged by the page, for error messages.
  final List<String> _console = [];

  /// Script URLs by script id.
  final Map<String, String> _scriptUrls = {};

  /// Completes once the program has finished, or with the first error from
  /// starting the page, setting breakpoints, stepping, or the page itself.
  final Completer<void> _done = Completer();

  /// Completes once all breakpoints have been set. Errors go to [_done].
  final Completer<void> _breakpointsSet = Completer();
  bool _settingBreakpoints = false;

  _ChromeStepper(this._connection, this._breakpoints, this._debugAction);

  /// Console output and recorded steps so far, for error messages.
  String get diagnostics =>
      'Console output:\n${_console.join('\n')}\n'
      'Recorded steps:\n${output.join('\n')}';

  Future<void> run(Uri bootstrapUrl) async {
    var subscriptions = <StreamSubscription<Object?>>[
      _connection.debugger.onScriptParsed.listen(_onScriptParsed),
      _connection.debugger.onPaused.listen(_onPaused),
      _connection.runtime.onConsoleAPICalled.listen(_onConsoleAPICalled),
      _connection.runtime.onExceptionThrown.listen(_onExceptionThrown),
      // Failed resource loads (e.g. a 404 for a module import) are only
      // reported here.
      _connection.log.onEntryAdded.listen(
        (entry) => _console.add(
          '[${entry.source} ${entry.level}] ${entry.text}'
          '${entry.url == null ? '' : ' (${entry.url})'}',
        ),
      ),
    ];
    unawaited(_start(bootstrapUrl).catchError(_fail));
    try {
      await _done.future;
    } finally {
      for (var subscription in subscriptions) {
        await subscription.cancel();
      }
    }
  }

  /// Loads the page and runs the program once all breakpoints are set.
  Future<void> _start(Uri bootstrapUrl) async {
    await _connection.debugger.enable();
    await _connection.runtime.enable();
    await _connection.log.enable();
    await _connection.page.enable();
    await _connection.page.navigate('$bootstrapUrl');
    await _breakpointsSet.future;
    await _waitForScheduleMain();
    await _connection.runtime.evaluate(_runMainExpression);
  }

  void _fail(Object error, [StackTrace? stackTrace]) {
    if (!_done.isCompleted) _done.completeError(error, stackTrace);
  }

  void _onScriptParsed(wip.ScriptParsedEvent event) {
    var script = event.script;
    _scriptUrls[script.scriptId] = script.url;
    if (script.url.endsWith(jsFileName) && !_settingBreakpoints) {
      _settingBreakpoints = true;
      _setBreakpoints(
        script.scriptId,
      ).then(_breakpointsSet.complete, onError: _fail);
    }
  }

  Future<void> _setBreakpoints(String scriptId) async {
    var debugger = _connection.debugger;
    for (var breakpoint in _breakpoints) {
      var data = breakpoint.split(':').map(int.parse).toList();
      if (data.length == 4) {
        var locations = await debugger.getPossibleBreakpoints(
          wip.WipLocation.fromValues(scriptId, data[0], columnNumber: data[1]),
          end: wip.WipLocation.fromValues(
            scriptId,
            data[2],
            columnNumber: data[3],
          ),
        );
        if (locations.isNotEmpty) {
          var first = locations.first;
          await _setBreakpoint(
            first.scriptId,
            first.lineNumber,
            first.columnNumber,
          );
        }
      } else if (data.length == 2) {
        await _setBreakpoint(scriptId, data[0], data[1]);
      } else {
        throw ArgumentError.value(breakpoint, 'breakpoint');
      }
    }
  }

  Future<void> _setBreakpoint(String scriptId, int line, int? column) async {
    try {
      await _connection.debugger.setBreakpoint(
        wip.WipLocation.fromValues(scriptId, line, columnNumber: column),
      );
    } on wip.WipError {
      // A breakpoint that can't be set shows up as a missing stop when the
      // steps are checked.
    }
  }

  /// Waits until the page has loaded and defined `scheduleMain`.
  ///
  /// Fails if the page finished loading without defining it, e.g. because a
  /// script failed to load.
  Future<void> _waitForScheduleMain() async {
    const gracePeriod = Duration(seconds: 5);
    Stopwatch? sinceLoaded;
    while (!_done.isCompleted) {
      try {
        var result = await _connection.runtime.evaluate(
          "document.readyState + ' ' + typeof scheduleMain",
          returnByValue: true,
        );
        if (result.value == 'complete function') return;
        if (result.value == 'complete undefined') {
          sinceLoaded ??= Stopwatch()..start();
          if (sinceLoaded.elapsed > gracePeriod) {
            throw Exception(
              'The page loaded but did not define scheduleMain().\n'
              '$diagnostics',
            );
          }
        }
      } on wip.ExceptionDetails {
        // The execution context may be replaced while navigating.
      } on wip.WipError {
        // Same as above.
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  void _onPaused(wip.DebuggerPausedEvent event) {
    var frames = event.getCallFrames();
    String method;
    if (_isStoppedInNonUserScript(frames)) {
      method = 'Debugger.stepOut';
    } else {
      _writeStackTrace(frames);
      method = _debugAction;
    }
    _connection.sendCommand(method).then((_) {}, onError: _fail);
  }

  bool _isStoppedInNonUserScript(List<wip.WipCallFrame> frames) {
    if (frames.isEmpty) return true;
    var url = _scriptUrls[frames.first.location.scriptId];
    if (url == null) return true;
    return !url.endsWith(jsFileName);
  }

  void _writeStackTrace(List<wip.WipCallFrame> frames) {
    output.add('');
    output.add('--- Debugger stacktrace start ---');
    for (var frame in frames) {
      var location = frame.location;
      var url = _displayUrl(_scriptUrls[location.scriptId] ?? frame.url);
      var functionName = frame.functionName;
      if (functionName.isEmpty) functionName = '(unknown)';
      output.add(
        '  at $functionName '
        '($url:${location.lineNumber}:${location.columnNumber ?? 0})',
      );
    }
    output.add('--- Debugger stacktrace end ---');
    output.add('');
  }

  /// Drops the origin from served URLs.
  ///
  /// [checkSteps] takes the first `<digits>:<digits>` in a stack frame as the
  /// position, which would otherwise match the end of the host and the port.
  static String _displayUrl(String url) {
    var uri = Uri.tryParse(url);
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      return uri.path;
    }
    return url;
  }

  void _onConsoleAPICalled(wip.ConsoleAPIEvent event) {
    var text = event.args.map((arg) => arg.value ?? arg.description).join(' ');
    if (text == _doneSentinel) {
      if (!_done.isCompleted) _done.complete();
    } else {
      _console.add('[${event.type}] $text');
    }
  }

  void _onExceptionThrown(wip.ExceptionThrownEvent event) {
    var details = event.exceptionDetails;
    _fail(
      Exception(
        'Uncaught exception in Chrome: '
        '${details.exception?.description ?? details.text} '
        '(${details.url}:${details.lineNumber}:${details.columnNumber})\n'
        '$diagnostics',
      ),
    );
  }
}

/// Translates the recorded JS steps to Dart and checks them against the
/// expectations in [code].
///
/// [stepOutput] is the result of [runChromeAndStep]. Note that the compiled
/// javascript is expected to be called [jsFileName] inside the outputPath
/// directory, with a source map next to it. It is furthermore expected that
/// the js has been compiled from a file in the same folder called test.dart.
void checkSteps(
  String outputPath,
  List<String> stepOutput,
  AnnotatedCode code, {
  bool debug = false,
}) {
  var outputFile = path.join(outputPath, jsFileName);
  var sourcemapText = File('$outputFile.map').readAsStringSync();
  SingleMapping sourceMap = parseSingleMapping(jsonDecode(sourcemapText));

  List<List<_DartStackTraceDataEntry>> result = _extractStackTraces(
    stepOutput,
    sourceMap,
    jsFileName,
  );

  List<_DartStackTraceDataEntry> trace = result
      .map((entry) => entry.first)
      .toList();
  if (debug) _debugPrint(trace, outputPath);

  List<String> recordStops = trace
      .where((entry) => !entry.isError)
      .map((entry) => '$entry')
      .toList();

  Set<int> recordStopLines = trace
      .where((entry) => !entry.isError)
      .map((entry) => entry.line)
      .toSet();
  Set<String> recordStopLineColumns = trace
      .where((entry) => !entry.isError)
      .map((entry) => '${entry.line}:${entry.column}')
      .toSet();

  List<String?> expectedStops = [];
  for (Annotation annotation in code.annotations.where(
    (annotation) =>
        annotation.text.trim().startsWith('s:') ||
        annotation.text.trim().startsWith('sl:') ||
        annotation.text.trim().startsWith('bc:'),
  )) {
    String text = annotation.text.trim();
    int stopNum = int.parse(text.substring(text.indexOf(':') + 1));
    if (expectedStops.length < stopNum) expectedStops.length = stopNum;
    if (text.startsWith('sl:')) {
      expectedStops[stopNum - 1] = 'test.dart:${annotation.lineNo}:';
    } else {
      expectedStops[stopNum - 1] =
          'test.dart:${annotation.lineNo}:${annotation.columnNo}:';
    }
  }

  List<List<String>?> noBreaksStart = [];
  List<List<String>?> noBreaksEnd = [];
  for (Annotation annotation in code.annotations.where(
    (annotation) => annotation.text.trim().startsWith('nbb:'),
  )) {
    String text = annotation.text.trim();
    var split = text.split(':');
    int stopNum1 = int.parse(split[1]);
    int stopNum2 = int.parse(split[2]);
    if (noBreaksStart.length <= stopNum1) noBreaksStart.length = stopNum1 + 1;
    (noBreaksStart[stopNum1] ??= []).add('test.dart:${annotation.lineNo}:');
    if (noBreaksEnd.length <= stopNum2) noBreaksEnd.length = stopNum2 + 1;
    (noBreaksEnd[stopNum2] ??= []).add('test.dart:${annotation.lineNo}:');
  }

  _checkRecordedStops(
    recordStops,
    expectedStops,
    noBreaksStart,
    noBreaksEnd,
    debug,
  );

  for (Annotation annotation in code.annotations.where(
    (annotation) => annotation.text.trim() == 'nb',
  )) {
    // Check that we didn't break where we're not allowed to.
    if (recordStopLines.contains(annotation.lineNo)) {
      fail(
        'Was not allowed to stop on line ${annotation.lineNo}, but did!'
        '  Actual line stops: $recordStopLines${_debugHint(debug)}',
      );
    }
  }
  for (Annotation annotation in code.annotations.where(
    (annotation) => annotation.text.trim() == 'nbc',
  )) {
    // Check that we didn't break where we're not allowed to.
    if (recordStopLineColumns.contains(
      '${annotation.lineNo}:${annotation.columnNo}',
    )) {
      fail(
        'Was not allowed to stop on line ${annotation.lineNo} '
        'column ${annotation.columnNo}, but did!'
        '  Actual line stops: $recordStopLineColumns${_debugHint(debug)}',
      );
    }
  }

  if (code.annotations.any((a) => a.text.trim() == 'fail')) {
    fail("Test contains 'fail' annotation.");
  }
}

void _checkRecordedStops(
  List<String> recordStops,
  List<String?> expectedStops,
  List<List<String>?> noBreaksStart,
  List<List<String>?> noBreaksEnd,
  bool debug,
) {
  // We want to find all expected lines in recorded lines in order, but allow
  // more in between in the recorded lines.
  // noBreaksStart and noBreaksStart gives instructions on what's *NOT* allowed
  // to be between those points though.

  int expectedIndex = 0;
  Set<String> aliveNoBreaks = {};
  if (noBreaksStart.isNotEmpty && noBreaksStart[0] != null) {
    aliveNoBreaks.addAll(noBreaksStart[0]!);
  }
  int stopNumber = 0;
  for (String recorded in recordStops) {
    stopNumber++;
    if (expectedIndex == expectedStops.length) break;
    var expectedStop = expectedStops[expectedIndex];
    if (expectedStop != null && '$recorded:'.contains(expectedStop)) {
      ++expectedIndex;
      if (noBreaksStart.length > expectedIndex &&
          noBreaksStart[expectedIndex] != null) {
        aliveNoBreaks.addAll(noBreaksStart[expectedIndex]!);
      }
      if (noBreaksEnd.length > expectedIndex &&
          noBreaksEnd[expectedIndex] != null) {
        aliveNoBreaks.removeAll(noBreaksEnd[expectedIndex]!);
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
        // wrong), and the normal failure list dumps the entire stop list,
        // making it difficult to see where the mismatch was.
        //
        // Also we add 1 to expectedIndex, because the stop annotations are
        // 1-based in the source files (e.g. `/*s:1*/` is expectedIndex 0)
        print(
          "Skipping stop `$recorded` that didn't match expected stop "
          '${expectedIndex + 1} `${expectedStops[expectedIndex]}`',
        );
      }
      if (aliveNoBreaks.contains(
        "${(recorded.split(":")..removeLast()).join(":")}:",
      )) {
        fail(
          "Break '$recorded' was found when it wasn't allowed "
          '(js step $stopNumber, after stop ${expectedIndex + 1}). '
          'This can happen when an expected stop was not matched'
          '${_debugHint(debug)}.',
        );
      }
    }
  }
  if (expectedIndex != expectedStops.length) {
    // Didn't find everything.
    fail(
      'Expected to find $expectedStops but found $recordStops'
      '${_debugHint(debug)}',
    );
  }
}

/// If we're not in debug mode, this returns a message string with information
/// about how to enable debug mode in the test runner.
String _debugHint(bool debug) {
  if (debug) return ''; // already in debug mode
  return ' (pass -Ddebug=1 to the test runner to see debug information)';
}

void _debugPrint(List<_DartStackTraceDataEntry> trace, String outputPath) {
  StringBuffer sb = StringBuffer();
  var jsFile = File(
    path.join(outputPath, jsFileName),
  ).readAsStringSync().split('\n');
  var dartFile = File(
    path.join(outputPath, 'test.dart'),
  ).readAsStringSync().split('\n');

  List<String> getSnippet(List<String> data, int line, int column) {
    List<String> result = List<String>.filled(5, '');
    if (line < 0 || column < 0) return result;

    for (int i = 0; i < 5; ++i) {
      int j = line - 2 + i;
      if (j < 0 || j >= data.length) continue;
      result[i] = data[j];
    }
    if (result[2].length >= column) {
      var before = result[2].substring(0, column);
      var after = result[2].substring(column);
      result[2] = '$before/*STOP*/$after';
    }
    return result;
  }

  List<String> sideBySide(List<String> a, List<String> b, int columns) {
    List<String> result = List<String>.filled(a.length, '');
    for (int i = 0; i < a.length; ++i) {
      String left = a[i].padRight(columns).substring(0, columns);
      String right = b[i].padRight(columns).substring(0, columns);
      result[i] = '$left  |  $right';
    }
    return result;
  }

  for (int i = 0; i < trace.length; ++i) {
    sb.write('\n\nStop #${i + 1}\n\n');
    if (trace[i].isError && trace[i].jsLine < 0) {
      sb.write('${trace[i].errorString}\n');
      continue;
    }
    var jsSnippet = getSnippet(jsFile, trace[i].jsLine, trace[i].jsColumn);
    var dartSnippet = getSnippet(
      dartFile,
      trace[i].line - 1,
      trace[i].column - 1,
    );
    var view = sideBySide(jsSnippet, dartSnippet, 50);
    sb.writeAll(view, '\n');
  }

  print(sb.toString());
}

List<List<_DartStackTraceDataEntry>> _extractStackTraces(
  List<String> lines,
  SingleMapping sourceMap,
  String outputFilename,
) {
  List<List<_DartStackTraceDataEntry>> result = [];
  bool inStackTrace = false;
  List<String> currentStackTrace = <String>[];
  for (var line in lines) {
    if (line.trim() == '--- Debugger stacktrace start ---') {
      inStackTrace = true;
    } else if (line.trim() == '--- Debugger stacktrace end ---') {
      result.add(
        _extractStackTrace(currentStackTrace, sourceMap, outputFilename),
      );
      currentStackTrace.clear();
      inStackTrace = false;
    } else if (inStackTrace) {
      currentStackTrace.add(line.trim());
    }
  }
  return result;
}

List<_DartStackTraceDataEntry> _extractStackTrace(
  List<String> js,
  SingleMapping sourceMap,
  String wantedFile,
) {
  List<_DartStackTraceDataEntry> result = [];
  for (String line in js) {
    if (!line.contains('$wantedFile:')) {
      result.add(_DartStackTraceDataEntry.error("Not correct file @ '$line'"));
      continue;
    }
    Iterable<Match> ms = RegExp(r'(\d+):(\d+)').allMatches(line);
    if (ms.isEmpty) {
      result.add(
        _DartStackTraceDataEntry.error("Line and column not found for '$line'"),
      );
      continue;
    }
    Match m = ms.first;
    int l = int.parse(m[1]!);
    int c = int.parse(m[2]!);
    SourceMapSpan? span = _getColumnOrPredecessor(sourceMap, l, c);
    if (span?.start == null) {
      result.add(
        _DartStackTraceDataEntry.errorWithJsPosition(
          "Source map not found for '$line'",
          l,
          c,
        ),
      );
      continue;
    }
    var file = span!.sourceUrl?.pathSegments.last ?? '(unknown file)';
    result.add(
      _DartStackTraceDataEntry(
        file,
        span.start.line + 1,
        span.start.column + 1,
        l,
        c,
      ),
    );
  }
  return result;
}

SourceMapSpan? _getColumnOrPredecessor(
  SingleMapping sourceMap,
  int line,
  int column,
) {
  SourceMapSpan? span = sourceMap.spanFor(line, column);
  if (span == null && line > 0) {
    span = sourceMap.spanFor(line - 1, 999999);
  }
  return span;
}

class _DartStackTraceDataEntry {
  final String? file;
  final int line;
  final int column;
  final String? errorString;
  final int jsLine;
  final int jsColumn;

  _DartStackTraceDataEntry(
    this.file,
    this.line,
    this.column,
    this.jsLine,
    this.jsColumn,
  ) : errorString = null;
  _DartStackTraceDataEntry.error(this.errorString)
    : file = null,
      line = -1,
      column = -1,
      jsLine = -1,
      jsColumn = -1;
  _DartStackTraceDataEntry.errorWithJsPosition(
    this.errorString,
    this.jsLine,
    this.jsColumn,
  ) : file = null,
      line = -1,
      column = -1;

  bool get isError => errorString != null;

  @override
  String toString() => isError ? errorString! : '$file:$line:$column';
}

class _PointMapping {
  final int fromLine;
  final int fromColumn;
  final int toLine;
  final int toColumn;

  _PointMapping(this.fromLine, this.fromColumn, this.toLine, this.toColumn);
}

/// Input and output is expected to be 0-based.
///
/// The "magic 4" below is taken from
/// https://github.com/ChromeDevTools/devtools-frontend/blob/fa18d70a995f06cb73365b2e5b8ae974cf60bd3a/front_end/sources/JavaScriptSourceFrame.js#L1520-L1523
String? _getJsBreakpointLine(
  String testFileName,
  SingleMapping sourceMap,
  int breakOnLine,
) {
  List<_PointMapping> mappingsOnLines = [];
  for (var line in sourceMap.lines) {
    for (var entry in line.entries) {
      final sourceLine = entry.sourceLine;
      if (sourceLine == null) continue;
      final sourceColumn = entry.sourceColumn!;
      final sourceUrlId = entry.sourceUrlId;
      if (sourceLine >= breakOnLine &&
          sourceLine < breakOnLine + 4 &&
          sourceUrlId != null &&
          sourceMap.urls[sourceUrlId] == testFileName) {
        mappingsOnLines.add(
          _PointMapping(sourceLine, sourceColumn, line.line, entry.column),
        );
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
  return '${first.toLine}:${first.toColumn}:${last.toLine}:${first.toColumn}';
}

/// Input and output is expected to be 0-based.
String? _getJsBreakpointLineAndColumn(
  String testFileName,
  SingleMapping sourceMap,
  int breakOnLine,
  int breakOnColumn,
) {
  for (var line in sourceMap.lines) {
    for (var entry in line.entries) {
      if (entry.sourceLine == breakOnLine &&
          entry.sourceColumn == breakOnColumn &&
          entry.sourceUrlId != null &&
          sourceMap.urls[entry.sourceUrlId!] == testFileName) {
        return '${line.line}:${entry.column}';
      }
    }
  }
  return null;
}

File? _cachedD8File;
Directory? _cachedSdkRoot;
File getD8File() {
  File attemptFileFromDir(Directory dir) {
    final arch = Abi.current().toString().split('_')[1];
    if (Platform.isWindows) {
      return File(
        '${dir.path}${Platform.pathSeparator}d8/windows/$arch/d8.exe',
      );
    } else if (Platform.isLinux) {
      return File('${dir.path}${Platform.pathSeparator}d8/linux/$arch/d8');
    } else if (Platform.isMacOS) {
      return File('${dir.path}${Platform.pathSeparator}d8/macos/$arch/d8');
    }
    throw UnsupportedError('Unsupported platform.');
  }

  File search() {
    Directory dir = File.fromUri(Platform.script).parent;
    while (dir.path.length > 1) {
      for (var entry in dir.listSync()) {
        if (entry is! Directory) continue;
        if (entry.path.endsWith('third_party')) {
          List<String> segments = entry.uri.pathSegments;
          if (segments[segments.length - 2] == 'third_party') {
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

    throw 'Cannot find D8 directory.';
  }

  return _cachedD8File ??= search();
}

/// The root of the SDK checkout, found by looking for `third_party/d8` above
/// the running script.
Directory? get sdkRoot {
  getD8File();
  return _cachedSdkRoot;
}
