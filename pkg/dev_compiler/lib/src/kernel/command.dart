// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';

import 'package:args/args.dart';
import 'package:build_integration/file_system/multi_root.dart';
import 'package:cli_util/cli_util.dart' show getSdkPath;
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:kernel/binary/ast_to_binary.dart' as kernel show BinaryPrinter;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart' hide MapEntry;
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart' as kernel show Printer;
import 'package:path/path.dart' as p;
import 'package:source_maps/source_maps.dart' show SourceMapBuilder;

import '../compiler/js_names.dart' as js_ast;
import '../compiler/module_builder.dart';
import '../compiler/shared_command.dart';
import '../compiler/shared_compiler.dart';
import '../js_ast/js_ast.dart' as js_ast;
import '../js_ast/js_ast.dart' show js;
import '../js_ast/source_map_printer.dart' show SourceMapPrintingContext;
import 'compiler.dart';
import 'module_metadata.dart';
import 'target.dart';

const _binaryName = 'dartdevc -k';

// ignore_for_file: DEPRECATED_MEMBER_USE

/// Invoke the compiler with [args].
///
/// Returns `true` if the program compiled without any fatal errors.
Future<CompilerResult> compile(List<String> args,
    {fe.InitializedCompilerState compilerState,
    bool isWorker = false,
    bool useIncrementalCompiler = false,
    Map<Uri, List<int>> inputDigests}) async {
  try {
    return await _compile(args,
        compilerState: compilerState,
        isWorker: isWorker,
        useIncrementalCompiler: useIncrementalCompiler,
        inputDigests: inputDigests);
  } catch (error, stackTrace) {
    print('''
We're sorry, you've found a bug in our compiler.
You can report this bug at:
    https://github.com/dart-lang/sdk/issues/labels/web-dev-compiler
Please include the information below in your report, along with
any other information that may help us track it down. Thanks!
-------------------- %< --------------------
    $_binaryName arguments: ${args.join(' ')}
    dart --version: ${Platform.version}

$error
$stackTrace
''');
    return CompilerResult(70);
  }
}

String _usageMessage(ArgParser ddcArgParser) =>
    'The Dart Development Compiler compiles Dart sources into a JavaScript '
    'module.\n\n'
    'Usage: $_binaryName [options...] <sources...>\n\n'
    '${ddcArgParser.usage}';

