// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';

import 'package:args/args.dart';
import 'package:build_integration/file_system/multi_root.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:kernel/kernel.dart';
import 'package:kernel/text/ast_to_text.dart' as kernel show Printer;
import 'package:kernel/binary/ast_to_binary.dart' as kernel show BinaryPrinter;
import 'package:path/path.dart' as path;
import 'package:source_maps/source_maps.dart' show SourceMapBuilder;

import '../compiler/js_names.dart' as JS;
import '../compiler/module_builder.dart';
import '../compiler/shared_command.dart';
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/source_map_printer.dart' show SourceMapPrintingContext;
import 'compiler.dart';
import 'target.dart';

const _binaryName = 'dartdevk';

/// Invoke the compiler with [args].
///
/// Returns `true` if the program compiled without any fatal errors.
Future<CompilerResult> compile(List<String> args,
    {fe.InitializedCompilerState compilerState}) async {
  try {
    return await _compile(args, compilerState: compilerState);
  } catch (error, stackTrace) {
    print('''
We're sorry, you've found a bug in our compiler.
You can report this bug at:
    https://github.com/dart-lang/sdk/issues/labels/area-dev-compiler
Please include the information below in your report, along with
any other information that may help us track it down. Thanks!
-------------------- %< --------------------
    $_binaryName arguments: ${args.join(' ')}
    dart --version: ${Platform.version}

$error
$stackTrace
''');
    rethrow;
  }
}

String _usageMessage(ArgParser ddcArgParser) =>
    'The Dart Development Compiler compiles Dart sources into a JavaScript '
    'module.\n\n'
    'Usage: $_binaryName [options...] <sources...>\n\n'
    '${ddcArgParser.usage}';

class CompilerResult {
  final fe.InitializedCompilerState compilerState;
  final bool success;

  CompilerResult(this.compilerState, this.success);

  CompilerResult.noState(this.success) : compilerState = null;
}

