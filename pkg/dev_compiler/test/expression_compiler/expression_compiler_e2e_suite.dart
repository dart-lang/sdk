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
import 'package:source_maps/source_maps.dart';
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
  wip.WipScript? _script;
  Uri? inputPart;
  late Uri output;
  late Uri packagesFile;
  late SetupCompilerOptions setup;
  late String source;
  String? partSource;
  late Directory testDir;
  late String dartSdkPath;
  final TimeoutTracker tracker = TimeoutTracker();

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
    String? partSource,
  }) =>
      tracker._watch(
          'init-source',
          () => _initSource(setup, source,
              experiments: experiments, partSource: partSource));

  Future<void> _initSource(
    SetupCompilerOptions setup,
    String source, {
    Map<String, bool> experiments = const {},
    String? partSource,
  }) async {
    // Perform setup sanity checks.
    var summaryPath = setup.options.sdkSummary!.toFilePath();
    if (!File(summaryPath).existsSync()) {
      throw StateError('Unable to find SDK summary at path: $summaryPath.');
    }
    this.setup = setup;
    this.source = source;
    this.partSource = partSource;
    testDir = chromeDir.createTempSync('ddc_eval_test');
    var scriptPath = Platform.script.normalizePath().toFilePath();
    var ddcPath = p.dirname(p.dirname(p.dirname(scriptPath)));
    output = testDir.uri.resolve('test.js');
    _script = null;
    input = testDir.uri.resolve('test.dart');
    File(input.toFilePath())
      ..createSync()
      ..writeAsStringSync(source);
    if (partSource != null) {
      inputPart = testDir.uri.resolve('part.dart');
      File(inputPart!.toFilePath())
        ..createSync()
        ..writeAsStringSync(partSource);
    } else {
      inputPart = null;
    }

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
                'ddc',
                'dart_sdk.js'))
            .toFilePath());
        if (!File(dartSdkPath).existsSync()) {
          throw Exception('Unable to find Dart SDK at $dartSdkPath');
        }
        var dartLibraryPath = escaped(
            p.join(ddcPath, 'lib', 'js', 'ddc', 'ddc_module_loader.js'));
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
  // Unlike the typical app bootstraper, we delay calling main until all
  // breakpoints are setup.
  let scheduleMain = () => {
    dart_library.start('$appName', '$uuid', '$moduleName', '$mainLibraryName', false);
  };
