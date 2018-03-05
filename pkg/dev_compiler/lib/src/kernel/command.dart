// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io';

import 'package:args/args.dart';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/api_unstable/ddc.dart' as fe;
import 'package:front_end/src/multi_root_file_system.dart';
import 'package:kernel/kernel.dart';
import 'package:path/path.dart' as path;
import 'package:source_maps/source_maps.dart';

import '../compiler/js_names.dart' as JS;
import '../compiler/module_builder.dart';
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/source_map_printer.dart' show SourceMapPrintingContext;
import 'compiler.dart';

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

/// Resolve [s] as a URI, possibly relative to the current directory.
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

/// Resolve [s] as a URI, and if the URI is a uri under a directory in [roots],
/// then return a custom URI containing only the subpath from that root and the
/// provided [scheme]. For example,
///
///    stringToCustomUri('a/b/c.dart', [Uri.base.resolve('a/')], 'foo')
///
/// returns:
///
///    foo:/b/c.dart
///
/// This is used to create machine agnostic URIs both for input files and for
/// summaries. We do so for input files to ensure we don't leak any
/// user-specific paths into non-package library names, and we do so for input
/// summaries to be able to easily derive a module name from the summary path.
Uri stringToCustomUri(String s, List<Uri> roots, String scheme) {
  Uri resolvedUri = stringToUri(s);
  if (resolvedUri.scheme != 'file') return resolvedUri;
  for (var root in roots) {
    if (resolvedUri.path.startsWith(root.path)) {
      var path = resolvedUri.path.substring(root.path.length);
      return Uri.parse('$scheme:///$path');
    }
  }
  return resolvedUri;
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
        abbr: 's',
        help: 'path to a summary of a transitive dependency of this module.\n'
            'This path should be under a provided summary-input-dir',
        allowMultiple: true)
    ..addFlag('source-map', help: 'emit source mapping', defaultsTo: true)
    ..addOption('summary-input-dir', allowMultiple: true)
    ..addOption('custom-app-scheme', defaultsTo: 'org-dartlang-app')
    // Ignore dart2js options that we don't support in DDC.
    ..addFlag('enable-enum', hide: true)
    ..addFlag('experimental-trust-js-interop-type-annotations', hide: true)
    ..addFlag('trust-type-annotations', hide: true)
    ..addFlag('supermixin', hide: true);

  addModuleFormatOptions(argParser, singleOutFile: false);

  var declaredVariables = parseAndRemoveDeclaredVariables(args);
  var argResults = argParser.parse(args);

  if (argResults['help'] || args.isEmpty) {
    print(_usageMessage(argParser));
    return new CompilerResult.noState(true);
  }

  var moduleFormat = parseModuleFormatOption(argResults).first;
  var ddcPath = path.dirname(path.dirname(path.fromUri(Platform.script)));

  var multiRoots = [];
  for (var s in argResults['summary-input-dir']) {
    var uri = stringToUri(s);
    if (!uri.path.endsWith('/')) {
      uri = uri.replace(path: '${uri.path}/');
    }
    multiRoots.add(uri);
  }
  multiRoots.add(Uri.base);

  var customScheme = argResults['custom-app-scheme'];
  var summaryUris = argResults['summary']
      .map((s) => stringToCustomUri(s, multiRoots, customScheme))
      .toList();

  var sdkSummaryPath = argResults['dart-sdk-summary'] ?? defaultSdkSummaryPath;

  var packageFile =
      argResults['packages'] ?? path.absolute(ddcPath, '..', '..', '.packages');

  var inputs = argResults.rest
      .map((s) => stringToCustomUri(s, [Uri.base], customScheme))
      .toList();

  var succeeded = true;
  void errorHandler(fe.CompilationMessage error) {
    if (error.severity == fe.Severity.error) {
      succeeded = false;
    }
  }

  // To make the output .dill agnostic of the current working directory,
  // we use a custom-uri scheme for all app URIs (these are files outside the
  // lib folder). The following [FileSystem] will resolve those references to
  // the correct location and keeps the real file location hidden from the
  // front end.
  var fileSystem = new MultiRootFileSystem(
      customScheme, multiRoots, StandardFileSystem.instance);

  compilerState = await fe.initializeCompiler(
      compilerState,
      stringToUri(sdkSummaryPath),
      stringToUri(packageFile),
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
      mapUrl: path.toUri(output + '.map').toString(),
      customScheme: customScheme);
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
  var compiler = new ProgramCompiler(p, declaredVariables: declaredVariables);
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
    {bool buildSourceMap: false,
    String jsUrl,
    String mapUrl,
    String customScheme}) {
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
    builtMap = placeSourceMap(
        sourceMap.build(jsUrl), mapUrl, <String, String>{}, customScheme);
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
// TODO(sigmund): delete bazelMappings - customScheme should be used instead.
Map placeSourceMap(Map sourceMap, String sourceMapPath,
    Map<String, String> bazelMappings, String customScheme) {
  var map = new Map.from(sourceMap);
  // Convert to a local file path if it's not.
  sourceMapPath = path.fromUri(_sourceToUri(sourceMapPath, customScheme));
  var sourceMapDir = path.dirname(path.absolute(sourceMapPath));
  var list = new List.from(map['sources']);
  map['sources'] = list;

  String makeRelative(String sourcePath) {
    var uri = _sourceToUri(sourcePath, customScheme);
    if (uri.scheme == 'dart' ||
        uri.scheme == 'package' ||
        uri.scheme == customScheme) {
      return sourcePath;
    }

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
Uri _sourceToUri(String source, customScheme) {
  var uri = Uri.parse(source);
  var scheme = uri.scheme;
  if (scheme == "dart" ||
      scheme == "package" ||
      scheme == "file" ||
      scheme == customScheme) {
    // A valid URI.
    return uri;
  }
  // Assume a file path.
  // TODO(jmesserly): shouldn't this be `path.toUri(path.absolute)`?
  return new Uri.file(path.absolute(source));
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

  // Add platform defined variables
  declaredVariables['dart.isVM'] = 'false';

  // TODO(vsm): Should this be hardcoded?
  declaredVariables['dart.library.html'] = 'true';
  declaredVariables['dart.library.io'] = 'false';
  declaredVariables['dart.library.ui'] = 'false';

  return declaredVariables;
}

/// The default path of the kernel summary for the Dart SDK.
final defaultSdkSummaryPath = path.join(
    path.dirname(path.dirname(Platform.resolvedExecutable)),
    'lib',
    '_internal',
    'ddc_sdk.dill');
