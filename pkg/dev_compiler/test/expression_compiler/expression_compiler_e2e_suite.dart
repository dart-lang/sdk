// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, Platform, FileSystemException;
import 'dart:math';

import 'package:async/async.dart';
import 'package:browser_launcher/browser_launcher.dart' as browser;
import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    as wip;

import '../shared_test_options.dart';
import 'test_compiler.dart';

class ExpressionEvaluationTestDriver {
  final browser.Chrome chrome;
  final Directory chromeDir;
  final wip.WipConnection connection;
  final wip.WipDebugger debugger;
  final wip.WipRuntime runtime;
  final ExecutionContext executionContext;
  late TestExpressionCompiler compiler;
  late Uri htmlBootstrapper;
  late Uri input;
  late Uri output;
  late Uri packagesFile;
  String? preemptiveBp;
  late SetupCompilerOptions setup;
  late String source;
  late Directory testDir;
  late String dartSdkPath;

  ExpressionEvaluationTestDriver._(
      this.chrome, this.chromeDir, this.connection, this.debugger, this.runtime)
      : executionContext = ExecutionContext(runtime);

  /// Initializes a Chrome browser instance, tab connection, and debugger.
  static Future<ExpressionEvaluationTestDriver> init() async {
    // Create a temporary directory for holding Chrome tests.
    var chromeDir = Directory.systemTemp.createTempSync('ddc_eval_test_anchor');

    // Try to start Chrome on an empty page with a single empty tab.
    // TODO(#45713): Headless Chrome crashes the Windows bots, so run in
    // standard mode until it's fixed.
    browser.Chrome? chrome;
    var retries = 3;
    // It is possible for chrome to start and be ready while still printing
    // messages to stderr which results in a Dart exception being thrown. For
    // that reason, it is important to check `chrome == null` so we don't
    // accidentally start multiple instances.
    while (chrome == null && retries-- > 0) {
      try {
        chrome = await browser.Chrome.startWithDebugPort(['about:blank'],
            userDataDir: chromeDir.uri.toFilePath(),
            headless: !Platform.isWindows);
      } catch (e) {
        if (retries == 0) rethrow;
        await Future.delayed(Duration(seconds: 5));
      }
    }
    if (chrome == null) {
      throw Exception('Unable to launch Chrome.');
    }

    // Connect to the first 'normal' tab.
    var tab = await chrome.chromeConnection.getTab(
        (tab) => !tab.isBackgroundPage && !tab.isChromeExtension,
        retryFor: Duration(seconds: 5));
    if (tab == null) {
      throw Exception('Unable to connect to Chrome tab');
    }

    var connection = await tab.connect().timeout(Duration(seconds: 5),
        onTimeout: (() => throw Exception('Unable to connect to WIP tab')));

    await connection.page.enable().timeout(Duration(seconds: 5),
        onTimeout: (() => throw Exception('Unable to enable WIP tab page')));

    var runtime = connection.runtime;
    await runtime.enable().timeout(Duration(seconds: 5),
        onTimeout: (() => throw Exception('Unable to enable WIP runtime')));

    var debugger = connection.debugger;
    await debugger.enable().timeout(Duration(seconds: 5),
        onTimeout: (() => throw Exception('Unable to enable WIP debugger')));

    return ExpressionEvaluationTestDriver._(
        chrome, chromeDir, connection, debugger, runtime);
  }