Future<CompilerResult> _compile(List<String> args,
    {fe.InitializedCompilerState compilerState,
    bool isWorker = false,
    bool useIncrementalCompiler = false,
    Map<Uri, List<int>> inputDigests}) async {
  // TODO(jmesserly): refactor options to share code with dartdevc CLI.
  var argParser = ArgParser(allowTrailingOptions: true)
    ..addFlag('help',
        abbr: 'h', help: 'Display this message.', negatable: false)
    ..addOption('packages', help: 'The package spec file to use.')
    // TODO(jmesserly): is this still useful for us, or can we remove it now?
    ..addFlag('summarize-text',
        help: 'Emit API summary in a .js.txt file.',
        defaultsTo: false,
        hide: true)
    ..addFlag('track-widget-creation',
        help: 'Enable inspecting of Flutter widgets.', hide: true)
    // TODO(jmesserly): add verbose help to show hidden options
    ..addOption('dart-sdk-summary',
        help: 'The path to the Dart SDK summary file.', hide: true)
    ..addMultiOption('multi-root',
        help: 'The directories to search when encountering uris with the '
            'specified multi-root scheme.',
        defaultsTo: [Uri.base.path])
    ..addOption('dart-sdk',
        help: '(unsupported with --kernel) path to the Dart SDK.', hide: true)
    ..addFlag('compile-sdk',
        help: 'Build an SDK module.', defaultsTo: false, hide: true)
    ..addOption('libraries-file',
        help: 'The path to the libraries.json file for the sdk.')
    ..addOption('used-inputs-file',
        help: 'If set, the file to record inputs used.', hide: true)
    ..addFlag('kernel',
        abbr: 'k',
        help: 'Deprecated and ignored. To be removed in a future release.',
        hide: true);
  SharedCompilerOptions.addArguments(argParser);
  var declaredVariables = parseAndRemoveDeclaredVariables(args);
  ArgResults argResults;
  try {
    argResults = argParser.parse(filterUnknownArguments(args, argParser));
  } on FormatException catch (error) {
    if (args.any((arg) => arg.contains('ddc_sdk.sum'))) {
      print('Compiling with analyzer based DDC is no longer supported.\n');
      print('The most likely reason you are seeing this message is due to an '
          'old version of build_web_compilers.');
      print('Update your package pubspec.yaml to depend on a newer version of '
          'build_web_compilers:\n\n'
          'dev_dependency:\n'
          '  build_web_compilers: ^2.0.0\n');
      return CompilerResult(64);
    }
    print(error);
    print(_usageMessage(argParser));
    return CompilerResult(64);
  }

  var outPaths = argResults['out'] as List<String>;
  var moduleFormats = parseModuleFormatOption(argResults);
  if (outPaths.isEmpty) {
    print('Please specify the output file location. For example:\n'
        '    -o PATH/TO/OUTPUT_FILE.js');
    return CompilerResult(64);
  } else if (outPaths.length != moduleFormats.length) {
    print('Number of output files (${outPaths.length}) must match '
        'number of module formats (${moduleFormats.length}).');
    return CompilerResult(64);
  }

  if (argResults['help'] as bool || args.isEmpty) {
    print(_usageMessage(argParser));
    return CompilerResult(0);
  }

  var options = SharedCompilerOptions.fromArguments(argResults);

  // To make the output .dill agnostic of the current working directory,
  // we use a custom-uri scheme for all app URIs (these are files outside the
  // lib folder). The following [FileSystem] will resolve those references to
  // the correct location and keeps the real file location hidden from the
  // front end.
  var multiRootPaths = (argResults['multi-root'] as Iterable<String>)
      .map(Uri.base.resolve)
      .toList();
  var multiRootOutputPath = options.multiRootOutputPath;
  if (multiRootOutputPath == null) {
    if (outPaths.length > 1) {
      print(
          'If multiple output files (found ${outPaths.length}) are specified, '
          'then --multi-root-output-path must be explicitly provided.');
      return CompilerResult(64);
    }
    var jsOutputUri = sourcePathToUri(p.absolute(outPaths.first));
    multiRootOutputPath = _longestPrefixingPath(jsOutputUri, multiRootPaths);
  }

  var fileSystem = MultiRootFileSystem(
      options.multiRootScheme, multiRootPaths, fe.StandardFileSystem.instance);

  Uri toCustomUri(Uri uri) {
    if (uri.scheme == '') {
      return Uri(scheme: options.multiRootScheme, path: '/' + uri.path);
    }
    return uri;
  }

  // TODO(jmesserly): this is a workaround for the CFE, which does not
  // understand relative URIs, and we'd like to avoid absolute file URIs
  // being placed in the summary if possible.
  // TODO(jmesserly): investigate if Analyzer has a similar issue.
  Uri sourcePathToCustomUri(String source) {
    return toCustomUri(sourcePathToRelativeUri(source));
  }

  var summaryPaths = options.summaryModules.keys.toList();
  var summaryModules = Map.fromIterables(
      summaryPaths.map(sourcePathToUri), options.summaryModules.values);
  var sdkSummaryPath = argResults['dart-sdk-summary'] as String;
  var librarySpecPath = argResults['libraries-file'] as String;
  if (sdkSummaryPath == null) {
    sdkSummaryPath =
        defaultSdkSummaryPath(soundNullSafety: options.soundNullSafety);
    librarySpecPath ??= defaultLibrarySpecPath;
  }
  var invalidSummary = summaryPaths.any((s) => !s.endsWith('.dill')) ||
      !sdkSummaryPath.endsWith('.dill');
  if (invalidSummary) {
    throw StateError('Non-dill file detected in input: $summaryPaths');
  }

  var inputs = [for (var arg in argResults.rest) sourcePathToCustomUri(arg)];
  if (inputs.length == 1 && inputs.single.path.endsWith('.dill')) {
    return compileSdkFromDill(args);
  }

  if (librarySpecPath == null) {
    // TODO(jmesserly): the `isSupported` bit should be included in the SDK
    // summary, but front_end requires a separate file, so we have to work
    // around that, while not requiring yet another command line option.
    //
    // Right now we search two locations: one level above the SDK summary
    // (this works for the build and SDK layouts) or next to the SDK summary
    // (if the user is doing something custom).
    //
    // Another option: we could make an in-memory file with the relevant info.
    librarySpecPath =
        p.join(p.dirname(p.dirname(sdkSummaryPath)), 'libraries.json');
    if (!File(librarySpecPath).existsSync()) {
      librarySpecPath = p.join(p.dirname(sdkSummaryPath), 'libraries.json');
    }
  }

  /// The .packages file path provided by the user.
  //
  // TODO(jmesserly): the default location is based on the current working
  // directory, to match the behavior of dartanalyzer/dartdevc. However the
  // Dart VM, CFE (and dart2js?) use the script file location instead. The
  // difference may be due to the lack of a single entry point for Analyzer.
  // Ultimately this is just the default behavior; in practice users call DDC
  // through a build tool, which generally passes in `--packages=`.
  //
  // TODO(jmesserly): conceptually CFE should not need a .packages file to
  // resolve package URIs that are in the input summaries, but it seems to.
  // This needs further investigation.
  var packageFile = argResults['packages'] as String ?? _findPackagesFilePath();

  var succeeded = true;
  void diagnosticMessageHandler(fe.DiagnosticMessage message) {
    if (message.severity == fe.Severity.error) {
      succeeded = false;
    }
    fe.printDiagnosticMessage(message, print);
  }

  var explicitExperimentalFlags = fe.parseExperimentalFlags(options.experiments,
      onError: stderr.writeln, onWarning: print);

  var trackWidgetCreation =
      argResults['track-widget-creation'] as bool ?? false;

  var compileSdk = argResults['compile-sdk'] == true;
  var oldCompilerState = compilerState;
  List<Component> doneAdditionalDills;
  fe.IncrementalCompiler incrementalCompiler;
  fe.WorkerInputComponent cachedSdkInput;
  var recordUsedInputs = argResults['used-inputs-file'] != null;
  var additionalDills = summaryModules.keys.toList();

  if (!useIncrementalCompiler) {
    compilerState = await fe.initializeCompiler(
        oldCompilerState,
        compileSdk,
        sourcePathToUri(getSdkPath()),
        compileSdk ? null : sourcePathToUri(sdkSummaryPath),
        sourcePathToUri(packageFile),
        sourcePathToUri(librarySpecPath),
        additionalDills,
        DevCompilerTarget(TargetFlags(
            trackWidgetCreation: trackWidgetCreation,
            enableNullSafety: options.enableNullSafety)),
        fileSystem: fileSystem,
        explicitExperimentalFlags: explicitExperimentalFlags,
        environmentDefines: declaredVariables,
        nnbdMode:
            options.soundNullSafety ? fe.NnbdMode.Strong : fe.NnbdMode.Weak);
  } else {
    // If digests weren't given and if not in worker mode, create fake data and
    // ensure we don't have a previous state (as that wouldn't be safe with
    // fake input digests).
    if (!isWorker && (inputDigests == null || inputDigests.isEmpty)) {
      oldCompilerState = null;
      inputDigests ??= {};
      if (!compileSdk) {
        inputDigests[sourcePathToUri(sdkSummaryPath)] = const [0];
      }
      for (var uri in summaryModules.keys) {
        inputDigests[uri] = const [0];
      }
    }

    doneAdditionalDills = List<Component>(summaryModules.length);
    compilerState = await fe.initializeIncrementalCompiler(
        oldCompilerState,
        {
          'trackWidgetCreation=$trackWidgetCreation',
          'multiRootScheme=${fileSystem.markerScheme}',
          'multiRootRoots=${fileSystem.roots}',
        },
        doneAdditionalDills,
        compileSdk,
        sourcePathToUri(getSdkPath()),
        compileSdk ? null : sourcePathToUri(sdkSummaryPath),
        sourcePathToUri(packageFile),
        sourcePathToUri(librarySpecPath),
        additionalDills,
        inputDigests,
        DevCompilerTarget(TargetFlags(
            trackWidgetCreation: trackWidgetCreation,
            enableNullSafety: options.enableNullSafety)),
        fileSystem: fileSystem,
        explicitExperimentalFlags: explicitExperimentalFlags,
        environmentDefines: declaredVariables,
        trackNeededDillLibraries: recordUsedInputs,
        nnbdMode:
            options.soundNullSafety ? fe.NnbdMode.Strong : fe.NnbdMode.Weak);
    incrementalCompiler = compilerState.incrementalCompiler;
    cachedSdkInput =
        compilerState.workerInputCache[sourcePathToUri(sdkSummaryPath)];
  }

  // TODO(jmesserly): is there a cleaner way to do this?
  //
  // Ideally we'd manage our own batch compilation caching rather than rely on
  // `initializeCompiler`. Also we should be able to pass down Components for
  // SDK and summaries.
  //
  fe.DdcResult result;
  if (!useIncrementalCompiler) {
    result = await fe.compile(compilerState, inputs, diagnosticMessageHandler);
  } else {
    compilerState.options.onDiagnostic = diagnosticMessageHandler;
    var incrementalComponent = await incrementalCompiler.computeDelta(
        entryPoints: inputs, fullComponent: true);
    result = fe.DdcResult(incrementalComponent, cachedSdkInput.component,
        doneAdditionalDills, incrementalCompiler.userCode.loader.hierarchy);
  }
  compilerState.options.onDiagnostic = null; // See http://dartbug.com/36983.

  if (result == null || !succeeded) {
    return CompilerResult(1, kernelState: compilerState);
  }

  var component = result.component;
  var librariesFromDill = result.computeLibrariesFromDill();
  var compiledLibraries =
      Component(nameRoot: component.root, uriToSource: component.uriToSource)
        ..setMainMethodAndMode(null, false, component.mode);
  for (var lib in component.libraries) {
    if (!librariesFromDill.contains(lib)) compiledLibraries.libraries.add(lib);
  }

  // Output files can be written in parallel, so collect the futures.
  var outFiles = <Future>[];
  if (argResults['summarize'] as bool) {
    if (outPaths.length > 1) {
      print(
          'If multiple output files (found ${outPaths.length}) are specified, '
          'the --summarize option is not supported.');
      return CompilerResult(64);
    }
    // Note: CFE mutates the Kernel tree, so we can't save the dill
    // file if we successfully reused a cached library. If compiler state is
    // unchanged, it means we used the cache.
    //
    // In that case, we need to unbind canonical names, because they could be
    // bound already from the previous compile.
    if (identical(compilerState, oldCompilerState)) {
      component.unbindCanonicalNames();
    }
    var sink = File(p.withoutExtension(outPaths.first) + '.dill').openWrite();
    // TODO(jmesserly): this appears to save external libraries.
    // Do we need to run them through an outlining step so they can be saved?
    kernel.BinaryPrinter(sink).writeComponentFile(component);
    outFiles.add(sink.flush().then((_) => sink.close()));
  }
  if (argResults['experimental-output-compiled-kernel'] as bool) {
    if (outPaths.length > 1) {
      print(
          'If multiple output files (found ${outPaths.length}) are specified, '
          'the --experimental-output-compiled-kernel option is not supported.');
      return CompilerResult(64);
    }
    // Note: CFE mutates the Kernel tree, so we can't save the dill
    // file if we successfully reused a cached library. If compiler state is
    // unchanged, it means we used the cache.
    //
    // In that case, we need to unbind canonical names, because they could be
    // bound already from the previous compile.
    if (identical(compilerState, oldCompilerState)) {
      compiledLibraries.unbindCanonicalNames();
    }
    var sink =
        File(p.withoutExtension(outPaths.first) + '.full.dill').openWrite();
    kernel.BinaryPrinter(sink).writeComponentFile(compiledLibraries);
    outFiles.add(sink.flush().then((_) => sink.close()));
  }
  if (argResults['summarize-text'] as bool) {
    if (outPaths.length > 1) {
      print(
          'If multiple output files (found ${outPaths.length}) are specified, '
          'the --summarize-text option is not supported.');
      return CompilerResult(64);
    }
    var sb = StringBuffer();
    kernel.Printer(sb).writeComponentFile(component);
    outFiles.add(File(outPaths.first + '.txt').writeAsString(sb.toString()));
  }

  final importToSummary = Map<Library, Component>.identity();
  final summaryToModule = Map<Component, String>.identity();
  for (var i = 0; i < result.additionalDills.length; i++) {
    var additionalDill = result.additionalDills[i];
    var moduleImport = summaryModules[additionalDills[i]];
    for (var l in additionalDill.libraries) {
      assert(!importToSummary.containsKey(l));
      importToSummary[l] = additionalDill;
      summaryToModule[additionalDill] = moduleImport;
    }
  }

  var compiler = ProgramCompiler(component, result.classHierarchy, options,
      importToSummary, summaryToModule);

  var jsModule = compiler.emitModule(compiledLibraries);

  // Also the old Analyzer backend had some code to make debugging better when
  // --single-out-file is used, but that option does not appear to be used by
  // any of our build systems.
  for (var i = 0; i < outPaths.length; ++i) {
    var output = outPaths[i];
    var moduleFormat = moduleFormats[i];
    var file = File(output);
    await file.parent.create(recursive: true);
    var mapUrl = p.toUri('$output.map').toString();
    var jsCode = jsProgramToCode(jsModule, moduleFormat,
        buildSourceMap: options.sourceMap,
        inlineSourceMap: options.inlineSourceMap,
        emitDebugMetadata: options.emitDebugMetadata,
        jsUrl: p.toUri(output).toString(),
        mapUrl: mapUrl,
        customScheme: options.multiRootScheme,
        multiRootOutputPath: multiRootOutputPath,
        component: compiledLibraries);

    outFiles.add(file.writeAsString(jsCode.code));
    if (jsCode.sourceMap != null) {
      outFiles.add(
          File('$output.map').writeAsString(json.encode(jsCode.sourceMap)));
    }
    if (jsCode.metadata != null) {
      outFiles.add(
          File('$output.metadata').writeAsString(json.encode(jsCode.metadata)));
    }
  }

  if (recordUsedInputs) {
    var usedOutlines = <Uri>{};
    if (useIncrementalCompiler) {
      compilerState.incrementalCompiler
          .updateNeededDillLibrariesWithHierarchy(result.classHierarchy, null);
      for (var lib in compilerState.incrementalCompiler.neededDillLibraries) {
        if (lib.importUri.scheme == 'dart') continue;
        var uri = compilerState.libraryToInputDill[lib.importUri];
        if (uri == null) {
          throw StateError('Library ${lib.importUri} was recorded as used, '
              'but was not in the list of known libraries.');
        }
        usedOutlines.add(uri);
      }
    } else {
      // Used inputs wasn't recorded: Say we used everything.
      usedOutlines.addAll(summaryModules.keys);
    }

    var outputUsedFile = File(argResults['used-inputs-file'] as String);
    outputUsedFile.createSync(recursive: true);
    outputUsedFile.writeAsStringSync(usedOutlines.join('\n'));
  }

  await Future.wait(outFiles);
  return CompilerResult(0, kernelState: compilerState);
}