Future<CompilerResult> _compile(List<String> args,
    {fe.InitializedCompilerState compilerState}) async {
  // TODO(jmesserly): refactor options to share code with dartdevc CLI.
  var argParser = ArgParser(allowTrailingOptions: true)
    ..addFlag('help',
        abbr: 'h', help: 'Display this message.', negatable: false)
    ..addOption('out', abbr: 'o', help: 'Output file (required).')
    ..addOption('packages', help: 'The package spec file to use.')
    // TODO(jmesserly): should default to `false` and be hidden.
    // For now this is very helpful in debugging the compiler.
    ..addFlag('summarize-text',
        help: 'emit API summary in a .js.txt file', defaultsTo: true)
    // TODO(jmesserly): add verbose help to show hidden options
    ..addOption('dart-sdk-summary',
        help: 'The path to the Dart SDK summary file.', hide: true)
    ..addOption('multi-root-scheme',
        help: 'The custom scheme to indicate a multi-root uri.',
        defaultsTo: 'org-dartlang-app')
    ..addMultiOption('multi-root',
        help: 'The directories to search when encountering uris with the '
            'specified multi-root scheme.',
        defaultsTo: [Uri.base.path]);
  SharedCompilerOptions.addArguments(argParser);

  var declaredVariables = parseAndRemoveDeclaredVariables(args);
  var argResults = argParser.parse(filterUnknownArguments(args, argParser));

  if (argResults['help'] as bool || args.isEmpty) {
    print(_usageMessage(argParser));
    return CompilerResult.noState(true);
  }

  // To make the output .dill agnostic of the current working directory,
  // we use a custom-uri scheme for all app URIs (these are files outside the
  // lib folder). The following [FileSystem] will resolve those references to
  // the correct location and keeps the real file location hidden from the
  // front end.
  var multiRootScheme = argResults['multi-root-scheme'] as String;

  var fileSystem = MultiRootFileSystem(
      multiRootScheme,
      (argResults['multi-root'] as Iterable<String>)
          .map(Uri.base.resolve)
          .toList(),
      StandardFileSystem.instance);

  Uri toCustomUri(Uri uri) {
    if (uri.scheme == '') {
      return Uri(scheme: multiRootScheme, path: '/' + uri.path);
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

  var options = SharedCompilerOptions.fromArguments(argResults);
  var ddcPath = path.dirname(path.dirname(path.fromUri(Platform.script)));
  var summaryModules = Map.fromIterables(
      options.summaryModules.keys.map(sourcePathToUri),
      options.summaryModules.values);

  var sdkSummaryPath =
      argResults['dart-sdk-summary'] as String ?? defaultSdkSummaryPath;

  var packageFile = argResults['packages'] as String ??
      path.absolute(ddcPath, '..', '..', '.packages');

  var inputs = argResults.rest.map(sourcePathToCustomUri).toList();

  var succeeded = true;
  void errorHandler(fe.CompilationMessage error) {
    if (error.severity == fe.Severity.error) {
      succeeded = false;
    }
  }

  var oldCompilerState = compilerState;
  compilerState = await fe.initializeCompiler(
      oldCompilerState,
      sourcePathToUri(sdkSummaryPath),
      sourcePathToUri(packageFile),
      summaryModules.keys.toList(),
      DevCompilerTarget(),
      fileSystem: fileSystem);
  fe.DdcResult result = await fe.compile(compilerState, inputs, errorHandler);
  if (result == null || !succeeded) {
    return CompilerResult(compilerState, false);
  }

  var component = result.component;
  if (!options.emitMetadata && _checkForDartMirrorsImport(component)) {
    return CompilerResult(compilerState, false);
  }

  String output = argResults['out'];
  var file = File(output);
  await file.parent.create(recursive: true);

  // Output files can be written in parallel, so collect the futures.
  var outFiles = <Future>[];
  if (argResults['summarize'] as bool) {
    // TODO(jmesserly): CFE mutates the Kernel tree, so we can't save the dill
    // file if we successfully reused a cached library. If compiler state is
    // unchanged, it means we used the cache.
    //
    // In that case, we need to unbind canonical names, because they could be
    // bound already from the previous compile.
    if (identical(compilerState, oldCompilerState)) {
      component.unbindCanonicalNames();
    }
    var sink = File(path.withoutExtension(output) + '.dill').openWrite();
    // TODO(jmesserly): this appears to save external libraries.
    // Do we need to run them through an outlining step so they can be saved?
    kernel.BinaryPrinter(sink).writeComponentFile(component);
    outFiles.add(sink.flush().then((_) => sink.close()));
  }
  if (argResults['summarize-text'] as bool) {
    var sink = File(output + '.txt').openWrite();
    kernel.Printer(sink, showExternal: false).writeComponentFile(component);
    outFiles.add(sink.flush().then((_) => sink.close()));
  }

  var compiler = ProgramCompiler(component, options, declaredVariables);
  var jsModule =
      compiler.emitModule(component, result.inputSummaries, summaryModules);

  var jsCode = jsProgramToCode(jsModule, options.moduleFormats.first,
      buildSourceMap: argResults['source-map'] as bool,
      jsUrl: path.toUri(output).toString(),
      mapUrl: path.toUri(output + '.map').toString(),
      bazelMapping: options.bazelMapping,
      customScheme: multiRootScheme);

  outFiles.add(file.writeAsString(jsCode.code));
  if (jsCode.sourceMap != null) {
    outFiles.add(
        File(output + '.map').writeAsString(json.encode(jsCode.sourceMap)));
  }

  await Future.wait(outFiles);
  return CompilerResult(compilerState, true);
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

  JSCode(this.code, this.sourceMap);
}

JSCode jsProgramToCode(JS.Program moduleTree, ModuleFormat format,
    {bool buildSourceMap = false,
    String jsUrl,
    String mapUrl,
    Map<String, String> bazelMapping,
    String customScheme}) {
  var opts = JS.JavaScriptPrintingOptions(
      allowKeywordsInProperties: true, allowSingleLineIfStatements: true);
  JS.SimpleJavaScriptPrintingContext printer;
  SourceMapBuilder sourceMap;
  if (buildSourceMap) {
    var sourceMapContext = SourceMapPrintingContext();
    sourceMap = sourceMapContext.sourceMap;
    printer = sourceMapContext;
  } else {
    printer = JS.SimpleJavaScriptPrintingContext();
  }

  var tree = transformModuleFormat(format, moduleTree);
  tree.accept(JS.Printer(opts, printer, localNamer: JS.TemporaryNamer(tree)));

  Map builtMap;
  if (buildSourceMap && sourceMap != null) {
    builtMap = placeSourceMap(
        sourceMap.build(jsUrl), mapUrl, bazelMapping, customScheme);
    var jsDir = path.dirname(path.fromUri(jsUrl));
    var relative = path.relative(path.fromUri(mapUrl), from: jsDir);
    var relativeMapUrl = path.toUri(relative).toString();
    assert(path.dirname(jsUrl) == path.dirname(mapUrl));
    printer.emit('\n//# sourceMappingURL=');
    printer.emit(relativeMapUrl);
    printer.emit('\n');
  }

  var text = printer.getText();

  return JSCode(text, builtMap);
}

/// Parses Dart's non-standard `-Dname=value` syntax for declared variables,
/// and removes them from [args] so the result can be parsed normally.
Map<String, String> parseAndRemoveDeclaredVariables(List<String> args) {
  var declaredVariables = <String, String>{};
  for (int i = 0; i < args.length;) {
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

/// The default path of the kernel summary for the Dart SDK.
final defaultSdkSummaryPath = path.join(
    path.dirname(path.dirname(Platform.resolvedExecutable)),
    'lib',
    '_internal',
    'ddc_sdk.dill');

bool _checkForDartMirrorsImport(Component component) {
  for (var library in component.libraries) {
    if (library.isExternal) continue;
    for (var dep in library.dependencies) {
      var uri = dep.targetLibrary.importUri;
      if (uri.scheme == 'dart' && uri.path == 'mirrors') {
        print('${library.importUri}: Error: Cannot import "dart:mirrors" '
            'in web applications (https://goo.gl/R1anEs).');
        return true;
      }
    }
  }
  return false;
}
