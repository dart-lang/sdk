// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashSet, Queue;
import 'dart:convert' show JSON;
import 'dart:io' show File;

import 'package:analyzer/analyzer.dart'
    show AnalysisError, CompilationUnit, ErrorSeverity;
import 'package:analyzer/dart/element/element.dart' show LibraryElement;
import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/src/context/builder.dart' show ContextBuilder;
import 'package:analyzer/src/context/context.dart' show AnalysisContextImpl;
import 'package:analyzer/src/error/codes.dart' show StaticTypeWarningCode;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine;
import 'package:analyzer/src/generated/sdk.dart' show DartSdkManager;
import 'package:analyzer/src/generated/source.dart'
    show ContentCache, DartUriResolver;
import 'package:analyzer/src/generated/source_io.dart'
    show Source, SourceKind, UriResolver;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show InSummarySource, InputPackagesResultProvider, SummaryDataStore;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:args/src/usage_exception.dart' show UsageException;
import 'package:func/func.dart' show Func1;
import 'package:path/path.dart' as path;
import 'package:source_maps/source_maps.dart';

import '../analyzer/context.dart' show AnalyzerOptions, createSourceFactory;
import '../js_ast/js_ast.dart' as JS;
import '../js_ast/js_ast.dart' show js;
import 'code_generator.dart' show CodeGenerator;
import 'error_helpers.dart' show errorSeverity, formatError, sortErrors;
import 'extension_types.dart' show ExtensionTypeSet;
import 'js_names.dart' as JS;
import 'module_builder.dart' show transformModuleFormat, ModuleFormat;
import 'source_map_printer.dart' show SourceMapPrintingContext;

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
        _extensionTypes = new ExtensionTypeSet(context);

  factory ModuleCompiler(AnalyzerOptions options,
      {ResourceProvider resourceProvider,
      String analysisRoot,
      List<UriResolver> fileResolvers,
      SummaryDataStore summaryData}) {
    // TODO(danrubel): refactor with analyzer CLI into analyzer common code
    AnalysisEngine.instance.processRequiredPlugins();

    resourceProvider ??= PhysicalResourceProvider.INSTANCE;
    analysisRoot ??= path.current;

    var contextBuilder = new ContextBuilder(resourceProvider,
        new DartSdkManager(options.dartSdkPath, true), new ContentCache(),
        options: options.contextBuilderOptions);

    var analysisOptions = contextBuilder.getAnalysisOptions(analysisRoot);
    var sdk = contextBuilder.findSdk(null, analysisOptions);

    var sdkResolver = new DartUriResolver(sdk);

    // Read the summaries.
    summaryData ??= new SummaryDataStore(options.summaryPaths,
        resourceProvider: resourceProvider,
        recordDependencyInfo: true,
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
          new InputPackagesResultProvider(context, summaryData);
    }
    options.declaredVariables.forEach(context.declaredVariables.define);
    context.declaredVariables.define('dart.isVM', 'false');

    // TODO(vsm): Should this be hardcoded?
    context.declaredVariables.define('dart.library.html', 'true');
    context.declaredVariables.define('dart.library.io', 'false');

    if (!context.analysisOptions.strongMode) {
      throw new ArgumentError('AnalysisContext must be strong mode');
    }
    if (!context.sourceFactory.dartSdk.context.analysisOptions.strongMode) {
      throw new ArgumentError('AnalysisContext must have strong mode SDK');
    }

    return new ModuleCompiler._(context, summaryData);
  }

  bool _isFatalError(AnalysisError e, CompilerOptions options) {
    if (errorSeverity(context, e) != ErrorSeverity.ERROR) return false;

    // These errors are not fatal in the REPL compile mode as we
    // allow access to private members across library boundaries
    // and those accesses will show up as undefined members unless
    // additional analyzer changes are made to support them.
    // TODO(jacobr): consider checking that the identifier name
    // referenced by the error is private.
    return !options.replCompile ||
        (e.errorCode != StaticTypeWarningCode.UNDEFINED_GETTER &&
            e.errorCode != StaticTypeWarningCode.UNDEFINED_SETTER &&
            e.errorCode != StaticTypeWarningCode.UNDEFINED_METHOD);
  }

  /// Compiles a single Dart build unit into a JavaScript module.
  ///
  /// *Warning* - this may require resolving the entire world.
  /// If that is not desired, the analysis context must be pre-configured using
  /// summaries before calling this method.
  JSModuleFile compile(BuildUnit unit, CompilerOptions options) {
    var trees = <CompilationUnit>[];
    var errors = <AnalysisError>[];

    var librariesToCompile = new Queue<LibraryElement>();

    var compilingSdk = false;
    for (var sourcePath in unit.sources) {
      var sourceUri = _sourceToUri(sourcePath);
      if (sourceUri.scheme == "dart") {
        compilingSdk = true;
      }
      var source = context.sourceFactory.forUri2(sourceUri);

      var fileUsage = 'You need to pass at least one existing .dart file as an'
          ' argument.';
      if (source == null) {
        throw new UsageException(
            'Could not create a source for "$sourcePath". The file name is in'
            ' the wrong format or was not found.',
            fileUsage);
      } else if (!source.exists()) {
        throw new UsageException(
            'Given file "$sourcePath" does not exist.', fileUsage);
      }

      // Ignore parts. They need to be handled in the context of their library.
      if (context.computeKindOf(source) == SourceKind.PART) {
        continue;
      }

      librariesToCompile.add(context.computeLibraryElement(source));
    }

    var libraries = new HashSet<LibraryElement>();
    while (librariesToCompile.isNotEmpty) {
      var library = librariesToCompile.removeFirst();
      if (library.source is InSummarySource) continue;
      if (!compilingSdk && library.source.isInSystemLibrary) continue;
      if (!libraries.add(library)) continue;

      librariesToCompile.addAll(library.importedLibraries);
      librariesToCompile.addAll(library.exportedLibraries);

      var tree = context.resolveCompilationUnit(library.source, library);
      trees.add(tree);
      errors.addAll(context.computeErrors(library.source));

      for (var part in library.parts) {
        trees.add(context.resolveCompilationUnit(part.source, library));
        errors.addAll(context.computeErrors(part.source));
      }
    }

    sortErrors(context, errors);

    var messages = <String>[];
    for (var e in errors) {
      var m = formatError(context, e);
      if (m != null) messages.add(m);
    }

    if (!options.unsafeForceCompile &&
        errors.any((e) => _isFatalError(e, options))) {
      return new JSModuleFile.invalid(unit.name, messages, options);
    }

    try {
      var codeGenerator =
          new CodeGenerator(context, summaryData, options, _extensionTypes);
      return codeGenerator.compile(unit, trees, messages);
    } catch (e) {
      if (errors.any((e) => _isFatalError(e, options))) {
        // Force compilation failed.  Suppress the exception and report
        // the static errors instead.
        assert(options.unsafeForceCompile);
        return new JSModuleFile.invalid(unit.name, messages, options);
      }
      rethrow;
    }
  }
}