// A simplified entrypoint similar to `_compile` that only supports building the
// sdk. Note that some changes in `_compile_` might need to be copied here as
// well.
// TODO(sigmund): refactor the underlying pieces to reduce the code duplication.
Future<CompilerResult> compileSdkFromDill(List<String> args) async {
  var argParser = ArgParser(allowTrailingOptions: true);
  SharedCompilerOptions.addSdkRequiredArguments(argParser);

  ArgResults argResults;
  try {
    argResults = argParser.parse(filterUnknownArguments(args, argParser));
  } on FormatException catch (error) {
    print(error);
    print(_usageMessage(argParser));
    return CompilerResult(64);
  }

  var inputs = argResults.rest.toList();
  if (inputs.length != 1) {
    print('Only a single input file is supported to compile the sdk from dill'
        'but found: \n${inputs.join('\n')}');
    return CompilerResult(64);
  }

  if (!inputs.single.endsWith('.dill')) {
    print('Input must be a .dill file: ${inputs.single}');
    return CompilerResult(64);
  }

  var outPaths = argResults['out'] as List<String>;
  var moduleFormats = parseModuleFormatOption(argResults);
  if (outPaths.isEmpty) {
    print('Please specify the output file location. For example:\n'
        '    -o PATH/TO/OUTPUT_FILE.js');
    return CompilerResult(64);
  } else if (outPaths.length != moduleFormats.length) {
    print('Number of output files (${outPaths.length}) must match '
        'number of module formats (${moduleFormats.length}).');
    return CompilerResult(64);
  }

  var component = loadComponentFromBinary(inputs.single);
  var invalidLibraries = <Uri>[];
  for (var library in component.libraries) {
    if (library.importUri.scheme != 'dart') {
      invalidLibraries.add(library.importUri);
    }
  }

  if (invalidLibraries.isNotEmpty) {
    print('Only the SDK libraries can be compiled from .dill but found:\n'
        '${invalidLibraries.join('\n')}');
    return CompilerResult(64);
  }
  var coreTypes = CoreTypes(component);
  var hierarchy = ClassHierarchy(component, coreTypes);
  var options = SharedCompilerOptions.fromSdkRequiredArguments(argResults);

  var compiler = ProgramCompiler(
      component, hierarchy, options, const {}, const {},
      coreTypes: coreTypes);
  var jsModule = compiler.emitModule(component);
  var outFiles = <Future>[];

  // Also the old Analyzer backend had some code to make debugging better when
  // --single-out-file is used, but that option does not appear to be used by
  // any of our build systems.
  for (var i = 0; i < outPaths.length; ++i) {
    var output = outPaths[i];
    var moduleFormat = moduleFormats[i];
    var file = File(output);
    await file.parent.create(recursive: true);
    var jsCode = jsProgramToCode(jsModule, moduleFormat,
        buildSourceMap: options.sourceMap,
        inlineSourceMap: options.inlineSourceMap,
        jsUrl: p.toUri(output).toString(),
        mapUrl: p.toUri(output + '.map').toString(),
        customScheme: options.multiRootScheme,
        multiRootOutputPath: options.multiRootOutputPath,
        component: component);

    outFiles.add(file.writeAsString(jsCode.code));
    if (jsCode.sourceMap != null) {
      outFiles.add(
          File(output + '.map').writeAsString(json.encode(jsCode.sourceMap)));
    }
  }
  await Future.wait(outFiles);
  return CompilerResult(0);
}

