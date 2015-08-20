// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line tool to run the checker on a Dart program.
library dev_compiler.src.compiler;

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:io';

import 'package:analyzer/src/generated/ast.dart' show CompilationUnit;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisEngine, AnalysisContext, ChangeSet, ParseDartTask;
import 'package:analyzer/src/generated/error.dart'
    show AnalysisError, ErrorSeverity, ErrorType;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/task/html.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html;
import 'package:logging/logging.dart' show Level, Logger, LogRecord;
import 'package:path/path.dart' as path;

import 'package:dev_compiler/strong_mode.dart' show StrongModeOptions;

import 'analysis_context.dart';
import 'checker/checker.dart';
import 'checker/rules.dart';
import 'codegen/html_codegen.dart' as html_codegen;
import 'codegen/js_codegen.dart';
import 'info.dart'
    show AnalyzerMessage, CheckerResults, LibraryInfo, LibraryUnit;
import 'options.dart';
import 'report.dart';

/// Sets up the type checker logger to print a span that highlights error
/// messages.
StreamSubscription setupLogger(Level level, printFn) {
  Logger.root.level = level;
  return Logger.root.onRecord.listen((LogRecord rec) {
    printFn('${rec.level.name.toLowerCase()}: ${rec.message}');
  });
}

CompilerOptions validateOptions(List<String> args, {bool forceOutDir: false}) {
  var options = parseOptions(args, forceOutDir: forceOutDir);
  if (!options.help) {
    var srcOpts = options.sourceOptions;
    if (!srcOpts.useMockSdk && srcOpts.dartSdkPath == null) {
      print('Could not automatically find dart sdk path.');
      print('Please pass in explicitly: --dart-sdk <path>');
      exit(1);
    }
    if (options.inputs.length == 0) {
      print('Expected filename.');
      return null;
    }
  }
  return options;
}

bool compile(CompilerOptions options) {
  assert(!options.serverMode);
  var context = createAnalysisContextWithSources(
      options.strongOptions, options.sourceOptions);
  var reporter = createErrorReporter(context, options);
  return new BatchCompiler(context, options, reporter: reporter).run();
}

class BatchCompiler extends AbstractCompiler {
  JSGenerator _jsGen;
  LibraryElement _dartCore;
  String _runtimeOutputDir;

  /// Already compiled sources, so we don't compile them again.
  final _compiled = new HashSet<LibraryElement>();

  bool _failure = false;
  bool get failure => _failure;

  BatchCompiler(AnalysisContext context, CompilerOptions options,
      {AnalysisErrorListener reporter})
      : super(
            context,
            options,
            new ErrorCollector(
                reporter ?? AnalysisErrorListener.NULL_LISTENER)) {
    _inputBaseDir = options.inputBaseDir;
    if (outputDir != null) {
      _jsGen = new JSGenerator(this);
      _runtimeOutputDir = path.join(outputDir, 'dev_compiler', 'runtime');
    }
    _dartCore = context.typeProvider.objectType.element.library;
  }

  ErrorCollector get reporter => checker.reporter;

  void reset() {
    _compiled.clear();
  }

  /// Compiles every file in [options.inputs].
  /// Returns true on successful compile.
  bool run() {
    var clock = new Stopwatch()..start();
    options.inputs.forEach(compileFromUriString);
    clock.stop();
    var time = (clock.elapsedMilliseconds / 1000).toStringAsFixed(2);
    _log.fine('Compiled ${_compiled.length} libraries in ${time} s\n');

    return !_failure;
  }

  void compileFromUriString(String uriString) {
    _compileFromUri(stringToUri(uriString));
  }

  void _compileFromUri(Uri uri) {
    if (!uri.isAbsolute) {
      throw new ArgumentError.value('$uri', 'uri', 'must be absolute');
    }
    var source = context.sourceFactory.forUri(Uri.encodeFull('$uri'));
    if (source == null) {
      throw new ArgumentError.value('$uri', 'uri', 'could not find source for');
    }
    compileSource(source);
  }

  void compileSource(Source source) {
    if (AnalysisEngine.isHtmlFileName(source.uri.path)) {
      _compileHtml(source);
    } else {
      _compileLibrary(context.computeLibraryElement(source));
    }
    reporter.flush();
  }

  void _compileLibrary(LibraryElement library) {
    if (!_compiled.add(library)) return;

    if (!options.checkSdk && library.source.uri.scheme == 'dart') {
      if (_jsGen != null) _copyDartRuntime();
      return;
    }

    // TODO(jmesserly): in incremental mode, we can skip the transitive
    // compile of imports/exports.
    _compileLibrary(_dartCore); // implicit dart:core dependency
    library.importedLibraries.forEach(_compileLibrary);
    library.exportedLibraries.forEach(_compileLibrary);

    var unitElements = [library.definingCompilationUnit]..addAll(library.parts);
    var units = <CompilationUnit>[];

    bool failureInLib = false;
    for (var element in unitElements) {
      var unit = context.resolveCompilationUnit(element.source, library);
      units.add(unit);
      failureInLib = logErrors(element.source) || failureInLib;
      checker.visitCompilationUnit(unit);
      if (checker.failure) failureInLib = true;
    }

    if (failureInLib) {
      _failure = true;
      if (!options.codegenOptions.forceCompile) return;
    }

    if (_jsGen != null) {
      var unit = units.first;
      var parts = units.skip(1).toList();
      _jsGen.generateLibrary(new LibraryUnit(unit, parts));
    }
  }

