// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show json;
import 'dart:io' show File;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart'
    show LibraryElement, UriReferencedElement;
import 'package:analyzer/error/error.dart';

import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:path/path.dart' as path;
import 'package:source_maps/source_maps.dart';

import '../compiler/js_names.dart' as js_ast;
import '../compiler/module_builder.dart'
    show transformModuleFormat, ModuleFormat;
import '../compiler/shared_command.dart';
import '../compiler/shared_compiler.dart';
import '../js_ast/js_ast.dart' as js_ast;
import '../js_ast/js_ast.dart' show js;
import '../js_ast/source_map_printer.dart' show SourceMapPrintingContext;
import 'code_generator.dart' show CodeGenerator;
import 'context.dart';

import 'driver.dart';
import 'error_helpers.dart';

/// Compiles a set of Dart files into a single JavaScript module.
///
/// For a single build unit, this will produce a [JSModuleFile].
///
/// A build unit is a collection of Dart sources that is sufficient to be
/// compiled together. This can be as small as a single Dart library file, but
/// if the library has parts, or if the library has cyclic dependencies on other
/// libraries, those must be included as well. A common build unit is the lib
/// directory of a Dart package.
///
/// This class exists to cache global state associated with a single in-memory
/// [AnalysisContext], such as information about extension types in the Dart
/// SDK. It can be used once to produce a single module, or reused to save
/// warm-up time. (Currently there is no warm up, but there may be in the
/// future.)
///
/// The SDK source code is assumed to be immutable for the life of this class.
///
/// For all other files, it is up to the analysis context to decide whether or
/// not any caching is performed. By default an analysis context will assume
/// sources are immutable for the life of the context, and cache information
/// about them.
JSModuleFile compileWithAnalyzer(
    CompilerAnalysisDriver compilerDriver,
    List<String> sourcePaths,
    AnalyzerOptions analyzerOptions,
    CompilerOptions options) {
  var trees = <CompilationUnit>[];

  var explicitSources = <Uri>[];
  var compilingSdk = false;
  for (var sourcePath in sourcePaths) {
    var sourceUri = sourcePathToUri(sourcePath);
    if (sourceUri.scheme == "dart") {
      compilingSdk = true;
    }
    explicitSources.add(sourceUri);
  }
  var driver = compilerDriver.linkLibraries(explicitSources, analyzerOptions);

  var errors = ErrorCollector(driver.analysisOptions, options.replCompile);
  for (var libraryUri in driver.libraryUris) {
    var analysisResults = driver.analyzeLibrary(libraryUri);

    CompilationUnit definingUnit;
    for (var result in analysisResults.values) {
      if (result.file.uriStr == libraryUri) definingUnit = result.unit;
      errors.addAll(result.unit.lineInfo, result.errors);
      trees.add(result.unit);
    }

    var library = driver.getLibrary(libraryUri);

    // TODO(jmesserly): remove "dart:mirrors" from DDC's SDK, and then remove
    // this special case error message.
    if (!compilingSdk && !options.emitMetadata) {
      var node = _getDartMirrorsImport(library);
      if (node != null) {
        errors.add(
            definingUnit.lineInfo,
            AnalysisError(library.source, node.uriOffset, node.uriEnd,
                invalidImportDartMirrors));
      }
    }
  }

  js_ast.Program jsProgram;
  if (options.unsafeForceCompile || !errors.hasFatalErrors) {
    var codeGenerator = CodeGenerator(
        driver,
        driver.typeProvider,
        compilerDriver.summaryData,
        options,
        compilerDriver.extensionTypes,
        errors);
    try {
      jsProgram = codeGenerator.compile(trees);
    } catch (e) {
      // If force compilation failed, suppress the exception and report the
      // static errors instead. Otherwise, rethrow an internal compiler error.
      if (!errors.hasFatalErrors) rethrow;
    }

    if (!options.unsafeForceCompile && errors.hasFatalErrors) {
      jsProgram = null;
    }
  }

  if (analyzerOptions.dependencyTracker != null) {
    var file = File(analyzerOptions.dependencyTracker.outputPath);
    file.writeAsStringSync(
        (analyzerOptions.dependencyTracker.dependencies.toList()..sort()).join('\n'));
  }

  var jsModule = JSModuleFile(
      errors.formattedErrors.toList(), options, jsProgram, driver.summaryBytes);
  return jsModule;
}

