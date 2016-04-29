// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashSet;
import 'package:args/args.dart' show ArgParser, ArgResults;
import 'package:analyzer/analyzer.dart'
    show
        AnalysisError,
        CompilationUnit,
        CompileTimeErrorCode,
        ErrorSeverity,
        StaticWarningCode;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/java_engine.dart' show AnalysisException;
import 'package:analyzer/src/generated/source_io.dart' show Source, SourceKind;
import 'package:func/func.dart' show Func1;
import 'package:path/path.dart' as path;

import '../analyzer/context.dart'
    show AnalyzerOptions, createAnalysisContextWithSources;
import 'extension_types.dart' show ExtensionTypeSet;
import 'code_generator.dart' show CodeGenerator;
import 'error_helpers.dart' show errorSeverity, formatError, sortErrors;

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
  final _extensionTypes = new ExtensionTypeSet();

  ModuleCompiler.withContext(this.context);

  ModuleCompiler(AnalyzerOptions analyzerOptions)
      : this.withContext(createAnalysisContextWithSources(analyzerOptions));

  /// Compiles a single Dart build unit into a JavaScript module.
  ///
  /// *Warning* - this may require resolving the entire world.
  /// If that is not desired, the analysis context must be pre-configured using
  /// summaries before calling this method.
  JSModuleFile compile(BuildUnit unit, CompilerOptions options) {
    var trees = <CompilationUnit>[];
    var errors = <AnalysisError>[];

    // Validate that all parts were explicitly passed in.
    // If not, it's an error.
    var explicitParts = new HashSet<Source>();
    var usedParts = new HashSet<Source>();
    for (var sourcePath in unit.sources) {
      var sourceUri = Uri.parse(sourcePath);
      if (sourceUri.scheme == '') {
        sourceUri = path.toUri(path.absolute(sourcePath));
      }
      Source source = context.sourceFactory.forUri2(sourceUri);
      if (source == null) {
        throw new AnalysisException('could not create a source for $sourcePath.'
            ' The file name is in the wrong format or was not found.');
      }

      // Ignore parts. They need to be handled in the context of their library.
      if (context.computeKindOf(source) == SourceKind.PART) {
        explicitParts.add(source);
        continue;
      }

      var resolvedTree = context.resolveCompilationUnit2(source, source);
      trees.add(resolvedTree);
      errors.addAll(context.computeErrors(source));

      var library = resolvedTree.element.library;
      for (var part in library.parts) {
        if (!library.isInSdk) usedParts.add(part.source);
        trees.add(context.resolveCompilationUnit(part.source, library));
        errors.addAll(context.computeErrors(part.source));
      }
    }

    // Check if all parts were explicitly passed in.
    // Also verify all explicitly parts were used.
    var missingParts = usedParts.difference(explicitParts);
    var unusedParts = explicitParts.difference(usedParts);
    errors.addAll(missingParts
        .map((s) => new AnalysisError(s, 0, 0, missingPartErrorCode)));
    errors.addAll(unusedParts
        .map((s) => new AnalysisError(s, 0, 0, unusedPartWarningCode)));

    sortErrors(context, errors);
    var messages = <String>[];
    for (var e in errors) {
      var m = formatError(context, e);
      if (m != null) messages.add(m);
    }

    if (!options.unsafeForceCompile &&
        errors.any((e) => errorSeverity(context, e) == ErrorSeverity.ERROR)) {
      return new JSModuleFile.invalid(unit.name, messages);
    }

    var codeGenerator = new CodeGenerator(context, options, _extensionTypes);
    return codeGenerator.compile(unit, trees, messages);
  }
}

enum ModuleFormat { es6, legacy, node }

ModuleFormat parseModuleFormat(String s) => {
      'es6': ModuleFormat.es6,
      'node': ModuleFormat.node,
      'legacy': ModuleFormat.legacy
    }[s];

class CompilerOptions {
  /// Whether to emit the source mapping file.
  ///
  /// This supports debugging the original source code instead of the generated
  /// code.
  final bool sourceMap;