  void _copyDartRuntime() {
    for (var file in defaultRuntimeFiles) {
      var input = path.join(options.runtimeDir, file);
      var output = path.join(_runtimeOutputDir, file);
      new Directory(path.dirname(output)).createSync(recursive: true);
      new File(input).copySync(output);
    }
  }

  void _compileHtml(Source source) {
    // TODO(jmesserly): reuse DartScriptsTask instead of copy/paste.
    var contents = context.getContents(source);
    var document = html.parse(contents.data, generateSpans: true);
    var scripts = document.querySelectorAll('script[type="application/dart"]');

    var loadedLibs = new LinkedHashSet<Uri>();

    var htmlOutDir = path.dirname(getOutputPath(source.uri));
    for (var script in scripts) {
      Source scriptSource = null;
      var srcAttr = script.attributes['src'];
      if (srcAttr == null) {
        if (script.hasContent()) {
          var fragments = <ScriptFragment>[];
          for (var node in script.nodes) {
            if (node is html.Text) {
              var start = node.sourceSpan.start;
              fragments.add(new ScriptFragment(
                  start.offset, start.line, start.column, node.data));
            }
          }
          scriptSource = new DartScript(source, fragments);
        }
      } else if (AnalysisEngine.isDartFileName(srcAttr)) {
        scriptSource = context.sourceFactory.resolveUri(source, srcAttr);
      }

      if (scriptSource != null) {
        var lib = context.computeLibraryElement(scriptSource);
        _compileLibrary(lib);
        script.replaceWith(_linkLibraries(lib, loadedLibs, from: htmlOutDir));
      }
    }

    new File(getOutputPath(source.uri)).openSync(mode: FileMode.WRITE)
      ..writeStringSync(document.outerHtml)
      ..writeStringSync('\n')
      ..closeSync();
  }

  html.DocumentFragment _linkLibraries(
      LibraryElement mainLib, LinkedHashSet<Uri> loaded,
      {String from}) {
    assert(from != null);
    var alreadyLoaded = loaded.length;
    _collectLibraries(mainLib, loaded);

    var newLibs = loaded.skip(alreadyLoaded);
    var df = new html.DocumentFragment();

    for (var uri in newLibs) {
      if (uri.scheme == 'dart') {
        if (uri.path == 'core') {
          // TODO(jmesserly): it would be nice to not special case these.
          for (var file in defaultRuntimeFiles) {
            file = path.join(_runtimeOutputDir, file);
            df.append(
                html_codegen.libraryInclude(path.relative(file, from: from)));
          }
        }
      } else {
        var file = path.join(outputDir, getModulePath(uri));
        df.append(html_codegen.libraryInclude(path.relative(file, from: from)));
      }
    }

    df.append(html_codegen.invokeMain(getModuleName(mainLib.source.uri)));
    return df;
  }

  void _collectLibraries(LibraryElement lib, LinkedHashSet<Uri> loaded) {
    var uri = lib.source.uri;
    if (!loaded.add(uri)) return;
    _collectLibraries(_dartCore, loaded);
    for (var l in lib.importedLibraries) _collectLibraries(l, loaded);
    for (var l in lib.exportedLibraries) _collectLibraries(l, loaded);
    // Move the item to the end of the list.
    loaded.remove(uri);
    loaded.add(uri);
  }
}

abstract class AbstractCompiler {
  final CompilerOptions options;
  final AnalysisContext context;
  final CodeChecker checker;

  AbstractCompiler(AnalysisContext context, CompilerOptions options,
      [AnalysisErrorListener reporter])
      : context = context,
        options = options,
        checker = createChecker(context.typeProvider, options.strongOptions,
            reporter ?? AnalysisErrorListener.NULL_LISTENER) {
    enableDevCompilerInference(context, options.strongOptions);
  }

  static CodeChecker createChecker(TypeProvider typeProvider,
      StrongModeOptions options, AnalysisErrorListener reporter) {
    return new CodeChecker(
        new RestrictedRules(typeProvider, options: options), reporter, options);
  }

  String get outputDir => options.codegenOptions.outputDir;
  TypeRules get rules => checker.rules;
  AnalysisErrorListener get reporter => checker.reporter;

  Uri stringToUri(String uriString) {
    var uri = uriString.startsWith('dart:') || uriString.startsWith('package:')
        ? Uri.parse(uriString)
        : new Uri.file(path.absolute(uriString));
    return uri;
  }