UriReferencedElement _getDartMirrorsImport(LibraryElement library) {
  return library.imports.firstWhere(_isDartMirrorsImort, orElse: () => null) ??
      library.exports.firstWhere(_isDartMirrorsImort, orElse: () => null);
}

bool _isDartMirrorsImort(UriReferencedElement import) {
  return import.uri == 'dart:mirrors';
}

class CompilerOptions extends SharedCompilerOptions {
  /// If [sourceMap] is emitted, this will emit a `sourceMappingUrl` comment
  /// into the output JavaScript module.
  final bool sourceMapComment;

  /// The file extension for summaries.
  final String summaryExtension;

  /// Whether to force compilation of code with static errors.
  final bool unsafeForceCompile;

  /// If specified, the path to write the summary file.
  /// Used when building the SDK.
  final String summaryOutPath;

  /// *deprecated* If specified, this is used to initialize the import paths for
  /// [summaryModules].
  final String moduleRoot;

  /// *deprecated* If specified, `dartdevc` will synthesize library names that
  /// are relative to this path for all libraries in the JS module.
  String libraryRoot;

  CompilerOptions(
      {bool sourceMap = true,
      this.sourceMapComment = true,
      bool summarizeApi = true,
      this.summaryExtension = 'sum',
      this.unsafeForceCompile = false,
      bool replCompile = false,
      bool emitMetadata = false,
      bool enableAsserts = true,
      Map<String, String> bazelMapping = const {},
      this.summaryOutPath,
      Map<String, String> summaryModules = const {},
      this.moduleRoot,
      this.libraryRoot})
      : super(
            sourceMap: sourceMap,
            summarizeApi: summarizeApi,
            emitMetadata: emitMetadata,
            enableAsserts: enableAsserts,
            replCompile: replCompile,
            bazelMapping: bazelMapping,
            summaryModules: summaryModules);

  CompilerOptions.fromArguments(ArgResults args)
      : sourceMapComment = args['source-map-comment'] as bool,
        summaryExtension = args['summary-extension'] as String,
        unsafeForceCompile = args['unsafe-force-compile'] as bool,
        summaryOutPath = args['summary-out'] as String,
        moduleRoot = args['module-root'] as String,
        libraryRoot = _getLibraryRoot(args),
        super.fromArguments(args, args['module-root'] as String,
            args['summary-extension'] as String);

  static void addArguments(ArgParser parser, {bool hide = true}) {
    SharedCompilerOptions.addArguments(parser, hide: hide);
    parser
      ..addOption('summary-extension',
          help: 'file extension for Dart summary files',
          defaultsTo: 'sum',
          hide: hide)
      ..addFlag('source-map-comment',
          help: 'adds a sourceMappingURL comment to the end of the JS,\n'
              'disable if using X-SourceMap header',
          defaultsTo: true,
          hide: hide)
      ..addFlag('unsafe-force-compile',
          help: 'Compile code even if it has errors. ಠ_ಠ\n'
              'This has undefined behavior!',
          hide: hide)
      ..addOption('summary-out',
          help: 'location to write the summary file', hide: hide)
      ..addOption('summary-deps-output',
          help: 'Path to a file to dump summary dependency info to.',
          hide: hide)
      ..addOption('module-root',
          help: '(deprecated) used to determine the default module name and\n'
              'summary import name if those are not provided.',
          hide: hide);
  }

  static String _getLibraryRoot(ArgResults args) {
    var root = args['library-root'] as String;
    return root != null ? path.absolute(root) : path.current;
  }
}

/// The output of Dart->JS compilation.
///
/// This contains the file contents of the JS module, as well as a list of
/// Dart libraries that are contained in this module.
class JSModuleFile {
  /// The list of messages (errors and warnings)
  final List<String> errors;

