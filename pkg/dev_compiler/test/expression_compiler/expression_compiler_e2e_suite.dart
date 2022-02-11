// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, Platform;

import 'package:browser_launcher/browser_launcher.dart' as browser;
import 'package:dev_compiler/dev_compiler.dart';
import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:dev_compiler/src/kernel/command.dart';
import 'package:dev_compiler/src/kernel/module_metadata.dart';
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
      [Uri initializeFrom,
      bool outlineOnly,
      fe.IncrementalSerializer incrementalSerializer])
      : super(
            fe.CompilerContext(
                fe.ProcessedOptions(options: options, inputs: [entryPoint])),
            initializeFrom,
            outlineOnly,
            incrementalSerializer);

  DevelopmentIncrementalCompiler.fromComponent(fe.CompilerOptions options,
      this.entryPoint, Component componentToInitializeFrom,
      [bool outlineOnly, fe.IncrementalSerializer incrementalSerializer])
      : super.fromComponent(
            fe.CompilerContext(
                fe.ProcessedOptions(options: options, inputs: [entryPoint])),
            componentToInitializeFrom,
            outlineOnly,
            incrementalSerializer);
}

class SetupCompilerOptions {
  static final sdkRoot = fe.computePlatformBinariesLocation();
  static final sdkUnsoundSummaryPath =
      p.join(sdkRoot.toFilePath(), 'ddc_sdk.dill');
  static final sdkSoundSummaryPath =
      p.join(sdkRoot.toFilePath(), 'ddc_outline_sound.dill');
  static final librariesSpecificationUri =
      p.join(p.dirname(p.dirname(getSdkPath())), 'libraries.json');

  final bool legacyCode;
  final List<String> errors = [];
  final List<String> diagnosticMessages = [];
  final ModuleFormat moduleFormat;
  final fe.CompilerOptions options;
  final bool soundNullSafety;

  static fe.CompilerOptions _getOptions(bool soundNullSafety) {
    var options = fe.CompilerOptions()
      ..verbose = false // set to true for debugging
      ..sdkRoot = sdkRoot
      ..target = DevCompilerTarget(TargetFlags())
      ..librariesSpecificationUri = p.toUri('sdk/lib/libraries.json')
      ..omitPlatform = true
      ..sdkSummary =
          p.toUri(soundNullSafety ? sdkSoundSummaryPath : sdkUnsoundSummaryPath)
      ..environmentDefines = const {}
      ..nnbdMode = soundNullSafety ? fe.NnbdMode.Strong : fe.NnbdMode.Weak;
    return options;
  }

  SetupCompilerOptions(
      {this.soundNullSafety = true,
      this.legacyCode = false,
      this.moduleFormat = ModuleFormat.amd})
      : options = _getOptions(soundNullSafety) {
    options.onDiagnostic = (fe.DiagnosticMessage m) {
      diagnosticMessages.addAll(m.plainTextFormatted);
      if (m.severity == fe.Severity.error) {
        errors.addAll(m.plainTextFormatted);
      }
    };
  }
}

class TestCompilationResult {
  final String result;
  final bool isSuccess;

  TestCompilationResult(this.result, this.isSuccess);
}

class TestCompiler {
  final SetupCompilerOptions setup;
  final Component component;
  final ExpressionCompiler evaluator;
  final ModuleMetadata metadata;
  final source_maps.SingleMapping sourceMap;

  TestCompiler._(this.setup, this.component, this.evaluator, this.metadata,
      this.sourceMap);