  /// Directory presumed to be the common prefix for all input file:// URIs.
  /// Used when computing output paths.
  ///
  /// For example:
  ///   dartdevc -o out foo/a.dart bar/b.dart
  ///
  /// Will produce:
  ///   out/foo/a.dart
  ///   out/bar/b.dart
  ///
  /// This is only used if at least one of [options.codegenOptions.inputs] is
  /// a file URI.
  // TODO(jmesserly): do we need an option for this?
  // Other ideas: we could look up and see what package the file is in, treat
  // that as a base path. We could also use the current working directory as
  // the base.
  String get inputBaseDir {
    if (_inputBaseDir == null) {
      List<String> common = null;
      for (var uri in options.inputs.map(stringToUri)) {
        if (uri.scheme != 'file') continue;

        var segments = path.split(path.dirname(uri.path));
        if (common == null) {
          common = segments;
        } else {
          int len = math.min(common.length, segments.length);
          while (len > 0 && common[len - 1] != segments[len - 1]) {
            len--;
          }
          common.length = len;
        }
      }
      _inputBaseDir = common == null ? '' : path.joinAll(common);
    }
    return _inputBaseDir;
  }

  String _inputBaseDir;

  String getOutputPath(Uri uri) => path.join(outputDir, getModulePath(uri));

  /// Like [getModuleName] but includes the file extension, either .js or .html.
  String getModulePath(Uri uri) {
    var ext = path.extension(uri.path);
    if (ext == '.dart' || ext == '' && uri.scheme == 'dart') ext = '.js';
    return getModuleName(uri) + ext;
  }

  /// Gets the module name, without extension. For example:
  ///
  /// * dart:core -> dart/core
  /// * file:foo/bar/baz.dart -> foo/bar/baz
  /// * package:qux/qux.dart -> qux/qux
  ///
  /// For file: URLs this will also make them relative to [inputBaseDir].
  // TODO(jmesserly): we need to figure out a way to keep package and file URLs
  // from conflicting.
  String getModuleName(Uri uri) {
    var filepath = path.withoutExtension(uri.path);
    if (uri.scheme == 'dart') {
      return 'dart/$filepath';
    } else if (uri.scheme == 'file') {
      return path.relative(filepath, from: inputBaseDir);
    } else {
      assert(uri.scheme == 'package');
      // filepath is good here, we want the output to start with a directory
      // matching the package name.
      return filepath;
    }
  }

  /// Log any errors encountered when resolving [source] and return whether any
  /// errors were found.
  bool logErrors(Source source) {
    List<AnalysisError> errors = context.computeErrors(source);
    bool failure = false;
    if (errors.isNotEmpty) {
      for (var error in errors) {
        // Always skip TODOs.
        if (error.errorCode.type == ErrorType.TODO) continue;

        // Skip hints for now. In the future these could be turned on via flags.
        if (error.errorCode.errorSeverity.ordinal <
            ErrorSeverity.WARNING.ordinal) {
          continue;
        }

        // All analyzer warnings or errors are errors for DDC.
        failure = true;
        reporter.onError(error);
      }
    }
    return failure;
  }
}

AnalysisErrorListener createErrorReporter(
    AnalysisContext context, CompilerOptions options) {
  return options.dumpInfo
      ? new SummaryReporter(context, options.logLevel)
      : new LogReporter(context, useColors: options.useColors);
}

// TODO(jmesserly): find a better home for these.
/// Curated order to minimize lazy classes needed by dart:core and its
/// transitive SDK imports.
const corelibOrder = const [
  'dart.core',
  'dart.collection',
  'dart._internal',
  'dart.math',
  'dart._interceptors',
  'dart.async',
  'dart._foreign_helper',
  'dart._js_embedded_names',
  'dart._js_helper',
  'dart.isolate',
  'dart.typed_data',
  'dart._native_typed_data',
  'dart._isolate_helper',
  'dart._js_primitives',
  'dart.convert',
  // TODO(jmesserly): these are not part of corelib library cycle, and shouldn't
  // be listed here. Instead, their source should be copied on demand if they
  // are actually used by the application.
  'dart.mirrors',
  'dart._js_mirrors',
  'dart.js'
  // _foreign_helper is not included, as it only defines the JS builtin that
  // the compiler handles at compile time.
];

/// Runtime files added to all applications when running the compiler in the
/// command line.
final defaultRuntimeFiles = () {
  var files = [
    'harmony_feature_check.js',
    'dart_utils.js',
    'dart_library.js',
    '_errors.js',
    '_generators.js',
    '_types.js',
    '_rtti.js',
    '_classes.js',
    '_operations.js',
    'dart_runtime.js',
  ];
  files.addAll(corelibOrder.map((l) => l.replaceAll('.', '/') + '.js'));
  return files;
}();

final _log = new Logger('dev_compiler.src.compiler');