class CompilerOptions {
  /// Whether to emit the source mapping file.
  ///
  /// This supports debugging the original source code instead of the generated
  /// code.
  final bool sourceMap;

  /// If [sourceMap] is emitted, this will emit a `sourceMappingUrl` comment
  /// into the output JavaScript module.
  final bool sourceMapComment;

  /// Whether to emit the source mapping file inline as a data url.
  final bool inlineSourceMap;

  /// Whether to emit a summary file containing API signatures.
  ///
  /// This is required for a modular build process.
  final bool summarizeApi;

  /// The file extension for summaries.
  final String summaryExtension;

  /// Whether to preserve metdata only accessible via mirrors
  final bool emitMetadata;

  /// Whether to force compilation of code with static errors.
  final bool unsafeForceCompile;

  /// Whether to compile code in a more permissive REPL mode allowing access
  /// to private members across library boundaries.
  final bool replCompile;

  /// Whether to emit Closure Compiler-friendly code.
  final bool closure;

  /// Hoist the types at instance creation sites
  final bool hoistInstanceCreation;

  /// Hoist types from class signatures
  final bool hoistSignatureTypes;

  /// Name types in type tests
  final bool nameTypeTests;

  /// Hoist types in type tests
  final bool hoistTypeTests;

  // TODO(kevmoo): Remove once https://github.com/dart-lang/sdk/issues/27255
  //               is fixed.
  final bool useAngular2Whitelist;