// Compute code size to embed in the generated JavaScript
// for this module.  Return `null` to indicate when size could not be properly
// computed for this module.
int _computeDartSize(Component component) {
  var dartSize = 0;
  var uriToSource = component.uriToSource;
  for (var lib in component.libraries) {
    var libUri = lib.fileUri;
    var importUri = lib.importUri;
    var source = uriToSource[libUri];
    if (source == null) return null;
    dartSize += source.source.length;
    for (var part in lib.parts) {
      var partUri = part.partUri;
      if (partUri.startsWith(importUri.scheme)) {
        // Convert to a relative-to-library uri in order to compute a file uri.
        partUri = p.relative(partUri, from: p.dirname('${lib.importUri}'));
      }
      var fileUri = libUri.resolve(partUri);
      var partSource = uriToSource[fileUri];
      if (partSource == null) return null;
      dartSize += partSource.source.length;
    }
  }
  return dartSize;
}

/// The output of compiling a JavaScript module in a particular format.
/// This was copied from module_compiler.dart class "JSModuleCode".
class JSCode {
  /// The JavaScript code for this module.
  ///
  /// If a [sourceMap] is available, this will include the `sourceMappingURL`
  /// comment at end of the file.
  final String code;

  /// The JSON of the source map, if generated, otherwise `null`.
  ///
  /// The source paths will initially be absolute paths. They can be adjusted
  /// using [placeSourceMap].
  final Map sourceMap;