  /// Must be called when testing a new Dart program.
  ///
  /// Depends on SDK artifacts (such as the sound and unsound dart_sdk.js
  /// files) generated from the 'ddc_stable_test' and 'ddc_canary_test' targets.
  Future<void> initSource(
    SetupCompilerOptions setup,
    String source, {
    Map<String, bool> experiments = const {},
  }) async {
    // Perform setup sanity checks.
    var summaryPath = setup.options.sdkSummary!.toFilePath();
    if (!File(summaryPath).existsSync()) {
      throw StateError('Unable to find SDK summary at path: $summaryPath.');
    }

    // Prepend legacy Dart version comment.
    if (setup.legacyCode) source = '// @dart = 2.11\n\n$source';
    this.setup = setup;
    this.source = source;
    testDir = chromeDir.createTempSync('ddc_eval_test');
    var scriptPath = Platform.script.normalizePath().toFilePath();
    var ddcPath = p.dirname(p.dirname(p.dirname(scriptPath)));
    output = testDir.uri.resolve('test.js');
    input = testDir.uri.resolve('test.dart');
    File(input.toFilePath())
      ..createSync()
      ..writeAsStringSync(source);

    packagesFile = testDir.uri.resolve('package_config.json');
    File(packagesFile.toFilePath())
      ..createSync()
      ..writeAsStringSync('''
      {
        "configVersion": 2,
        "packages": [
          {
            "name": "eval_test",
            "rootUri": "./",
            "packageUri": "./"
          }
        ]
      }
      ''');

    // Initialize DDC and the incremental compiler, then perform a full compile.
    compiler = await TestExpressionCompiler.init(setup,
        input: input,
        output: output,
        packages: packagesFile,
        experiments: experiments);

    htmlBootstrapper = testDir.uri.resolve('bootstrapper.html');
    var bootstrapFile = File(htmlBootstrapper.toFilePath())..createSync();
    var moduleName = compiler.metadata!.name;
    var mainLibraryName = compiler.metadataForLibraryUri(input).name;
    var appName = p.relative(
        p.withoutExtension(compiler.metadataForLibraryUri(input).importUri));

    switch (setup.moduleFormat) {
      case ModuleFormat.ddc:
        dartSdkPath = escaped(SetupCompilerOptions.buildRoot
            .resolve(p.join(
                'gen',
                'utils',
                'ddc',
                '${setup.canaryFeatures ? 'canary' : 'stable'}'
                    '${setup.soundNullSafety ? '' : '_unsound'}',
                'sdk',
                'legacy',
                'dart_sdk.js'))
            .toFilePath());
        if (!File(dartSdkPath).existsSync()) {
          throw Exception('Unable to find Dart SDK at $dartSdkPath');
        }
        var dartLibraryPath =
            escaped(p.join(ddcPath, 'lib', 'js', 'legacy', 'dart_library.js'));
        var outputPath = output.toFilePath();
        // This is used in the DDC module system for multiapp workflows and is
        // stubbed here.
        var uuid = '00000000-0000-0000-0000-000000000000';
        bootstrapFile.writeAsStringSync('''
<script src='$dartLibraryPath'></script>
<script src='$dartSdkPath'></script>
<script src='$outputPath'></script>
<script>
  'use strict';
  let dartApplication = true;
  var sound = ${setup.soundNullSafety};
  var sdk = dart_library.import('dart_sdk');

  if (sound) {
    sdk.dart.nativeNonNullAsserts(true);
  } else {
    sdk.dart.weakNullSafetyWarnings(false);
    sdk.dart.weakNullSafetyErrors(false);
    sdk.dart.nonNullAsserts(true);
  }

  sdk._debugger.registerDevtoolsFormatter();
  dart_library.start('$appName', '$uuid', '$moduleName', '$mainLibraryName',
    false);
</script>
''');
        break;
      case ModuleFormat.amd:
        var dartSdkPathNoExtension = escaped(SetupCompilerOptions.buildRoot
            .resolve(p.join(
                'gen',
                'utils',
                'ddc',
                '${setup.canaryFeatures ? 'canary' : 'stable'}'
                    '${setup.soundNullSafety ? '' : '_unsound'}',
                'sdk',
                'amd',
                'dart_sdk'))
            .toFilePath());
        dartSdkPath = '$dartSdkPathNoExtension.js';

        if (!File(dartSdkPath).existsSync()) {
          throw Exception('Unable to find Dart SDK at $dartSdkPath');
        }
        var requirePath = escaped(SetupCompilerOptions.buildRoot
            .resolve(
                p.join('dart-sdk', 'lib', 'dev_compiler', 'amd', 'require.js'))
            .toFilePath());
        var outputPath = escaped(p.withoutExtension(output.toFilePath()));
        bootstrapFile.writeAsStringSync('''
<script src='$requirePath'></script>
<script>
  require.config({
    paths: {
        'dart_sdk': '$dartSdkPathNoExtension',
        '$moduleName': '$outputPath'
    },
    waitSeconds: 15
  });
  let dartApplication = true;
  var sound = ${setup.soundNullSafety};

  require(['dart_sdk', '$moduleName'],
        function(sdk, app) {
    'use strict';

    if (sound) {
      sdk.dart.nativeNonNullAsserts(true);
    } else {
      sdk.dart.weakNullSafetyWarnings(false);
      sdk.dart.weakNullSafetyErrors(false);
      sdk.dart.nonNullAsserts(true);
    }

    sdk._debugger.registerDevtoolsFormatter();
    app.$mainLibraryName.main([]);
  });
</script>
''');

        break;
      default:
        throw Exception('Unsupported module format for SDK evaluation tests: '
            '${setup.moduleFormat}');
    }

    await setBreakpointsActive(debugger, true);

    // Pause as soon as the test file loads but before it executes.
    var urlRegex = '.*${libraryUriToJsIdentifier(output)}.*';
    var bpResponse =
        await debugger.sendCommand('Debugger.setBreakpointByUrl', params: {
      'urlRegex': urlRegex,
      'lineNumber': 0,
    });
    preemptiveBp = wip.SetBreakpointResponse(bpResponse.json).breakpointId;
  }