  /// Enable ES6 destructuring of named parameters. Off by default.
  ///
  /// Older V8 versions do not accept default values with destructuring in
  /// arrow functions yet (e.g. `({a} = {}) => 1`) but happily accepts them
  /// with regular functions (e.g. `function({a} = {}) { return 1 }`).
  ///
  /// Supporting the syntax:
  /// * Chrome Canary (51)
  /// * Firefox
  ///
  /// Not yet supporting:
  /// * Atom (1.5.4)
  /// * Electron (0.36.3)
  // TODO(ochafik): Simplify this code when our target platforms catch up.
  final bool destructureNamedParams;

  /// Mapping from absolute file paths to bazel short path to substitute in
  /// source maps.
  final Map<String, String> bazelMapping;

  /// If specified, the path to write the summary file.
  /// Used when building the SDK.
  final String summaryOutPath;

  const CompilerOptions(
      {this.sourceMap: true,
      this.sourceMapComment: true,
      this.inlineSourceMap: false,
      this.summarizeApi: true,
      this.summaryExtension: 'sum',
      this.unsafeForceCompile: false,
      this.replCompile: false,
      this.emitMetadata: false,
      this.closure: false,
      this.destructureNamedParams: false,
      this.hoistInstanceCreation: true,
      this.hoistSignatureTypes: false,
      this.nameTypeTests: true,
      this.hoistTypeTests: true,
      this.useAngular2Whitelist: false,
      this.bazelMapping: const {},
      this.summaryOutPath});

  CompilerOptions.fromArguments(ArgResults args)
      : sourceMap = args['source-map'],
        sourceMapComment = args['source-map-comment'],
        inlineSourceMap = args['inline-source-map'],
        summarizeApi = args['summarize'],
        summaryExtension = args['summary-extension'],
        unsafeForceCompile = args['unsafe-force-compile'],
        replCompile = args['repl-compile'],
        emitMetadata = args['emit-metadata'],
        closure = args['closure-experimental'],
        destructureNamedParams = args['destructure-named-params'],
        hoistInstanceCreation = args['hoist-instance-creation'],
        hoistSignatureTypes = args['hoist-signature-types'],
        nameTypeTests = args['name-type-tests'],
        hoistTypeTests = args['hoist-type-tests'],
        useAngular2Whitelist = args['unsafe-angular2-whitelist'],
        bazelMapping = _parseBazelMappings(args['bazel-mapping']),
        summaryOutPath = args['summary-out'];

  static void addArguments(ArgParser parser, {bool hide: true}) {
    parser
      ..addFlag('summarize', help: 'emit an API summary file', defaultsTo: true)
      ..addOption('summary-extension',
          help: 'file extension for Dart summary files',
          defaultsTo: 'sum',
          hide: hide)
      ..addFlag('source-map', help: 'emit source mapping', defaultsTo: true)
      ..addFlag('source-map-comment',
          help: 'adds a sourceMappingURL comment to the end of the JS,\n'
              'disable if using X-SourceMap header',
          defaultsTo: true,
          hide: hide)
      ..addFlag('inline-source-map',
          help: 'emit source mapping inline', defaultsTo: false)
      ..addFlag('emit-metadata',
          help: 'emit metadata annotations queriable via mirrors',
          defaultsTo: false)
      ..addFlag('closure-experimental',
          help: 'emit Closure Compiler-friendly code (experimental)',
          defaultsTo: false)
      ..addFlag('destructure-named-params',
          help: 'Destructure named parameters', defaultsTo: false, hide: hide)
      ..addFlag('unsafe-force-compile',
          help: 'Compile code even if it has errors. ಠ_ಠ\n'
              'This has undefined behavior!',
          defaultsTo: false,
          hide: hide)
      ..addFlag('repl-compile',
          help: 'Compile code more permissively when in REPL mode\n'
              'allowing access to private members across library boundaries.',
          defaultsTo: false,
          hide: hide)
      ..addFlag('hoist-instance-creation',
          help: 'Hoist the class type from generic instance creations',
          defaultsTo: true,
          hide: hide)
      ..addFlag('hoist-signature-types',
          help: 'Hoist types from class signatures',
          defaultsTo: false,
          hide: hide)
      ..addFlag('name-type-tests',
          help: 'Name types used in type tests', defaultsTo: true, hide: hide)
      ..addFlag('hoist-type-tests',
          help: 'Hoist types used in type tests', defaultsTo: true, hide: hide)
      // TODO(kevmoo): Remove once https://github.com/dart-lang/sdk/issues/27255
      //               is fixed.
      ..addFlag('unsafe-angular2-whitelist', defaultsTo: false, hide: hide)
      ..addOption('bazel-mapping',
          help:
              '--bazel-mapping=genfiles/to/library.dart,to/library.dart uses \n'
              'to/library.dart as the path for library.dart in source maps.',
          allowMultiple: true,
          splitCommas: false,
          hide: hide)
      ..addOption('summary-out',
          help: 'location to write the summary file', hide: hide);
  }