  /// Module and library information
  ///
  /// The [metadata] is a contract between compiler and the debugger,
  /// helping the debugger map between libraries, modules, source paths.
  /// see: https://goto.google.com/dart-web-debugger-metadata
  final ModuleMetadata metadata;

  JSCode(this.code, this.sourceMap, {this.metadata});
}

/// Converts [moduleTree] to [JSCode], using [format].
///
/// See [placeSourceMap] for a description of [sourceMapBase], [customScheme],
/// and [multiRootOutputPath] arguments.
JSCode jsProgramToCode(js_ast.Program moduleTree, ModuleFormat format,
    {bool buildSourceMap = false,
    bool inlineSourceMap = false,
    bool emitDebugMetadata = false,
    String jsUrl,
    String mapUrl,
    String sourceMapBase,
    String customScheme,
    String multiRootOutputPath,
    Component component}) {
  var opts = js_ast.JavaScriptPrintingOptions(
      allowKeywordsInProperties: true, allowSingleLineIfStatements: true);
  js_ast.SimpleJavaScriptPrintingContext printer;
  SourceMapBuilder sourceMap;
  if (buildSourceMap) {
    var sourceMapContext = SourceMapPrintingContext();
    sourceMap = sourceMapContext.sourceMap;
    printer = sourceMapContext;
  } else {
    printer = js_ast.SimpleJavaScriptPrintingContext();
  }

  var tree = transformModuleFormat(format, moduleTree);
  tree.accept(
      js_ast.Printer(opts, printer, localNamer: js_ast.TemporaryNamer(tree)));

  Map builtMap;
  if (buildSourceMap && sourceMap != null) {
    builtMap = placeSourceMap(sourceMap.build(jsUrl), mapUrl, customScheme,
        multiRootOutputPath: multiRootOutputPath, sourceMapBase: sourceMapBase);
    var jsDir = p.dirname(p.fromUri(jsUrl));
    var relative = p.relative(p.fromUri(mapUrl), from: jsDir);
    var relativeMapUrl = p.toUri(relative).toString();
    assert(p.dirname(jsUrl) == p.dirname(mapUrl));
    printer.emit('\n//# sourceMappingURL=');
    printer.emit(relativeMapUrl);
    printer.emit('\n');
  }

  var text = printer.getText();
  var encodedMap = json.encode(builtMap);
  var rawSourceMap =
      inlineSourceMap ? js.escapedString(encodedMap, "'").value : 'null';
  text = text.replaceFirst(SharedCompiler.sourceMapLocationID, rawSourceMap);

  // This is intended to be used by our build/debug tools to gather metrics.
  // See pkg/dev_compiler/lib/js/legacy/dart_library.js for runtime code that
  // reads this.
  //
  // These keys (see corresponding logic in dart_library.js) include:
  // - dartSize: <size of Dart input code in bytes>
  // - sourceMapSize: <size of JS source map in bytes>
  //
  // TODO(vsm): Ideally, this information is never sent to the browser.  I.e.,
  // our runtime metrics gathering would obtain this information from the
  // compilation server, not the browser.  We don't yet have the infra for that.
  var compileTimeStatistics = {
    'dartSize': component != null ? _computeDartSize(component) : null,
    'sourceMapSize': encodedMap.length
  };
  text = text.replaceFirst(
      SharedCompiler.metricsLocationID, '$compileTimeStatistics');

  var debugMetadata = emitDebugMetadata
      ? _emitMetadata(moduleTree, component, mapUrl, jsUrl)
      : null;

  return JSCode(text, builtMap, metadata: debugMetadata);
}

