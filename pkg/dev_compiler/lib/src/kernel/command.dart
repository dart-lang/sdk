// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io';

import 'package:args/args.dart';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:front_end/src/api_prototype/physical_file_system.dart';
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:front_end/src/multi_root_file_system.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:path/path.dart' as path;
import 'package:source_maps/source_maps.dart';

import '../compiler/js_names.dart' as JS;
import '../compiler/module_builder.dart';
import '../js_ast/js_ast.dart' as JS;
import 'compiler.dart';
import 'native_types.dart';
import 'source_map_printer.dart';

const _binaryName = 'dartdevk';

/// Invoke the compiler with [args].
///
/// Returns `true` if the program compiled without any fatal errors.
Future<CompilerResult> compile(List<String> args,
    {fe.InitializedCompilerState compilerState}) async {
  try {
    return await _compile(args, compilerState: compilerState);
  } catch (error) {
    print('''
We're sorry, you've found a bug in our compiler.
You can report this bug at:
    https://github.com/dart-lang/sdk/issues/labels/area-dev-compiler
Please include the information below in your report, along with
any other information that may help us track it down. Thanks!
-------------------- %< --------------------
    $_binaryName arguments: ${args.join(' ')}
    dart --version: ${Platform.version}
''');
    rethrow;
  }
}

String _usageMessage(ArgParser ddcArgParser) =>
    'The Dart Development Compiler compiles Dart sources into a JavaScript '
    'module.\n\n'
    'Usage: $_binaryName [options...] <sources...>\n\n'
    '${ddcArgParser.usage}';

Uri stringToUri(String s, {bool windows}) {
  windows ??= Platform.isWindows;
  if (windows) {
    s = s.replaceAll("\\", "/");
  }

  Uri result = Uri.base.resolve(s);
  if (windows && result.scheme.length == 1) {
    // Assume c: or similar --- interpret as file path.
    return new Uri.file(s, windows: true);
  }
  return result;
}

class CompilerResult {
  final fe.InitializedCompilerState compilerState;
  final bool result;

  CompilerResult(this.compilerState, this.result);

  CompilerResult.noState(this.result) : compilerState = null;
}

Future<CompilerResult> _compile(List<String> args,
    {fe.InitializedCompilerState compilerState}) async {
  var argParser = new ArgParser(allowTrailingOptions: true)
    ..addFlag('help',
        abbr: 'h', help: 'Display this message.', negatable: false)
    ..addOption('out', abbr: 'o', help: 'Output file (required).')
    ..addOption('packages', help: 'The package spec file to use.')
    ..addOption('dart-sdk-summary',
        help: 'The path to the Dart SDK summary file.', hide: true)
    ..addOption('summary',
        abbr: 's', help: 'summaries to link to', allowMultiple: true)
    ..addFlag('source-map', help: 'emit source mapping', defaultsTo: true);

  addModuleFormatOptions(argParser, singleOutFile: false);

  var declaredVariables = parseAndRemoveDeclaredVariables(args);
  var argResults = argParser.parse(args);

  if (argResults['help'] || args.isEmpty) {
    print(_usageMessage(argParser));
    return new CompilerResult.noState(true);
  }

  var moduleFormat = parseModuleFormatOption(argResults).first;
  var ddcPath = path.dirname(path.dirname(path.fromUri(Platform.script)));

  var summaryUris =
      (argResults['summary'] as List<String>).map(stringToUri).toList();

  var sdkSummaryPath = argResults['dart-sdk-summary'] ??
      path.absolute(ddcPath, 'gen', 'sdk', 'ddc_sdk.dill');

  var packageFile =
      argResults['packages'] ?? path.absolute(ddcPath, '..', '..', '.packages');

  var inputs = argResults.rest.map(stringToUri).toList();

  var succeeded = true;
  void errorHandler(fe.CompilationMessage error) {
    // TODO(jmesserly): front end warning levels do not seem to follow the
    // Strong Mode/Dart 2 spec. So for now, we treat all warnings as
    // compile time errors.
    if (error.severity == fe.Severity.error ||
        error.severity == fe.Severity.warning) {
      succeeded = false;
    }
  }

  // To make the output .dill agnostic of the current working directory,
  // we use a custom-uri scheme for all app URIs (these are files outside the
  // lib folder). The following [FileSystem] will resolve those references to
  // the correct location and keeps the real file location hidden from the
  // front end.
  // TODO(sigmund): technically we don't need a "multi-root" file system,
  // because we are providing a single root, the alternative here is to
  // implement a new file system with a single root instead.
  var fileSystem = new MultiRootFileSystem(
      'org-dartlang-app', [Uri.base], PhysicalFileSystem.instance);

  compilerState = await fe.initializeCompiler(
      compilerState,
      path.toUri(sdkSummaryPath),
      path.toUri(packageFile),
      summaryUris,
      new DevCompilerTarget(),
      fileSystem: fileSystem);
  fe.DdcResult result = await fe.compile(compilerState, inputs, errorHandler);
  if (result == null || !succeeded) {
    return new CompilerResult(compilerState, false);
  }

  String output = argResults['out'];
  var file = new File(output);
  if (!file.parent.existsSync()) file.parent.createSync(recursive: true);

  // Useful for debugging:
  writeProgramToText(result.program, path: output + '.txt');

  // TODO(jmesserly): Save .dill file so other modules can link in this one.
  //await writeProgramToBinary(program, output);
  var jsModule = compileToJSModule(
      result.program, result.inputSummaries, summaryUris, declaredVariables);
  var jsCode = jsProgramToCode(jsModule, moduleFormat,
      buildSourceMap: argResults['source-map'],
      jsUrl: path.toUri(output).toString(),
      mapUrl: path.toUri(output + '.map').toString());
  file.writeAsStringSync(jsCode.code);

  if (jsCode.sourceMap != null) {
    file = new File(output + '.map');
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    file.writeAsStringSync(JSON.encode(jsCode.sourceMap));
  }

  return new CompilerResult(compilerState, true);
}

