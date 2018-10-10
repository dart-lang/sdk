// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashSet, Queue;
import 'dart:convert' show json;
import 'dart:io' show File;

import 'package:analyzer/analyzer.dart'
    show AnalysisError, CompilationUnit, StaticWarningCode;
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/element/element.dart'
    show LibraryElement, UriReferencedElement;
import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/src/context/builder.dart' show ContextBuilder;
import 'package:analyzer/src/context/context.dart' show AnalysisContextImpl;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine;
import 'package:analyzer/src/generated/sdk.dart' show DartSdkManager;
import 'package:analyzer/src/generated/source.dart'
    show ContentCache, DartUriResolver;
import 'package:analyzer/src/generated/source_io.dart'
    show SourceKind, UriResolver;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show InSummarySource, InputPackagesResultProvider, SummaryDataStore;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:args/src/usage_exception.dart' show UsageException;
import 'package:path/path.dart' as path;
import 'package:source_maps/source_maps.dart';

import '../compiler/js_names.dart' as JS;
import '../compiler/module_builder.dart'
    show transformModuleFormat, ModuleFormat;
import '../compiler/shared_command.dart';
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/js_ast.dart' show js;
import '../js_ast/source_map_printer.dart' show SourceMapPrintingContext;
import 'code_generator.dart' show CodeGenerator;
import 'context.dart' show AnalyzerOptions, createSourceFactory;
import 'error_helpers.dart';
import 'extension_types.dart' show ExtensionTypeSet;

/// Compiles a set of Dart files into a single JavaScript module.
///
/// For a single [BuildUnit] definition, this will produce a [JSModuleFile].
/// Those objects are record types that record the data consumed and produced
/// for a single compile.
///
/// This class exists to cache global state associated with a single in-memory
/// AnalysisContext, such as information about extension types in the Dart SDK.
/// It can be used once to produce a single module, or reused to save warm-up
/// time. (Currently there is no warm up, but there may be in the future.)
///
/// The SDK source code is assumed to be immutable for the life of this class.
///
/// For all other files, it is up to the [AnalysisContext] to decide whether or
/// not any caching is performed. By default an analysis context will assume
/// sources are immutable for the life of the context, and cache information
/// about them.
class ModuleCompiler {
  final AnalysisContext context;
  final SummaryDataStore summaryData;
  final ExtensionTypeSet _extensionTypes;

  ModuleCompiler._(AnalysisContext context, this.summaryData)
      : context = context,
        _extensionTypes = ExtensionTypeSet(context);

  factory ModuleCompiler(AnalyzerOptions options,
      {ResourceProvider resourceProvider,
      String analysisRoot,
      List<UriResolver> fileResolvers,
      SummaryDataStore summaryData,
      Iterable<String> summaryPaths = const []}) {
    // TODO(danrubel): refactor with analyzer CLI into analyzer common code
    AnalysisEngine.instance.processRequiredPlugins();

    resourceProvider ??= PhysicalResourceProvider.INSTANCE;
    analysisRoot ??= path.current;

    var contextBuilder = ContextBuilder(resourceProvider,
        DartSdkManager(options.dartSdkPath, true), ContentCache(),
        options: options.contextBuilderOptions);

    var analysisOptions = contextBuilder.getAnalysisOptions(analysisRoot);
    var sdk = contextBuilder.findSdk(null, analysisOptions);

    var sdkResolver = DartUriResolver(sdk);

    // Read the summaries.
    summaryData ??= SummaryDataStore(summaryPaths,
        resourceProvider: resourceProvider,
        // TODO(vsm): Reset this to true once we cleanup internal build rules.
        disallowOverlappingSummaries: false);

    var sdkSummaryBundle = sdk.getLinkedBundle();
    if (sdkSummaryBundle != null) {
      summaryData.addBundle(null, sdkSummaryBundle);
    }

    var srcFactory = createSourceFactory(options,
        sdkResolver: sdkResolver,
        fileResolvers: fileResolvers,
        summaryData: summaryData,
        resourceProvider: resourceProvider);

    var context =
        AnalysisEngine.instance.createAnalysisContext() as AnalysisContextImpl;
    context.analysisOptions = analysisOptions;
    context.sourceFactory = srcFactory;
    if (sdkSummaryBundle != null) {
      context.resultProvider =
          InputPackagesResultProvider(context, summaryData);
    }
    var variables = Map<String, String>.from(options.declaredVariables)
      ..addAll(sdkLibraryVariables);

    context.declaredVariables = DeclaredVariables.fromMap(variables);
    if (!context.analysisOptions.strongMode) {
      throw ArgumentError('AnalysisContext must be strong mode');
    }
    if (!context.sourceFactory.dartSdk.context.analysisOptions.strongMode) {
      throw ArgumentError('AnalysisContext must have strong mode SDK');
    }

    return ModuleCompiler._(context, summaryData);
  }