ModuleMetadata _emitMetadata(js_ast.Program program, Component component,
    String sourceMapUri, String moduleUri) {
  var metadata = ModuleMetadata(
      program.name, loadFunctionName(program.name), sourceMapUri, moduleUri);

  for (var lib in component.libraries) {
    metadata.addLibrary(LibraryMetadata(
        libraryUriToJsIdentifier(lib.importUri),
        lib.importUri.toString(),
        lib.fileUri.toString(),
        [...lib.parts.map((p) => p.partUri)]));
  }
  return metadata;
}

/// Parses Dart's non-standard `-Dname=value` syntax for declared variables,
/// and removes them from [args] so the result can be parsed normally.
Map<String, String> parseAndRemoveDeclaredVariables(List<String> args) {
  var declaredVariables = <String, String>{};
  for (var i = 0; i < args.length;) {
    var arg = args[i];
    if (arg.startsWith('-D') && arg.length > 2) {
      var rest = arg.substring(2);
      var eq = rest.indexOf('=');
      if (eq <= 0) {
        var kind = eq == 0 ? 'name' : 'value';
        throw FormatException('no $kind given to -D option `$arg`');
      }
      var name = rest.substring(0, eq);
      var value = rest.substring(eq + 1);
      declaredVariables[name] = value;
      args.removeAt(i);
    } else {
      i++;
    }
  }

  // Add platform defined variables
  declaredVariables.addAll(sdkLibraryVariables);

  return declaredVariables;
}