  /// If [sourceMap] is emitted, this will emit a `sourceMappingUrl` comment
  /// into the output JavaScript module.
  final bool sourceMapComment;

  /// Whether to emit a summary file containing API signatures.
  ///
  /// This is required for a modular build process.
  final bool summarizeApi;

  /// Whether to force compilation of code with static errors.
  final bool unsafeForceCompile;

  /// Whether to emit Closure Compiler-friendly code.
  final bool closure;

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

  /// Which module format to support.
  /// Currently 'es6' and 'legacy' are supported.
  final ModuleFormat moduleFormat;

  const CompilerOptions(
      {this.sourceMap: true,
      this.sourceMapComment: true,
      this.summarizeApi: true,
      this.unsafeForceCompile: false,
      this.closure: false,
      this.destructureNamedParams: false,
      this.moduleFormat: ModuleFormat.legacy});

  CompilerOptions.fromArguments(ArgResults args)
      : sourceMap = args['source-map'],
        sourceMapComment = args['source-map-comment'],
        summarizeApi = args['summarize'],
        unsafeForceCompile = args['unsafe-force-compile'],
        closure = args['closure-experimental'],
        destructureNamedParams = args['destructure-named-params'],
        moduleFormat = parseModuleFormat(args['modules']);

  static ArgParser addArguments(ArgParser parser) => parser
    ..addFlag('summarize', help: 'emit an API summary file', defaultsTo: true)
    ..addFlag('source-map', help: 'emit source mapping', defaultsTo: true)
    ..addFlag('source-map-comment',
        help: 'adds a sourceMappingURL comment to the end of the JS,\n'
            'disable if using X-SourceMap header',
        defaultsTo: true)
    ..addOption('modules',
        help: 'module pattern to emit',
        allowed: ['es6', 'legacy', 'node'],
        allowedHelp: {
          'es6': 'es6 modules',
          'legacy': 'a custom format used by dartdevc, similar to AMD',
          'node': 'node.js modules (https://nodejs.org/api/modules.html)'
        },
        defaultsTo: 'legacy')
    ..addFlag('closure-experimental',
        help: 'emit Closure Compiler-friendly code (experimental)',
        defaultsTo: false)
    ..addFlag('destructure-named-params',
        help: 'Destructure named parameters', defaultsTo: false)
    ..addFlag('unsafe-force-compile',
        help: 'Compile code even if it has errors. ಠ_ಠ\n'
            'This has undefined behavior!',
        defaultsTo: false);
}

/// A unit of Dart code that can be built into a single JavaScript module.
class BuildUnit {
  /// The name of this module.
  final String name;

  /// Build root.  All library names are relative to this path/prefix.
  final String buildRoot;

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

  BuildUnit(this.name, this.buildRoot, this.sources, this.libraryToModule);
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

  /// The binary contents of the API summary file, including APIs from each of
  /// the [libraries] in this module.
  final List<int> summaryBytes;

  JSModuleFile(
      this.name, this.errors, this.code, this.sourceMap, this.summaryBytes);

  JSModuleFile.invalid(this.name, this.errors)
      : code = null,
        sourceMap = null,
        summaryBytes = null;

  /// True if this library was successfully compiled.
  bool get isValid => code != null;

  /// Adjusts the source paths in [sourceMap] to be relative to [sourceMapPath],
  /// and returns the new map.
  ///
  /// See also [writeSourceMap].
  Map placeSourceMap(String sourceMapPath) {
    var dir = path.dirname(sourceMapPath);

    var map = new Map.from(this.sourceMap);
    List list = new List.from(map['sources']);
    map['sources'] = list;
    for (int i = 0; i < list.length; i++) {
      list[i] = path.relative(list[i], from: dir);
    }
    return map;
  }
}

/// (Public for tests) the error code used when a part is missing.
final missingPartErrorCode = const CompileTimeErrorCode(
    'MISSING_PART', 'The part was not supplied as an input to the compiler.');

/// (Public for tests) the error code used when a part is unused.
final unusedPartWarningCode = const StaticWarningCode(
    'UNUSED_PART', 'The part was not used by any libraries being compiled.');