  /// Compiles a single Dart build unit into a JavaScript module.
  ///
  /// *Warning* - this may require resolving the entire world.
  /// If that is not desired, the analysis context must be pre-configured using
  /// summaries before calling this method.
  JSModuleFile compile(List<String> sourcePaths, CompilerOptions options) {
    var trees = <CompilationUnit>[];
    var errors = <AnalysisError>[];

    var librariesToCompile = Queue<LibraryElement>();

    var compilingSdk = false;
    for (var sourcePath in sourcePaths) {
      var sourceUri = sourcePathToUri(sourcePath);
      if (sourceUri.scheme == "dart") {
        compilingSdk = true;
      }
      var source = context.sourceFactory.forUri2(sourceUri);

      var fileUsage = 'You need to pass at least one existing .dart file as an'
          ' argument.';
      if (source == null) {
        throw UsageException(
            'Could not create a source for "$sourcePath". The file name is in'
            ' the wrong format or was not found.',
            fileUsage);
      } else if (!source.exists()) {
        throw UsageException(
            'Given file "$sourcePath" does not exist.', fileUsage);
      }

      // Ignore parts. They need to be handled in the context of their library.
      if (context.computeKindOf(source) == SourceKind.PART) {
        continue;
      }

      librariesToCompile.add(context.computeLibraryElement(source));
    }

    var libraries = HashSet<LibraryElement>();
    while (librariesToCompile.isNotEmpty) {
      var library = librariesToCompile.removeFirst();
      if (library.source is InSummarySource) continue;
      if (!compilingSdk && library.source.isInSystemLibrary) continue;
      if (!libraries.add(library)) continue;

      librariesToCompile.addAll(library.importedLibraries);
      librariesToCompile.addAll(library.exportedLibraries);

      // TODO(jmesserly): remove "dart:mirrors" from DDC's SDK, and then remove
      // this special case error message.
      if (!compilingSdk && !options.emitMetadata) {
        var node = _getDartMirrorsImport(library);
        if (node != null) {
          errors.add(AnalysisError(library.source, node.uriOffset, node.uriEnd,
              invalidImportDartMirrors));
        }
      }

      var tree = context.resolveCompilationUnit(library.source, library);
      trees.add(tree);

      var unitErrors = context.computeErrors(library.source);
      errors.addAll(_filterJsErrors(library, unitErrors));

      for (var part in library.parts) {
        trees.add(context.resolveCompilationUnit(part.source, library));

        var unitErrors = context.computeErrors(part.source);
        errors.addAll(_filterJsErrors(library, unitErrors));
      }
    }

    var compiler =
        CodeGenerator(context, summaryData, options, _extensionTypes, errors);
    return compiler.compile(trees);
  }

  Iterable<AnalysisError> _filterJsErrors(
      LibraryElement library, Iterable<AnalysisError> errors) {
    var libraryUriStr = library.source.uri.toString();
    if (libraryUriStr == 'dart:html' ||
        libraryUriStr == 'dart:svg' ||
        libraryUriStr == 'dart:_interceptors') {
      return errors.where((error) {
        return error.errorCode !=
                StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1 &&
            error.errorCode !=
                StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2 &&
            error.errorCode !=
                StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS;
      });
    }
    return errors;
  }
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

  /// Whether to emit the source mapping file inline as a data url.
  final bool inlineSourceMap;

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
  final String libraryRoot;

  CompilerOptions(
      {bool sourceMap = true,
      this.sourceMapComment = true,
      this.inlineSourceMap = false,
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
        inlineSourceMap = args['inline-source-map'] as bool,
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
      ..addFlag('inline-source-map',
          help: 'emit source mapping inline', defaultsTo: false, hide: hide)
      ..addFlag('unsafe-force-compile',
          help: 'Compile code even if it has errors. ಠ_ಠ\n'
              'This has undefined behavior!',
          hide: hide)
      ..addOption('summary-out',
          help: 'location to write the summary file', hide: hide)
      ..addOption('module-root',
          help: '(deprecated) used to determine the default module name and\n'
              'summary import name if those are not provided.',
          hide: hide)
      ..addOption('library-root',
          help: '(deprecated) used to name libraries inside the module.');
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
  /// The name of this module.
  final String name;

  /// The list of messages (errors and warnings)
  final List<String> errors;

  /// The AST that will be used to generate the [code] and [sourceMap] for this
  /// module.
  final JS.Program moduleTree;

  /// The compiler options used to generate this module.
  final CompilerOptions options;

  /// The binary contents of the API summary file, including APIs from each of
  /// the libraries in this module.
  final List<int> summaryBytes;

  /// Unique identifier indicating hole to inline the source map.
  ///
  /// We cannot generate the source map before the script it is for is
  /// generated so we have generate the script including this id and then
  /// replace the ID once the source map is generated.
  static String sourceMapHoleID = 'SourceMap3G5a8h6JVhHfdGuDxZr1EF9GQC8y0e6u';

  JSModuleFile(
      this.name, this.errors, this.options, this.moduleTree, this.summaryBytes);

  JSModuleFile.invalid(this.name, this.errors, this.options)
      : moduleTree = null,
        summaryBytes = null;

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
    var opts = JS.JavaScriptPrintingOptions(
        allowKeywordsInProperties: true, allowSingleLineIfStatements: true);
    JS.SimpleJavaScriptPrintingContext printer;
    SourceMapBuilder sourceMap;
    if (options.sourceMap) {
      var sourceMapContext = SourceMapPrintingContext();
      sourceMap = sourceMapContext.sourceMap;
      printer = sourceMapContext;
    } else {
      printer = JS.SimpleJavaScriptPrintingContext();
    }

    var tree = transformModuleFormat(format, moduleTree);
    tree.accept(JS.Printer(opts, printer, localNamer: JS.TemporaryNamer(tree)));

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
    text = text.replaceFirst(sourceMapHoleID, rawSourceMap);

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