  Future<void> finish() async {
    await chrome.close();
    // Attempt to clean up the temporary directory.
    // On windows sometimes the process has not released the directory yet so
    // retry with an exponential backoff.
    var deleteAttempts = 0;
    while (await chromeDir.exists()) {
      deleteAttempts++;
      try {
        await chromeDir.delete(recursive: true);
      } on FileSystemException {
        if (deleteAttempts > 3) rethrow;
        var delayMs = pow(10, deleteAttempts).floor();
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  Future<void> cleanupTest() async {
    await setBreakpointsActive(debugger, false);
    if (preemptiveBp != null) {
      await debugger.removeBreakpoint(preemptiveBp!);
    }
    setup.diagnosticMessages.clear();
    setup.errors.clear();
  }

  Future<void> checkScope({
    required String breakpointId,
    required Map<String, String> expectedScope,
  }) async {
    final actualScope = await getScope(breakpointId);
    actualScope.removeWhere((key, value) =>
        _ddcTemporaryVariableRegExp.hasMatch(key) ||
        _ddcTemporaryTypeVariableRegExp.hasMatch(key));
    expect(actualScope, expectedScope);
  }

  Future<wip.WipScript> _loadScript() async {
    final scriptController = StreamController<wip.ScriptParsedEvent>();
    final consoleSub = debugger.connection.runtime.onConsoleAPICalled
        .listen((e) => printOnFailure('$e'));

    // Fail on exceptions in JS code.
    await debugger.setPauseOnExceptions(wip.PauseState.uncaught);
    final pauseSub = debugger.onPaused.listen((wip.DebuggerPausedEvent e) {
      if (e.reason == 'exception' || e.reason == 'assert') {
        scriptController.addError('Uncaught exception in JS code: ${e.data}');
        throw Exception('Failed to load script.');
      }
    });

    final scriptSub = debugger.onScriptParsed.listen((event) {
      if (event.script.url == '$output') {
        scriptController.add(event);
      }
    });

    try {
      // Navigate from the empty page and immediately pause on the preemptive
      // breakpoint.
      await connection.page.navigate('$htmlBootstrapper').timeout(
          Duration(seconds: 5),
          onTimeout: (() => throw Exception(
              'Unable to navigate to page bootstrap script: $htmlBootstrapper')));

      // Poll until the script is found, or timeout after a few seconds.
      return (await scriptController.stream.first.timeout(Duration(seconds: 5),
              onTimeout: (() => throw Exception(
                  'Unable to find JS script corresponding to test file '
                  '$output in ${debugger.scripts}.'))))
          .script;
    } finally {
      await scriptSub.cancel();
      await consoleSub.cancel();
      await scriptController.close();
      await pauseSub.cancel();
    }
  }

  /// Load the script and run [onPause] when the app pauses on [breakpointId].
  Future<T> _onBreakpoint<T>(String breakpointId,
      {required Future<T> Function(wip.DebuggerPausedEvent) onPause}) async {
    // The next two pause events will correspond to:
    // 1. the initial preemptive breakpoint and
    // 2. the breakpoint at the specified ID

    final consoleSub = debugger.connection.runtime.onConsoleAPICalled
        .listen((e) => printOnFailure('$e'));

    final pauseController = StreamController<wip.DebuggerPausedEvent>();
    final pauseSub = debugger.onPaused.listen((e) {
      if (e.reason == 'exception' || e.reason == 'assert') {
        pauseController.addError('Uncaught exception in JS code: ${e.data}');
        throw Exception('Script failed while waiting for a breakpoint to hit.');
      }
      pauseController.add(e);
    });

    final script = await _loadScript();

    // Breakpoint at the first WIP location mapped from its Dart line.
    var dartLine = _findBreakpointLine(breakpointId);
    var location = await _jsLocationFromDartLine(script, dartLine);

    var bp = await debugger.setBreakpoint(location);
    final pauseQueue = StreamQueue(pauseController.stream);
    try {
      // Continue to the next breakpoint, ignoring the first pause event
      // since it corresponds to the preemptive URI breakpoint made prior
      // to page navigation.
      await debugger.resume();
      await pauseQueue.next.timeout(Duration(seconds: 5),
          onTimeout: () => throw Exception(
              'Unable to find JS preemptive pause event in $output.'));
      final event = await pauseQueue.next.timeout(Duration(seconds: 5),
          onTimeout: () => throw Exception(
              'Unable to find JS pause event corresponding to line '
              '($dartLine -> $location) in $output.'));

      return await onPause(event);
    } finally {
      await pauseQueue.cancel();
      await pauseSub.cancel();
      await pauseController.close();
      await consoleSub.cancel();

      await debugger.removeBreakpoint(bp.breakpointId);
      // Resume execution to the end of the current script
      try {
        await debugger.resume();
      } catch (_) {
        // Resume throws it the program is not paused, ignore.
      }
    }
  }

  /// Load the script and run the [body] while the app is running.
  Future<T> _whileRunning<T>({required Future<T> Function() body}) async {
    final consoleSub = debugger.connection.runtime.onConsoleAPICalled
        .listen((e) => printOnFailure('$e'));

    await _loadScript();
    try {
      // Continue running, ignoring the first pause event since it corresponds
      // to the preemptive URI breakpoint made prior to page navigation.
      await debugger.resume();
      return await body();
    } finally {
      await consoleSub.cancel();
    }
  }

  Future<Map<String, String>> getScope(String breakpointId) async {
    return await _onBreakpoint(breakpointId, onPause: (event) async {
      // Retrieve the call frame and its scope variables.
      var frame = event.getCallFrames().first;
      return await _collectScopeVariables(frame);
    });
  }

  /// Evaluates a dart [expression] on a breakpoint.
  ///
  /// [breakpointId] is the ID of the breakpoint from the source.
  Future<String> evaluateDartExpressionInFrame({
    required String breakpointId,
    required String expression,
  }) async {
    var dartLine = _findBreakpointLine(breakpointId);
    return await _onBreakpoint(breakpointId, onPause: (event) async {
      var result = await _evaluateDartExpressionInFrame(
        event,
        expression,
        dartLine,
      );
      return await stringifyRemoteObject(result);
    });
  }

  /// Evaluates a dart [expression] while the app is running.
  Future<String> evaluateDartExpression({required String expression}) async {
    return await _whileRunning(body: () async {
      var result = await _evaluateDartExpression(expression);
      return await stringifyRemoteObject(result);
    });
  }

  /// Evaluates a js [expression] on a breakpoint.
  ///
  /// [breakpointId] is the ID of the breakpoint from the source.
  Future<String> evaluateJsExpression({
    required String breakpointId,
    required String expression,
  }) async {
    return await _onBreakpoint(breakpointId, onPause: (event) async {
      var result = await _evaluateJsExpression(
        event,
        expression,
      );
      return await stringifyRemoteObject(result);
    });
  }

  /// Evaluates a JavaScript [expression] on a breakpoint and validates result.
  ///
  /// [breakpointId] is the ID of the breakpoint from the source.
  /// [expression] is a dart runtime method call, i.e.
  /// `dart.getLibraryMetadata(uri)`;
  /// [expectedResult] is the JSON for the returned remote object.
  ///
  /// Nested objects are not included in the result (they appear as `{}`),
  /// only primitive values, lists or maps, etc.
  ///
  /// TODO(annagrin): Add recursive check for nested objects.
  Future<void> checkRuntimeInFrame({
    required String breakpointId,
    required String expression,
    dynamic expectedError,
    dynamic expectedResult,
  }) async {
    assert(expectedError == null || expectedResult == null,
        'Cannot expect both an error and result.');

    return await _onBreakpoint(breakpointId, onPause: (event) async {
      var evalResult = await _evaluateJsExpression(event, expression);

      var error = evalResult.json['error'];
      if (error != null) {
        expect(
          expectedError,
          isNotNull,
          reason: 'Unexpected expression evaluation failure:\n$error',
        );
        expect(error, _matches(expectedError!));
      } else {
        expect(
          expectedResult,
          isNotNull,
          reason:
              'Unexpected expression evaluation success:\n${evalResult.json}',
        );
        var actual = evalResult.value;
        expect(actual, _matches(equals(expectedResult!)));
      }
    });
  }

  /// Evaluates a dart [expression] on a breakpoint and validates result.
  ///
  /// [breakpointId] is the ID of the breakpoint from the source.
  /// [expression] is a dart expression.
  /// [expectedResult] is the JSON for the returned remote object.
  /// [expectedError] is the error string if the error is expected.
  Future<void> checkInFrame(
      {required String breakpointId,
      required String expression,
      dynamic expectedError,
      dynamic expectedResult}) async {
    assert(expectedError == null || expectedResult == null,
        'Cannot expect both an error and result.');

    var dartLine = _findBreakpointLine(breakpointId);
    return await _onBreakpoint(breakpointId, onPause: (event) async {
      var evalResult = await _evaluateDartExpressionInFrame(
        event,
        expression,
        dartLine,
      );

      var error = evalResult.json['error'];
      if (error != null) {
        expect(
          expectedError,
          isNotNull,
          reason: 'Unexpected expression evaluation failure:\n$error',
        );
        expect(error, _matches(expectedError!));
      } else {
        expect(
          expectedResult,
          isNotNull,
          reason:
              'Unexpected expression evaluation success:\n${evalResult.json}',
        );
        var actual = await stringifyRemoteObject(evalResult);
        expect(actual, _matches(expectedResult!));
      }
    });
  }

  /// Evaluates a dart [expression] without breakpoint and validates result.
  ///
  /// [expression] is a dart expression.
  /// [expectedResult] is the JSON for the returned remote object.
  /// [expectedError] is the error string if the error is expected.
  Future<void> check(
      {required String expression,
      dynamic expectedError,
      dynamic expectedResult}) async {
    assert(expectedError == null || expectedResult == null,
        'Cannot expect both an error and result.');

    return await _whileRunning(body: () async {
      var evalResult = await _evaluateDartExpression(expression);

      var error = evalResult.json['error'];
      if (error != null) {
        expect(
          expectedError,
          isNotNull,
          reason: 'Unexpected expression evaluation failure:\n$error',
        );
        expect(error, _matches(expectedError!));
      } else {
        expect(
          expectedResult,
          isNotNull,
          reason:
              'Unexpected expression evaluation success:\n${evalResult.json}',
        );
        var actual = await stringifyRemoteObject(evalResult);
        expect(actual, _matches(expectedResult!));
      }
    });
  }

  Future<wip.RemoteObject> _evaluateJsExpression(
    wip.DebuggerPausedEvent event,
    String expression, {
    bool returnByValue = true,
  }) async {
    var frame = event.getCallFrames().first;

    var jsExpression = '''
      (function () {
        var sdk = ${setup.loadModule}('dart_sdk');
        var dart = sdk.dart;
        var interceptors = sdk._interceptors;
        return $expression;
      })()
      ''';

    try {
      return await debugger.evaluateOnCallFrame(
        frame.callFrameId,
        jsExpression,
        returnByValue: returnByValue,
      );
    } on wip.ExceptionDetails catch (e) {
      return _createRuntimeError(e);
    }
  }

  Future<TestCompilationResult> _compileDartExpressionInFrame(
      wip.WipCallFrame frame, String expression, int dartLine) async {
    // Retrieve the call frame and its scope variables.
    var scope = await _collectScopeVariables(frame);

    // Perform an incremental compile.
    return await compiler.compileExpression(
      input: input,
      line: dartLine,
      column: 1,
      scope: scope,
      expression: expression,
    );
  }

  Future<TestCompilationResult> _compileDartExpression(
      String expression) async {
    // Perform an incremental compile.
    return await compiler.compileExpression(
      input: input,
      line: 1,
      column: 1,
      scope: {},
      expression: expression,
    );
  }

  Future<wip.RemoteObject> _evaluateDartExpressionInFrame(
    wip.DebuggerPausedEvent event,
    String expression,
    int dartLine, {
    bool returnByValue = false,
  }) async {
    var frame = event.getCallFrames().first;
    var result = await _compileDartExpressionInFrame(
      frame,
      expression,
      dartLine,
    );

    if (!result.isSuccess) {
      return _createCompilationError(result);
    }

    // Evaluate the compiled expression.
    try {
      return await debugger.evaluateOnCallFrame(
        frame.callFrameId,
        result.result!,
        returnByValue: returnByValue,
      );
    } on wip.ExceptionDetails catch (e) {
      return _createRuntimeError(e);
    }
  }

  Future<wip.RemoteObject> _evaluateDartExpression(
    String expression, {
    bool returnByValue = false,
  }) async {
    var result = await _compileDartExpression(expression);
    if (!result.isSuccess) {
      return _createCompilationError(result);
    }

    // Find the execution context for the dart app.
    final context = await executionContext.id;

    // Evaluate the compiled expression.
    try {
      return await runtime.evaluate(
        result.result!,
        contextId: context,
        returnByValue: returnByValue,
      );
    } on wip.ExceptionDetails catch (e) {
      return _createRuntimeError(e);
    }
  }

  wip.RemoteObject _createCompilationError(TestCompilationResult result) {
    setup.diagnosticMessages.clear();
    setup.errors.clear();
    return wip.RemoteObject({'error': result.result});
  }

  wip.RemoteObject _createRuntimeError(wip.ExceptionDetails error) {
    return wip.RemoteObject({'error': error.exception!.description});
  }

  /// Generate simple string representation of a RemoteObject that closely
  /// resembles Chrome's console output.
  ///
  /// Examples:
  /// Class: t.C.new {Symbol(C.field): 5, Symbol(_field): 7}
  /// Function: function main() {
  ///             return test.foo(1, {y: 2});
  ///           }
  Future<String> stringifyRemoteObject(wip.RemoteObject obj) async {
    String str;
    switch (obj.type) {
      case 'function':
        str = obj.description ?? '';
        break;
      case 'object':
        if (obj.subtype == 'null') {
          return 'null';
        }
        try {
          var properties =
              await connection.runtime.getProperties(obj, ownProperties: true);
          var filteredProps = <String, String?>{};
          for (var prop in properties) {
            if (prop.value != null && prop.name != '__proto__') {
              filteredProps[prop.name] =
                  await stringifyRemoteObject(prop.value!);
            }
          }
          str = '${obj.description} $filteredProps';
        } catch (e, s) {
          throw StateError('Failed to stringify remote object $obj: $e:$s');
        }
        break;
      default:
        str = '${obj.value}';
        break;
    }
    return str;
  }

  /// Collects local JS variables visible at a breakpoint during evaluation.
  ///
  /// Adapted from webdev/dwds/lib/src/services/expression_evaluator.dart.
  Future<Map<String, String>> _collectScopeVariables(
      wip.WipCallFrame frame) async {
    var jsScope = <String, String>{};

    for (var scope in filterScopes(frame)) {
      var response = await connection.runtime
          .getProperties(scope.object, ownProperties: true);
      for (var prop in response) {
        var propKey = prop.name;
        var propValue = '${prop.value?.value}';
        if (prop.value?.type == 'string') {
          propValue = "'$propValue'";
        } else if (propValue == 'null') {
          propValue = propKey;
        }
        jsScope[propKey] = propValue;
      }
    }
    return jsScope;
  }

  /// Used for matching error text emitted during expression evaluation.
  Matcher _matches(dynamic matcher) {
    if (matcher is Matcher) return matcher;
    if (matcher is! String) throw StateError('Unexpected matcher: $matcher');

    var unindented = RegExp.escape(matcher).replaceAll(RegExp('[ ]+'), '[ ]*');
    return matches(RegExp(unindented, multiLine: true));
  }

  /// Finds the line number in [source] matching [breakpointId].
  ///
  /// A breakpoint ID is found by looking for a line that ends with a comment
  /// of exactly this form: `// Breakpoint: <id>`.
  ///
  /// Throws if it can't find the matching line.
  ///
  /// Adapted from webdev/blob/master/dwds/test/fixtures/context.dart.
  int _findBreakpointLine(String breakpointId) {
    var lines = LineSplitter.split(source).toList();
    var lineNumber =
        lines.indexWhere((l) => l.endsWith('// Breakpoint: $breakpointId'));
    if (lineNumber == -1) {
      throw StateError(
          'Unable to find breakpoint in $input with id: $breakpointId');
    }
    return lineNumber + 1;
  }

  /// Finds the corresponding JS WipLocation for a given line in Dart.
  Future<wip.WipLocation> _jsLocationFromDartLine(
      wip.WipScript script, int dartLine) async {
    var inputSourceUrl = input.pathSegments.last;
    for (var lineEntry in compiler.sourceMap.lines) {
      for (var entry in lineEntry.entries) {
        if (entry.sourceUrlId != null &&
            entry.sourceLine == dartLine &&
            compiler.sourceMap.urls[entry.sourceUrlId!] == inputSourceUrl) {
          return wip.WipLocation.fromValues(script.scriptId, lineEntry.line);
        }
      }
    }
    throw StateError(
        'Unable to extract WIP Location from ${script.url} for Dart line '
        '$dartLine.');
  }
}

/// The execution context in which to do remote evaluations.
///
/// Copied and simplified from webdev/dwds/lib/src/debugging/execution_context.dart.
class ExecutionContext {
  static const _nextContextTimeoutDuration = Duration(milliseconds: 100);
  final wip.WipRuntime _runtime;

  /// Contexts that may contain a Dart application.
  late StreamQueue<int> _contexts;

  int? _id;

  Future<int> get id async {
    if (_id != null) return _id!;
    while (await _contexts.hasNext.timeout(
      _nextContextTimeoutDuration,
      onTimeout: () => false,
    )) {
      final context = await _contexts.next;
      printOnFailure('Trying context: $context');
      try {
        // Confirm the context belongs to a dart application.
        final result = await _runtime.evaluate(
          'dartApplication',
          contextId: context,
          returnByValue: true,
        );
        if (result.value != null) {
          printOnFailure('Found dart app context: $context');
          _id = context;
          break;
        }
      } catch (_) {
        printOnFailure('Failed context: $context, trying again...');
      }
    }

    if (_id == null) {
      throw StateError('No context with the running Dart application.');
    }
    return _id!;
  }

  ExecutionContext(this._runtime) {
    final contextController = StreamController<int>();
    _runtime.onExecutionContextsCleared.listen((_) => _id = null);
    _runtime.onExecutionContextDestroyed.listen((_) => _id = null);
    _runtime.onExecutionContextCreated
        .listen((e) => contextController.add(e.id));
    _contexts = StreamQueue(contextController.stream);
  }
}

/// Filters the provided frame scopes to those that are pertinent for Dart
/// debugging.
///
/// Copied from webdev/dwds/lib/src/debugging/dart_scope.dart.
List<wip.WipScope> filterScopes(wip.WipCallFrame frame) {
  var scopes = frame.getScopeChain().toList();
  // Remove outer scopes up to and including the Dart SDK.
  while (
      scopes.isNotEmpty && !(scopes.last.name?.startsWith('load__') ?? false)) {
    scopes.removeLast();
  }
  if (scopes.isNotEmpty) scopes.removeLast();
  return scopes;
}

String escaped(String path) => path.replaceAll('\\', '\\\\');

Future setBreakpointsActive(wip.WipDebugger debugger, bool active) async {
  await debugger.sendCommand('Debugger.setBreakpointsActive', params: {
    'active': active
  }).timeout(Duration(seconds: 5),
      onTimeout: (() => throw Exception('Unable to set breakpoint activity')));
}

/// The regexes used in dwds to filter out temp variables.
/// Needs to be kept in sync in both repos.
///
/// TODO(annagrin) - use an alternative way to identify
/// synthetic variables.
/// Issue: https://github.com/dart-lang/sdk/issues/44262
final _ddcTemporaryVariableRegExp = RegExp(r'^t(\$[0-9]*)+\w*$');
final _ddcTemporaryTypeVariableRegExp = RegExp(r'^__t[\$\w*]+$');
