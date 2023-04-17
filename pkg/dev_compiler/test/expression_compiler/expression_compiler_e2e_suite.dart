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
import 'package:dev_compiler/src/compiler/shared_command.dart'
    show SharedCompilerOptions;
import 'package:dev_compiler/src/kernel/command.dart';
import 'package:dev_compiler/src/kernel/compiler.dart' show ProgramCompiler;
import 'package:dev_compiler/src/kernel/expression_compiler.dart'
    show ExpressionCompiler;
import 'package:dev_compiler/src/kernel/module_metadata.dart';
import 'package:dev_compiler/src/kernel/target.dart' show DevCompilerTarget;
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:front_end/src/compute_platform_binaries_location.dart' as fe;
import 'package:front_end/src/fasta/incremental_serializer.dart' as fe;
import 'package:kernel/ast.dart' show Component, Library;
import 'package:kernel/target/targets.dart';
import 'package:path/path.dart' as p;
import 'package:source_maps/source_maps.dart' as source_maps;
import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    as wip;

class DevelopmentIncrementalCompiler extends fe.IncrementalCompiler {
  Uri entryPoint;

  DevelopmentIncrementalCompiler(fe.CompilerOptions options, this.entryPoint,
      [Uri? initializeFrom,
      bool? outlineOnly,
      fe.IncrementalSerializer? incrementalSerializer])
      : super(
            fe.CompilerContext(
                fe.ProcessedOptions(options: options, inputs: [entryPoint])),
            initializeFrom,
            outlineOnly,
            incrementalSerializer);

  DevelopmentIncrementalCompiler.fromComponent(fe.CompilerOptions options,
      this.entryPoint, Component componentToInitializeFrom,
      [bool? outlineOnly, fe.IncrementalSerializer? incrementalSerializer])
      : super.fromComponent(
            fe.CompilerContext(
                fe.ProcessedOptions(options: options, inputs: [entryPoint])),
            componentToInitializeFrom,
            outlineOnly,
            incrementalSerializer);
}

class SetupCompilerOptions {
  static final sdkRoot = fe.computePlatformBinariesLocation();
  static final buildRoot =
      fe.computePlatformBinariesLocation(forceBuildDir: true);
  // Unsound .dill files are not longer in the released SDK so this file must be
  // read from the build output directory.
  static final sdkUnsoundSummaryPath =
      buildRoot.resolve('ddc_outline_unsound.dill').toFilePath();
  // Use the outline copied to the released SDK.
  static final sdkSoundSummaryPath =
      sdkRoot.resolve('ddc_outline.dill').toFilePath();
  static final librariesSpecificationUri =
      p.join(p.dirname(p.dirname(getSdkPath())), 'libraries.json');

  final bool legacyCode;
  final List<String> errors = [];
  final List<String> diagnosticMessages = [];
  final ModuleFormat moduleFormat;
  final fe.CompilerOptions options;
  final bool soundNullSafety;

  static fe.CompilerOptions _getOptions(
      {required bool enableAsserts, required bool soundNullSafety}) {
    var options = fe.CompilerOptions()
      ..verbose = false // set to true for debugging
      ..sdkRoot = sdkRoot
      ..target =
          DevCompilerTarget(TargetFlags(soundNullSafety: soundNullSafety))
      ..librariesSpecificationUri = p.toUri('sdk/lib/libraries.json')
      ..omitPlatform = true
      ..sdkSummary =
          p.toUri(soundNullSafety ? sdkSoundSummaryPath : sdkUnsoundSummaryPath)
      ..environmentDefines = addGeneratedVariables({},
          // Disable asserts due to failures to load source and
          // locations on kernel loaded from dill files in DDC.
          // https://github.com/dart-lang/sdk/issues/43986
          enableAsserts: false)
      ..nnbdMode = soundNullSafety ? fe.NnbdMode.Strong : fe.NnbdMode.Weak;
    return options;
  }

  SetupCompilerOptions(
      {bool enableAsserts = true,
      this.soundNullSafety = true,
      this.legacyCode = false,
      this.moduleFormat = ModuleFormat.amd})
      : options = _getOptions(
            soundNullSafety: soundNullSafety, enableAsserts: enableAsserts) {
    options.onDiagnostic = (fe.DiagnosticMessage m) {
      diagnosticMessages.addAll(m.plainTextFormatted);
      if (m.severity == fe.Severity.error) {
        errors.addAll(m.plainTextFormatted);
      }
    };
  }
}

class TestCompilationResult {
  final String? result;
  final bool isSuccess;

  TestCompilationResult(this.result, this.isSuccess);
}

class TestCompiler {
  final SetupCompilerOptions setup;
  final Component component;
  final ExpressionCompiler evaluator;
  final ModuleMetadata? metadata;
  final source_maps.SingleMapping sourceMap;

  TestCompiler._(this.setup, this.component, this.evaluator, this.metadata,
      this.sourceMap);