  /// The AST that will be used to generate the [code] and [sourceMap] for this
  /// module.
  final js_ast.Program moduleTree;

  /// The compiler options used to generate this module.
  final CompilerOptions options;

  /// The binary contents of the API summary file, including APIs from each of
  /// the libraries in this module.
  final List<int> summaryBytes;

  JSModuleFile(this.errors, this.options, this.moduleTree, this.summaryBytes);

  JSModuleFile.invalid(this.errors, this.options)
      : moduleTree = null,
        summaryBytes = null;

  /// The name of this module.
  String get name => options.moduleName;

  /// True if this library was successfully compiled.
  bool get isValid => moduleTree != null;

  /// Gets the source code and source map for this JS module, given the
  /// locations where the JS file and map file will be served from.
  ///
  /// Relative URLs will be used to point from the .js file to the .map file
  //
  // TODO(jmesserly): this should match our old logic, but I'm not sure we are
  // correctly handling the pointer from the .js file to the .map file.
  JSModuleCode getCode(ModuleFormat format, String jsUrl, String mapUrl) {
    var opts = js_ast.JavaScriptPrintingOptions(
        allowKeywordsInProperties: true, allowSingleLineIfStatements: true);
    js_ast.SimpleJavaScriptPrintingContext printer;
    SourceMapBuilder sourceMap;
    if (options.sourceMap) {
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
    if (options.sourceMap && sourceMap != null) {
      builtMap = placeSourceMap(
          sourceMap.build(jsUrl), mapUrl, options.bazelMapping, null);
      if (options.sourceMapComment) {
        var jsDir = path.dirname(path.fromUri(jsUrl));
        var relative = path.relative(path.fromUri(mapUrl), from: jsDir);
        var relativeMapUrl = path.toUri(relative).toString();
        assert(path.dirname(jsUrl) == path.dirname(mapUrl));
        printer.emit('\n//# sourceMappingURL=');
        printer.emit(relativeMapUrl);
        printer.emit('\n');
      }
    }

    var text = printer.getText();
    var rawSourceMap = options.inlineSourceMap
        ? js.escapedString(json.encode(builtMap), "'").value
        : 'null';
    text = text.replaceFirst(SharedCompiler.sourceMapLocationID, rawSourceMap);

    return JSModuleCode(text, builtMap);
  }

  /// Similar to [getCode] but immediately writes the resulting files.
  ///
  /// If [mapPath] is not supplied but [options.sourceMap] is set, mapPath
  /// will default to [jsPath].map.
  void writeCodeSync(ModuleFormat format, String jsPath) {
    String mapPath = jsPath + '.map';
    var code = getCode(
        format, path.toUri(jsPath).toString(), path.toUri(mapPath).toString());
    var c = code.code;
    if (format == ModuleFormat.amdConcat ||
        format == ModuleFormat.legacyConcat) {
      // In single-out-file mode we wrap each module in an eval statement to
      // leverage sourceURL to improve the debugging experience when source maps
      // are not enabled.
      //
      // Note: We replace all `/` with `.` so that we don't break relative urls
      // to sources in the original sourcemap. The name of this file is bogus
      // anyways, so it has very little effect on things.
      c += '\n//# sourceURL=${name.replaceAll("/", ".")}.js\n';
      c = 'eval(${json.encode(c)});\n';
    }

    var file = File(jsPath);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    file.writeAsStringSync(c);

    // TODO(jacobr): it is a bit strange we are writing the source map to a file
    // even when options.inlineSourceMap is true. To be consistent perhaps we
    // should also write a copy of the source file without a sourcemap even when
    // inlineSourceMap is true.
    if (code.sourceMap != null) {
      file = File(mapPath);
      if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
      file.writeAsStringSync(json.encode(code.sourceMap));
    }
  }
}

/// The output of compiling a JavaScript module in a particular format.
class JSModuleCode {
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

  JSModuleCode(this.code, this.sourceMap);
}