/// The default path of the kernel summary for the Dart SDK given the
/// [soundNullSafety] mode.
String defaultSdkSummaryPath({bool soundNullSafety}) {
  var outlineDill = soundNullSafety ? 'ddc_outline_sound.dill' : 'ddc_sdk.dill';
  return p.join(getSdkPath(), 'lib', '_internal', outlineDill);
}

final defaultLibrarySpecPath = p.join(getSdkPath(), 'lib', 'libraries.json');

/// Returns the absolute path to the default `.packages` file, or `null` if one
/// could not be found.
///
/// Checks for a `.packages` file in the current working directory, or in any
/// parent directory.
String _findPackagesFilePath() {
  // TODO(jmesserly): this was copied from package:package_config/discovery.dart
  // Unfortunately the relevant function is not public. CFE APIs require a URI
  // to the .packages file, rather than letting us provide the package map data.
  var dir = Directory.current;
  if (!dir.isAbsolute) dir = dir.absolute;
  if (!dir.existsSync()) return null;

  // Check for $cwd/.packages
  while (true) {
    var file = File(p.join(dir.path, '.packages'));
    if (file.existsSync()) return file.path;

    // If we didn't find it, search the parent directory.
    // Stop the search if we're already at the root.
    var parent = dir.parent;
    if (dir.path == parent.path) return null;
    dir = parent;
  }
}

/// Inputs must be absolute paths. Returns null if no prefixing path is found.
String _longestPrefixingPath(Uri baseUri, List<Uri> prefixingPaths) {
  var basePath = baseUri.path;
  return prefixingPaths.fold(null, (String previousValue, Uri element) {
    if (basePath.startsWith(element.path) &&
        (previousValue == null || previousValue.length < element.path.length)) {
      return element.path;
    }
    return previousValue;
  });
}