  static Future<TestCompiler> init(SetupCompilerOptions setup,
      {Uri input, Uri output, Uri packages}) async {
    // Initialize the incremental compiler and module component.
    // TODO: extend this for multi-module compilations by storing separate
    // compilers/components/names per module.
    setup.options.packagesFileUri = packages;
    var compiler = DevelopmentIncrementalCompiler(setup.options, input);
    var compilerResult = await compiler.computeDelta();
    var component = compilerResult.component;
    component.computeCanonicalNames();
    // Initialize DDC.
    var moduleName = p.basenameWithoutExtension(output.toFilePath());

    var classHierarchy = compilerResult.classHierarchy;
    var compilerOptions = SharedCompilerOptions(
        replCompile: true,
        moduleName: moduleName,
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

    var sourceMap = source_maps.SingleMapping.fromJson(code.sourceMap);
    return TestCompiler._(
        setup, component, evaluator, code.metadata, sourceMap);
  }

  Future<TestCompilationResult> compileExpression(
      {Uri input,
      int line,
      int column,
      Map<String, String> scope,
      String expression}) async {
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
      metadata.libraries.entries
          .firstWhere((entry) => entry.value.fileUri == '$libraryUri')
          .value;
}

class TestDriver {
  final browser.Chrome chrome;
  final Directory chromeDir;
  final wip.WipConnection connection;
  final wip.WipDebugger debugger;
  TestCompiler compiler;
  Uri htmlBootstrapper;
  Uri input;
  String moduleFormatString;
  Uri output;
  Uri packagesFile;
  String preemptiveBp;
  SetupCompilerOptions setup;
  String source;
  Directory testDir;

  TestDriver._(this.chrome, this.chromeDir, this.connection, this.debugger);

  /// Initializes a Chrome browser instance, tab connection, and debugger.
  static Future<TestDriver> init() async {
    // Create a temporary directory for holding Chrome tests.
    var chromeDir = Directory.systemTemp.createTempSync('ddc_eval_test_anchor');

    // Try to start Chrome on an empty page with a single empty tab.
    // TODO(#45713): Headless Chrome crashes the Windows bots, so run in
    // standard mode until it's fixed.
    browser.Chrome chrome;
    var retries = 3;
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

    // Connect to the first 'normal' tab.
    var tab = await chrome.chromeConnection
        .getTab((tab) => !tab.isBackgroundPage && !tab.isChromeExtension);
    if (tab == null) {
      throw Exception('Unable to connect to Chrome tab');
    }

    var connection = await tab.connect().timeout(Duration(seconds: 5),
        onTimeout: () => throw Exception('Unable to connect to WIP tab'));

    await connection.page.enable().timeout(Duration(seconds: 5),
        onTimeout: () => throw Exception('Unable to enable WIP tab page'));

    var debugger = connection.debugger;
    await debugger.enable().timeout(Duration(seconds: 5),
        onTimeout: () => throw Exception('Unable to enable WIP debugger'));
    return TestDriver._(chrome, chromeDir, connection, debugger);
  }

  /// Must be called when testing a new Dart program.
  ///
  /// Depends on SDK artifacts (such as the sound and unsound dart_sdk.js
  /// files) generated from the 'dartdevc_test' target.
  Future<void> initSource(SetupCompilerOptions setup, String source) async {
    // Perform setup sanity checks.
    var summaryPath = setup.options.sdkSummary.toFilePath();
    if (!File(summaryPath).existsSync()) {
      throw StateError('Unable to find SDK summary at path: $summaryPath.');
    }

    // Prepend legacy Dart version comment.
    if (setup.legacyCode) source = '// @dart = 2.11\n\n$source';
    this.setup = setup;
    this.source = source;
    testDir = chromeDir.createTempSync('ddc_eval_test');
    var buildDir = p.dirname(p.dirname(p.dirname(Platform.resolvedExecutable)));
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
        input: input, output: output, packages: packagesFile);

    htmlBootstrapper = testDir.uri.resolve('bootstrapper.html');
    var bootstrapFile = File(htmlBootstrapper.toFilePath())..createSync();
    var moduleName = compiler.metadata.name;
    var mainLibraryName = compiler.metadataForLibraryUri(input).name;

    switch (setup.moduleFormat) {
      case ModuleFormat.ddc:
        moduleFormatString = 'ddc';
        var dartSdkPath = escaped(p.join(
            buildDir,
            'gen',
            'utils',
            'dartdevc',
            setup.soundNullSafety ? 'sound' : 'kernel',
            'legacy',
            'dart_sdk.js'));
        if (!File(dartSdkPath).existsSync()) {
          throw Exception('Unable to find Dart SDK at $dartSdkPath');
        }
        var dartLibraryPath =
            escaped(p.join(ddcPath, 'lib', 'js', 'legacy', 'dart_library.js'));
        var outputPath = output.toFilePath();
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
  dart_library.start('$moduleName', '$mainLibraryName');
</script>
''');
        break;
      case ModuleFormat.amd:
        moduleFormatString = 'amd';
        var dartSdkPath = escaped(p.join(buildDir, 'gen', 'utils', 'dartdevc',
            setup.soundNullSafety ? 'sound' : 'kernel', 'amd', 'dart_sdk'));
        if (!File('$dartSdkPath.js').existsSync()) {
          throw Exception('Unable to find Dart SDK at $dartSdkPath.js');
        }
        var requirePath = escaped(p.join(buildDir, 'dart-sdk', 'lib',
            'dev_compiler', 'kernel', 'amd', 'require.js'));
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
        throw Exception(
            'Unsupported module format for SDK evaluation tests: ${setup.moduleFormat}');
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
    await chrome?.close();
    // Chrome takes a while to free its claim on chromeDir, so wait a bit.
    await Future.delayed(Duration(milliseconds: 500));
    chromeDir?.deleteSync(recursive: true);
  }

  Future<void> cleanupTest() async {
    await setBreakpointsActive(debugger, false);
    await debugger.removeBreakpoint(preemptiveBp);
    setup.diagnosticMessages.clear();
    setup.errors.clear();
  }

  Future<void> check(
      {String breakpointId,
      String expression,
      String expectedError,
      String expectedResult}) async {
    assert(expectedError == null || expectedResult == null,
        'Cannot expect both an error and result.');

    // The next two pause events will correspond to:
    // 1) the initial preemptive breakpoint and
    // 2) the breakpoint at the specified ID
    final pauseController = StreamController<wip.DebuggerPausedEvent>();
    var pauseSub = debugger.onPaused.listen(pauseController.add);

    final scriptController = StreamController<wip.ScriptParsedEvent>();
    var scriptSub = debugger.onScriptParsed.listen((event) {
      if (event.script.url == '$output') {
        scriptController.add(event);
      }
    });

    // Navigate from the empty page and immediately pause on the preemptive
    // breakpoint.
    await connection.page.navigate('$htmlBootstrapper').timeout(
        Duration(seconds: 5),
        onTimeout: () => throw Exception(
            'Unable to navigate to page bootstrap script: $htmlBootstrapper'));

    // Poll until the script is found, or timeout after a few seconds.
    var script = (await scriptController.stream.first.timeout(
            Duration(seconds: 5),
            onTimeout: () => throw Exception(
                'Unable to find JS script corresponding to test file $output in ${debugger.scripts}.')))
        .script;
    await scriptSub.cancel();
    await scriptController.close();

    // Breakpoint at the first WIP location mapped from its Dart line.
    var dartLine = _findBreakpointLine(breakpointId);
    var location = await _jsLocationFromDartLine(script, dartLine);
    var bp = await debugger.setBreakpoint(location);

    // Continue to the next breakpoint, ignoring the first pause event since it
    // corresponds to the preemptive URI breakpoint made prior to page
    // navigation.
    await debugger.resume();
    final event = await pauseController.stream
        .skip(1)
        .timeout(Duration(seconds: 5),
            onTimeout: (event) => throw Exception(
                'Unable to find JS preemptive pause event in $output.'))
        .first
        .timeout(Duration(seconds: 5),
            onTimeout: () => throw Exception(
                'Unable to find JS pause event corresponding to line ($dartLine -> $location) in $output.'));
    await pauseSub.cancel();
    await pauseController.close();

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
          const TypeMatcher<TestCompilationResult>()
              .having((_) => result.result, 'result', _matches(expectedError)));
      setup.diagnosticMessages.clear();
      setup.errors.clear();
      return;
    }

    if (!result.isSuccess) {
      throw Exception(
          'Unexpected expression evaluation failure:\n${result.result}');
    }

    var evalResult = await debugger.evaluateOnCallFrame(
        frame.callFrameId, result.result,
        returnByValue: false);

    await debugger.removeBreakpoint(bp.breakpointId);
    var value = await stringifyRemoteObject(evalResult);

    // Resume execution to the end of the current script
    await debugger.resume();

    expect(
        result,
        const TypeMatcher<TestCompilationResult>()
            .having((_) => value, 'result', _matches(expectedResult)));
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
        str = obj.description;
        break;
      case 'object':
        if (obj.subtype == 'null') {
          return 'null';
        }
        var properties =
            await connection.runtime.getProperties(obj, ownProperties: true);
        var filteredProps = <String, String>{};
        for (var prop in properties) {
          if (prop.value != null && prop.name != '__proto__') {
            filteredProps[prop.name] = await stringifyRemoteObject(prop.value);
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
        var propValue = '${prop.value.value}';
        if (prop.value.type == 'string') {
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
            compiler.sourceMap.urls[entry.sourceUrlId] == inputSourceUrl) {
          return wip.WipLocation.fromValues(script.scriptId, lineEntry.line);
        }
      }
    }
    throw StateError(
        'Unable to extract WIP Location from ${script.url} for Dart line $dartLine.');
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
      onTimeout: () => throw Exception('Unable to set breakpoint activity'));
}