  static Future<TestCompiler> init(SetupCompilerOptions setup,
      {required Uri input,
      required Uri output,
      Uri? packages,
      Map<String, bool> experiments = const {}}) async {
    // Initialize the incremental compiler and module component.
    // TODO: extend this for multi-module compilations by storing separate
    // compilers/components/names per module.
    setup.options.packagesFileUri = packages;
    setup.options.explicitExperimentalFlags.addAll(fe.parseExperimentalFlags(
        experiments,
        onError: (message) => throw Exception(message)));
    var compiler = DevelopmentIncrementalCompiler(setup.options, input);
    var compilerResult = await compiler.computeDelta();
    var component = compilerResult.component;
    component.computeCanonicalNames();
    // Initialize DDC.
    var moduleName = p.basenameWithoutExtension(output.toFilePath());

    var classHierarchy = compilerResult.classHierarchy!;
    var compilerOptions = SharedCompilerOptions(
        replCompile: true,
        moduleName: moduleName,
        experiments: experiments,
        soundNullSafety: setup.soundNullSafety,
        emitDebugMetadata: true);
    var coreTypes = compilerResult.coreTypes;

    final importToSummary = Map<Library, Component>.identity();
    final summaryToModule = Map<Component, String>.identity();
    for (var lib in component.libraries) {
      importToSummary[lib] = component;
    }
    summaryToModule[component] = moduleName;

    var kernel2jsCompiler = ProgramCompiler(component, classHierarchy,
        compilerOptions, importToSummary, summaryToModule,
        coreTypes: coreTypes);
    var module = kernel2jsCompiler.emitModule(component);

    // Perform a full compile, writing the compiled JS + sourcemap.
    var code = jsProgramToCode(
      module,
      setup.moduleFormat,
      inlineSourceMap: compilerOptions.inlineSourceMap,
      buildSourceMap: compilerOptions.sourceMap,
      emitDebugMetadata: compilerOptions.emitDebugMetadata,
      emitDebugSymbols: compilerOptions.emitDebugSymbols,
      jsUrl: '$output',
      mapUrl: '$output.map',
      compiler: kernel2jsCompiler,
      component: component,
    );
    var codeBytes = utf8.encode(code.code);
    var sourceMapBytes = utf8.encode(json.encode(code.sourceMap));

    File(output.toFilePath()).writeAsBytesSync(codeBytes);
    File('${output.toFilePath()}.map').writeAsBytesSync(sourceMapBytes);

    // Save the expression evaluator for future evaluations.
    var evaluator = ExpressionCompiler(
      setup.options,
      setup.moduleFormat,
      setup.errors,
      compiler,
      kernel2jsCompiler,
      component,
    );

    if (setup.errors.isNotEmpty) {
      throw Exception('Compilation failed with: ${setup.errors}');
    }
    setup.diagnosticMessages.clear();

    var sourceMap = source_maps.SingleMapping.fromJson(
        code.sourceMap!.cast<String, dynamic>());
    return TestCompiler._(
        setup, component, evaluator, code.metadata, sourceMap);
  }

  Future<TestCompilationResult> compileExpression(
      {required Uri input,
      required int line,
      required int column,
      required Map<String, String> scope,
      required String expression}) async {
    var libraryUri = metadataForLibraryUri(input);
    var jsExpression = await evaluator.compileExpressionToJs(
        libraryUri.importUri, line, column, scope, expression);
    if (setup.errors.isNotEmpty) {
      jsExpression = setup.errors.toString().replaceAll(
          RegExp(
              r'org-dartlang-debug:synthetic_debug_expression:[0-9]*:[0-9]*:'),
          '');

      return TestCompilationResult(jsExpression, false);
    }

    return TestCompilationResult(jsExpression, true);
  }

  LibraryMetadata metadataForLibraryUri(Uri libraryUri) =>
      metadata!.libraries.entries
          .firstWhere((entry) => entry.value.fileUri == '$libraryUri')
          .value;
}

class TestDriver {
  final browser.Chrome chrome;
  final Directory chromeDir;
  final wip.WipConnection connection;
  final wip.WipDebugger debugger;
  late TestCompiler compiler;
  late Uri htmlBootstrapper;
  late Uri input;
  late Uri output;
  late Uri packagesFile;
  late String preemptiveBp;
  late SetupCompilerOptions setup;
  late String source;
  late Directory testDir;

  TestDriver._(this.chrome, this.chromeDir, this.connection, this.debugger);

  /// Initializes a Chrome browser instance, tab connection, and debugger.
  static Future<TestDriver> init() async {
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

    var debugger = connection.debugger;
    await debugger.enable().timeout(Duration(seconds: 5),
        onTimeout: (() => throw Exception('Unable to enable WIP debugger')));
    return TestDriver._(chrome, chromeDir, connection, debugger);
  }