JS.Program compileToJSModule(Program p, List<Program> summaries,
    List<Uri> summaryUris, Map<String, String> declaredVariables) {
  var compiler = new ProgramCompiler(new NativeTypeSet(p, new CoreTypes(p)),
      declaredVariables: declaredVariables);
  return compiler.emitProgram(p, summaries, summaryUris);
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
    {bool buildSourceMap: false, String jsUrl, String mapUrl}) {
  var opts = new JS.JavaScriptPrintingOptions(
      allowKeywordsInProperties: true, allowSingleLineIfStatements: true);
  var printer;
  SourceMapBuilder sourceMap;
  if (buildSourceMap) {
    var sourceMapContext = new SourceMapPrintingContext();
    sourceMap = sourceMapContext.sourceMap;
    printer = sourceMapContext;
  } else {
    printer = new JS.SimpleJavaScriptPrintingContext();
  }

  var tree = transformModuleFormat(format, moduleTree);
  tree.accept(
      new JS.Printer(opts, printer, localNamer: new JS.TemporaryNamer(tree)));

  Map builtMap;
  if (buildSourceMap && sourceMap != null) {
    builtMap =
        placeSourceMap(sourceMap.build(jsUrl), mapUrl, <String, String>{});
    var jsDir = path.dirname(path.fromUri(jsUrl));
    var relative = path.relative(path.fromUri(mapUrl), from: jsDir);
    var relativeMapUrl = path.toUri(relative).toString();
    assert(path.dirname(jsUrl) == path.dirname(mapUrl));
    printer.emit('\n//# sourceMappingURL=');
    printer.emit(relativeMapUrl);
    printer.emit('\n');
  }

  var text = printer.getText();

  return new JSCode(text, builtMap);
}

/// This was copied from module_compiler.dart.
/// Adjusts the source paths in [sourceMap] to be relative to [sourceMapPath],
/// and returns the new map.  Relative paths are in terms of URIs ('/'), not
/// local OS paths (e.g., windows '\').
// TODO(jmesserly): find a new home for this.
Map placeSourceMap(
    Map sourceMap, String sourceMapPath, Map<String, String> bazelMappings) {
  var map = new Map.from(sourceMap);
  // Convert to a local file path if it's not.
  sourceMapPath = path.fromUri(_sourceToUri(sourceMapPath));
  var sourceMapDir = path.dirname(path.absolute(sourceMapPath));
  var list = new List.from(map['sources']);
  map['sources'] = list;

  String makeRelative(String sourcePath) {
    var uri = _sourceToUri(sourcePath);
    if (uri.scheme == 'dart' || uri.scheme == 'package') return sourcePath;

    // Convert to a local file path if it's not.
    sourcePath = path.absolute(path.fromUri(uri));

    // Allow bazel mappings to override.
    var match = bazelMappings[sourcePath];
    if (match != null) return match;

    // Fall back to a relative path against the source map itself.
    sourcePath = path.relative(sourcePath, from: sourceMapDir);

    // Convert from relative local path to relative URI.
    return path.toUri(sourcePath).path;
  }

  for (int i = 0; i < list.length; i++) {
    list[i] = makeRelative(list[i]);
  }
  map['file'] = makeRelative(map['file']);
  return map;
}

/// This was copied from module_compiler.dart.
/// Convert a source string to a Uri.  The [source] may be a Dart URI, a file
/// URI, or a local win/mac/linux path.
Uri _sourceToUri(String source) {
  var uri = Uri.parse(source);
  var scheme = uri.scheme;
  switch (scheme) {
    case "dart":
    case "package":
    case "file":
      // A valid URI.
      return uri;
    default:
      // Assume a file path.
      // TODO(jmesserly): shouldn't this be `path.toUri(path.absolute)`?
      return new Uri.file(path.absolute(source));
  }
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
        throw new FormatException('no $kind given to -D option `$arg`');
      }
      var name = rest.substring(0, eq);
      var value = rest.substring(eq + 1);
      declaredVariables[name] = value;
      args.removeAt(i);
    } else {
      i++;
    }
  }
  return declaredVariables;
}