  static Map<String, String> _parseBazelMappings(Iterable argument) {
    var mappings = <String, String>{};
    for (var mapping in argument) {
      var splitMapping = mapping.split(',');
      if (splitMapping.length >= 2) {
        mappings[path.absolute(splitMapping[0])] = splitMapping[1];
      }
    }
    return mappings;
  }
}

/// A unit of Dart code that can be built into a single JavaScript module.
class BuildUnit {
  /// The name of this module.
  final String name;

  /// All library names are relative to this path/prefix.
  final String libraryRoot;

  /// The list of sources in this module.
  ///
  /// The set of Dart files can be arbitrarily large, but it must contain
  /// complete libraries including all of their parts, as well as all libraries
  /// that are part of a library cycle.
  final List<String> sources;

  /// Given an imported library URI, this will determine to what Dart/JS module
  /// it belongs to.
  // TODO(jmesserly): we should replace this with another way of tracking
  // build units.
  final Func1<Source, String> libraryToModule;

  BuildUnit(
      String modulePath, this.libraryRoot, this.sources, this.libraryToModule)
      : name = '${path.toUri(modulePath)}';
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
  JSModuleCode getCode(ModuleFormat format, String jsUrl, String mapUrl,
      {bool singleOutFile: false}) {
    var opts = new JS.JavaScriptPrintingOptions(
        emitTypes: options.closure,
        allowKeywordsInProperties: true,
        allowSingleLineIfStatements: true);
    JS.SimpleJavaScriptPrintingContext printer;
    SourceMapBuilder sourceMap;
    if (options.sourceMap) {
      var sourceMapContext = new SourceMapPrintingContext();
      sourceMap = sourceMapContext.sourceMap;
      printer = sourceMapContext;
    } else {
      printer = new JS.SimpleJavaScriptPrintingContext();
    }

    var tree =
        transformModuleFormat(format, moduleTree, singleOutFile: singleOutFile);
    tree.accept(
        new JS.Printer(opts, printer, localNamer: new JS.TemporaryNamer(tree)));

    Map builtMap;
    if (options.sourceMap && sourceMap != null) {
      builtMap =
          placeSourceMap(sourceMap.build(jsUrl), mapUrl, options.bazelMapping);
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
        ? js.escapedString(JSON.encode(builtMap), "'").value
        : 'null';
    text = text.replaceFirst(sourceMapHoleID, rawSourceMap);

    return new JSModuleCode(text, builtMap);
  }

  /// Similar to [getCode] but immediately writes the resulting files.
  ///
  /// If [mapPath] is not supplied but [options.sourceMap] is set, mapPath
  /// will default to [jsPath].map.
  void writeCodeSync(ModuleFormat format, String jsPath,
      {bool singleOutFile: false}) {
    String mapPath = jsPath + '.map';
    var code = getCode(
        format, path.toUri(jsPath).toString(), path.toUri(mapPath).toString(),
        singleOutFile: singleOutFile);
    var c = code.code;
    if (singleOutFile) {
      // In singleOutFile mode we wrap each module in an eval statement to
      // leverage sourceURL to improve the debugging experience when source maps
      // are not enabled.
      //
      // Note: We replace all `/` with `.` so that we don't break relative urls
      // to sources in the original sourcemap. The name of this file is bogus
      // anyways, so it has very little effect on things.
      c += '\n//# sourceURL=${name.replaceAll("/", ".")}.js\n';
      c = 'eval(${JSON.encode(c)});\n';
    }

    var file = new File(jsPath);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    file.writeAsStringSync(c);

    // TODO(jacobr): it is a bit strange we are writing the source map to a file
    // even when options.inlineSourceMap is true. To be consistent perhaps we
    // should also write a copy of the source file without a sourcemap even when
    // inlineSourceMap is true.
    if (code.sourceMap != null) {
      file = new File(mapPath);
      if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
      file.writeAsStringSync(JSON.encode(code.sourceMap));
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

// Convert a source string to a Uri.  The [source] may be a Dart URI, a file
// URI, or a local win/mac/linux path.
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
      return new Uri.file(path.absolute(source));
  }
}