  /// Must be called when testing a new Dart program.
  ///
  /// Depends on SDK artifacts (such as the sound and unsound dart_sdk.js
  /// files) generated from the 'dartdevc_test' target.
  Future<void> initSource(SetupCompilerOptions setup, String source,
      {Map<String, bool> experiments = const {}}) async {
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
    compiler = await TestCompiler.init(setup,
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
        var dartSdkPath = escaped(SetupCompilerOptions.buildRoot
            .resolve(p.join(
                'gen',
                'utils',
                'dartdevc',
                setup.soundNullSafety ? 'sound' : 'kernel',
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
  var sound = ${setup.soundNullSafety};
  var sdk = dart_library.import('dart_sdk');

  if (!sound) {
    sdk.dart.weakNullSafetyWarnings(false);
    sdk.dart.weakNullSafetyErrors(false);
  }
  sdk.dart.nonNullAsserts(true);
  sdk.dart.nativeNonNullAsserts(true);
  sdk._debugger.registerDevtoolsFormatter();
  dart_library.start('$appName', '$uuid', '$moduleName', '$mainLibraryName',
    false);
</script>
''');
        break;
      case ModuleFormat.amd:
        var dartSdkPath = escaped(SetupCompilerOptions.buildRoot
            .resolve(p.join('gen', 'utils', 'dartdevc',
                setup.soundNullSafety ? 'sound' : 'kernel', 'amd', 'dart_sdk'))
            .toFilePath());
        if (!File('$dartSdkPath.js').existsSync()) {
          throw Exception('Unable to find Dart SDK at $dartSdkPath.js');
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
        'dart_sdk': '$dartSdkPath',
        '$moduleName': '$outputPath'
    },
    waitSeconds: 15
  });
  var sound = ${setup.soundNullSafety};

  require(['dart_sdk', '$moduleName'],
        function(sdk, app) {
    'use strict';

    if (!sound) {
    sdk.dart.weakNullSafetyWarnings(false);
    sdk.dart.weakNullSafetyErrors(false);
    }
    sdk.dart.nonNullAsserts(true);
    sdk.dart.nativeNonNullAsserts(true);
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
    await debugger.removeBreakpoint(preemptiveBp);
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
    final consoleSub =
        debugger.connection.runtime.onConsoleAPICalled.listen(print);

    // Fail on exceptions in JS code.
    await debugger.setPauseOnExceptions(wip.PauseState.uncaught);
    final pauseSub = debugger.onPaused.listen((wip.DebuggerPausedEvent e) {
      if (e.reason == 'exception' || e.reason == 'assert') {
        throw Exception('Uncaught exception in JS code: ${e.data}');
      }
    });

    final scriptController = StreamController<wip.ScriptParsedEvent>();
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
        throw Exception('Uncaught exception in JS code: ${e.data}');
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

  Future<Map<String, String>> getScope(String breakpointId) async {
    return await _onBreakpoint(breakpointId, onPause: (event) async {
      // Retrieve the call frame and its scope variables.
      var frame = event.getCallFrames().first;
      return await _collectScopeVariables(frame);
    });
  }

  Future<void> check(
      {required String breakpointId,
      required String expression,
      String? expectedError,
      String? expectedResult}) async {
    assert(expectedError == null || expectedResult == null,
        'Cannot expect both an error and result.');

    var dartLine = _findBreakpointLine(breakpointId);
    return await _onBreakpoint(breakpointId, onPause: (event) async {
      // Retrieve the call frame and its scope variables.
      var frame = event.getCallFrames().first;
      var scope = await _collectScopeVariables(frame);

      // Perform an incremental compile.
      var result = await compiler.compileExpression(
          input: input,
          line: dartLine,
          column: 1,
          scope: scope,
          expression: expression);

      if (expectedError != null) {
        expect(
            result,
            const TypeMatcher<TestCompilationResult>().having(
                (_) => result.result, 'result', _matches(expectedError)));
        setup.diagnosticMessages.clear();
        setup.errors.clear();
        return;
      }

      if (!result.isSuccess) {
        throw Exception(
            'Unexpected expression evaluation failure:\n${result.result}');
      }

      // Evaluate the compiled expression.
      var evalResult = await debugger.evaluateOnCallFrame(
          frame.callFrameId, result.result!,
          returnByValue: false);

      var value = await stringifyRemoteObject(evalResult);

      expect(
          result,
          const TypeMatcher<TestCompilationResult>()
              .having((_) => value, 'result', _matches(expectedResult!)));
    });
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
        var properties =
            await connection.runtime.getProperties(obj, ownProperties: true);
        var filteredProps = <String, String?>{};
        for (var prop in properties) {
          if (prop.value != null && prop.name != '__proto__') {
            filteredProps[prop.name] = await stringifyRemoteObject(prop.value!);
          }
        }
        str = '${obj.description} $filteredProps';
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
        var propValue = '${prop.value!.value}';
        if (prop.value!.type == 'string') {
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
  Matcher _matches(String text) {
    var unindented = RegExp.escape(text).replaceAll(RegExp('[ ]+'), '[ ]*');
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