</script>
''');
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
  let scheduleMainCalled = false;
  // Unlike the typical app bootstraper, we delay calling main until all
  // breakpoints are setup.
  // Because AMD runs the initialization asynchronously, this may be called
  // before require.js calls the initialization below.
  let scheduleMain = () => {
    scheduleMainCalled = true;
  };
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
    scheduleMain = () => {
      app.$mainLibraryName.main([]);
    };
    // Call main if the test harness already requested it.
    if (scheduleMainCalled) scheduleMain();
  });
</script>
''');

      default:
        throw Exception('Unsupported module format for SDK evaluation tests: '
            '${setup.moduleFormat}');
    }

    await setBreakpointsActive(debugger, true);
  }

  Future<void> finish() async {
    tracker._showReport();
    await chrome.close();
    // Attempt to clean up the temporary directory.
    // On windows sometimes the process has not released the directory yet so
    // retry with an exponential backoff.
    var deleteAttempts = 0;
    while (await chromeDir.exists()) {
      deleteAttempts++;
      try {
        await chromeDir.delete(recursive: true);
      } on FileSystemException catch (e) {
        print('Error trying to delete chromeDir: $e');
        if (deleteAttempts > 3) return;
        var delayMs = pow(10, deleteAttempts).floor();
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  Future<void> cleanupTest() async {
    await setBreakpointsActive(debugger, false);
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

  /// Ensures the current [input] script is loaded.
  ///
  /// The first time an input is found, this will navigate to the bootstrap page
  /// set up by [initSource] and return the script corresponding to [input].
  /// Any subsequent test that uses the same input will not trigger a new
  /// navigation, but reuse the existing script on the page.
  ///
  /// Reusing the script is possible because the bootstrap does not run `main`,
  /// but instead lets the test harness start main when it has prepared all
  /// breakpoints needed for the test.
  Future<wip.WipScript> _loadScript() =>
      tracker._watch('load-script', () => _loadScriptHelper());

  Future<wip.WipScript> _loadScriptHelper() async {
    if (_script != null) return Future.value(_script);
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
      // Navigate to the page that will load the application code.
      // Note: the bootstrapper does not invoke the application main, but
      // exposes a function that can be called to do so.
      await connection.page.navigate('$htmlBootstrapper').timeout(
          Duration(seconds: 5),
          onTimeout: (() => throw Exception(
              'Unable to navigate to page bootstrap script: $htmlBootstrapper')));

      // Poll until the script is found, or timeout after a few seconds.
      return _script = (await tracker._watch(
              'find-script',
              () => scriptController.stream.first.timeout(Duration(seconds: 10),
                  onTimeout: (() => throw Exception(
                      'Unable to find JS script corresponding to test file '
                      '$output in ${debugger.scripts}.')))))
          .script;
    } finally {
      await scriptSub.cancel();
      await consoleSub.cancel();
      await scriptController.close();
      await pauseSub.cancel();
    }
  }

  /// Uses the debugger API to trigger the execution of the app.
  Future<wip.RemoteObject> _scheduleMain() async {
    final context = await executionContext.id;
    return runtime
        .evaluate('scheduleMain()', contextId: context)
        .catchError((Object e) {
      printOnFailure(e is wip.ExceptionDetails
          ? 'Exception when calling scheduleMain: ${e.json}!'
          : 'Uncaught exception during scheduleMain: $e');
      throw e;
    });
  }

  /// Load the script, invoke it's main method, and run [onPause] when the app
  /// pauses on [breakpointId].
  ///
  /// Internally, this navigates to the bootstrapper page or ensures that the
  /// bootstrapper page has already been loaded. The page only loads code
  /// without running the DDC app main method. Once the resouces are loaded we
  /// wait until after the breakpoint is registered before scheduling a call to
  /// the app's main method.
  Future<T> _onBreakpoint<T>(String breakpointId,
      {required Future<T> Function(wip.DebuggerPausedEvent) onPause}) async {
    final consoleSub = debugger.connection.runtime.onConsoleAPICalled
        .listen((e) => printOnFailure('$e'));

    // Used to reflect when [breakpointId] is hit.
    final breakpointCompleter = Completer<wip.DebuggerPausedEvent>();
    final pauseSub = debugger.onPaused.listen((e) {
      if (e.reason == 'exception' || e.reason == 'assert') {
        breakpointCompleter
            .completeError('Uncaught exception in JS code: ${e.data}');
        throw Exception('Script failed while waiting for a breakpoint to hit.');
      }
      breakpointCompleter.complete(e);
    });

    final script = await _loadScript();

    // Breakpoint at the first WIP location mapped from its Dart line.
    var dartLine = _findBreakpointLine(breakpointId);
    var location =
        await _jsLocationFromDartLine(script, dartLine.value, dartLine.key);

    var bp = await tracker._watch(
        'set-breakpoint', () => debugger.setBreakpoint(location));
    final atBreakpoint = breakpointCompleter.future;
    try {
      // Now that the breakpoint is set, the application can start running.
      unawaited(_scheduleMain());

      final event = await tracker._watch(
          'pause-event-for-line',
          () => atBreakpoint.timeout(Duration(seconds: 10),
              onTimeout: () => throw Exception(
                  'Unable to find JS pause event corresponding to line '
                  '($dartLine -> $location) in $output.')));
      return await onPause(event);
    } finally {
      await pauseSub.cancel();
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
      await _scheduleMain();
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
    return await _onBreakpoint(breakpointId, onPause: (event) async {
      var result = await _evaluateDartExpressionInFrame(
        event,
        expression,
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
          dynamic expectedResult}) =>
      tracker._watch(
          'check-in-frame',
          () => _checkInFrame(
              breakpointId: breakpointId,
              expression: expression,
              expectedError: expectedError,
              expectedResult: expectedResult));

  Future<void> _checkInFrame(
      {required String breakpointId,
      required String expression,
      dynamic expectedError,
      dynamic expectedResult}) async {
    assert(expectedError == null || expectedResult == null,
        'Cannot expect both an error and result.');

    return await _onBreakpoint(breakpointId, onPause: (event) async {
      var evalResult = await _evaluateDartExpressionInFrame(
        event,
        expression,
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

  /// Evaluates a dart [expression] under the scope of [libraryUri] without
  /// a breakpoint and validates the result.
  ///
  /// When [libraryUri] is ommitted, the expression is evaluated in the [input]
  /// library.
  ///
  /// [expectedResult] is the JSON for the returned remote object.
  /// [expectedError] is the error string if the error is expected.
  Future<void> check(
      {required String expression,
      Uri? libraryUri,
      dynamic expectedError,
      dynamic expectedResult}) async {
    assert(expectedError == null || expectedResult == null,
        'Cannot expect both an error and result.');

    return await _whileRunning(body: () async {
      var evalResult =
          await _evaluateDartExpression(expression, libraryUri: libraryUri);

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
      wip.WipCallFrame frame, String expression) async {
    // Retrieve the call frame and its scope variables.
    var scope = await _collectScopeVariables(frame);
    var searchLine = frame.location.lineNumber;
    var searchColumn = frame.location.columnNumber;
    var inputSourceUrl = input.pathSegments.last;
    var inputPartSourceUrl = inputPart?.pathSegments.last;
    // package:dwds - which I think is what actually provides line and column
    // when debugging e.g. via flutter - basically finds the closest point
    // before or on the line/column, so we do the same here.
    // If there is no javascript column we pick the smallest column value on
    // that line.
    TargetEntry? best;
    for (var lineEntry in compiler.sourceMap.lines) {
      if (lineEntry.line != searchLine) continue;
      for (var entry in lineEntry.entries) {
        if (entry.sourceUrlId != null) {
          var sourceMapUrl = compiler.sourceMap.urls[entry.sourceUrlId!];
          if (sourceMapUrl == inputSourceUrl ||
              sourceMapUrl == inputPartSourceUrl) {
            if (best == null) {
              best = entry;
            } else if (searchColumn != null &&
                entry.column > best.column &&
                entry.column <= searchColumn) {
              best = entry;
            } else if (searchColumn == null && entry.column < best.column) {
              best = entry;
            }
          }
        }
      }
    }
    if (best == null || best.sourceLine == null || best.sourceColumn == null) {
      throw StateError('Unable to find the matching dart line and column '
          ' for where the javascript paused.');
    }

    final bestUrl = compiler.sourceMap.urls[best.sourceUrlId!];
    var scriptUrl = input;
    if (bestUrl == inputPartSourceUrl) {
      scriptUrl = inputPart!;
    }

    // Convert from 0-indexed to 1-indexed.
    var dartLine = best.sourceLine! + 1;
    var dartColumn = best.sourceColumn! + 1;

    // Perform an incremental compile.
    return await compiler.compileExpression(
      libraryUri: input,
      scriptUri: scriptUrl,
      line: dartLine,
      column: dartColumn,
      scope: scope,
      expression: expression,
    );
  }

  Future<TestCompilationResult> _compileDartExpression(
      String expression, Uri? libraryUri) async {
    // Perform an incremental compile.
    return await compiler.compileExpression(
      libraryUri: libraryUri ?? input,
      line: 1,
      column: 1,
      scope: {},
      expression: expression,
    );
  }

  Future<wip.RemoteObject> _evaluateDartExpressionInFrame(
    wip.DebuggerPausedEvent event,
    String expression, {
    bool returnByValue = false,
  }) async {
    var frame = event.getCallFrames().first;
    var result = await _compileDartExpressionInFrame(
      frame,
      expression,
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
    Uri? libraryUri,
    bool returnByValue = false,
  }) async {
    var result = await _compileDartExpression(expression, libraryUri);
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
    final type = obj.json.containsKey('type') ? obj.type : null;
    switch (type) {
      case 'function':
        str = obj.description ?? '';
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
      default:
        str = '${obj.value}';
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

  /// Finds the first line number in [source] or [partSource] matching
  /// [breakpointId].
  ///
  /// A breakpoint ID is found by looking for a line that ends with a comment
  /// of exactly this form: `// Breakpoint: <id>`.
  ///
  /// Throws if it can't find a matching line.
  ///
  /// The returned map entry is the uri (key) and the 1-indexed line number of
  /// the comment (value).
  /// Note that we often put the comment on the line *before* where we actually
  /// want the breakpoint, and that the value can thus be seen as being that
  /// line but then being 0-indexed.
  ///
  /// Adapted from webdev/blob/master/dwds/test/fixtures/context.dart.
  MapEntry<Uri, int> _findBreakpointLine(String breakpointId) {
    var lineNumber = _findBreakpointLineImpl(breakpointId, source);
    if (lineNumber >= 0) {
      return MapEntry(input, lineNumber + 1);
    }
    if (partSource != null) {
      lineNumber = _findBreakpointLineImpl(breakpointId, partSource!);
      if (lineNumber >= 0) {
        return MapEntry(inputPart!, lineNumber + 1);
      }
    }
    throw StateError(
        'Unable to find breakpoint in $input with id: $breakpointId');
  }

  /// Finds the 0-indexed line number in [source] for the given breakpoint id.
  static int _findBreakpointLineImpl(String breakpointId, String source) {
    var lines = LineSplitter.split(source).toList();
    return lines.indexWhere((l) => l.endsWith('// Breakpoint: $breakpointId'));
  }

  /// Finds the corresponding JS WipLocation for a given line in Dart.
  /// The input [dartLine] is 1-indexed, but really refers to the following line
  /// meaning that it talks about the following line in a 0-indexed manner.
  Future<wip.WipLocation> _jsLocationFromDartLine(
      wip.WipScript script, int dartLine, Uri lineIn) async {
    var inputSourceUrl = lineIn.pathSegments.last;
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

/// Records timing statistics from the test driver.
///
/// A few steps in the test driver need to wait for a response from the browser.
/// These are set up with a timeout of usually 5 seconds, but the total time may
/// vary by machine and architecture. Occationally tests fail with flaky
/// failures due to a timeout that is too short.
///
/// We use this class to help log information from flaky failures that can
/// inform us whether the timeout is accurate and how often we are approaching
/// it.
///
/// The driver logic only watches a couple tasks, focusing on big parts of the
/// framework or tasks that have historically hit timeouts in the CI bots.
class TimeoutTracker {
  /// Stores data for each key.
  final _data = <String, List<int>>{};

  /// Track how long an asynchronous [task] takes and record it under [key].
  Future<T> _watch<T>(String key, Future<T> Function() task) {
    final watch = Stopwatch()..start();
    return task().then((v) {
      _addOneRecord(key, watch.elapsedMilliseconds);
      return v;
    });
  }

  /// Record under [key] a single event that took [milliseconds].
  ///
  /// This makes an incremental update to the aggreagate average, max, and count
  /// values in [_data].
  void _addOneRecord(String key, int milliseconds) {
    (_data[key] ??= []).add(milliseconds);
  }

  /// Prints to stdout a summary of the data tracked so far.
  void _showReport() {
    print('Fine-grain timeout data:');
    _data.forEach((key, values) {
      values.sort();
      final total = values.length;
      final sum = values.reduce((a, b) => a + b);
      final max = values.last;
      final p50 = values[(values.length * 0.5).toInt()];
      final p90 = values[(values.length * 0.9).toInt()];
      final average = sum ~/ total;
      print('$key: '
          '${average}ms (avg), '
          '${p50}ms (p50), '
          '${p90}ms (p90), '
          '${max}ms (max), '
          '$total (total)');
    });
  }
}
