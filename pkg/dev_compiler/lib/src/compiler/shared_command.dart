// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:args/args.dart';
import 'package:front_end/src/api_unstable/ddc.dart'
    show InitializedCompilerState;
import 'package:path/path.dart' as path;
import 'module_builder.dart';
import '../analyzer/command.dart' as analyzer_compiler;
import '../analyzer/driver.dart' show CompilerAnalysisDriver;
import '../kernel/command.dart' as kernel_compiler;

/// Shared code between Analyzer and Kernel CLI interfaces.
///
/// This file should only implement functionality that does not depend on
/// Analyzer/Kernel imports.

/// Variables that indicate which libraries are available in dev compiler.
// TODO(jmesserly): provide an option to compile without dart:html & friends?
Map<String, String> sdkLibraryVariables = {
  'dart.isVM': 'false',
  'dart.library.async': 'true',
  'dart.library.core': 'true',
  'dart.library.collection': 'true',
  'dart.library.convert': 'true',
  // TODO(jmesserly): this is not really supported in dart4web other than
  // `debugger()`
  'dart.library.developer': 'true',
  'dart.library.io': 'false',
  'dart.library.isolate': 'false',
  'dart.library.js': 'true',
  'dart.library.js_util': 'true',
  'dart.library.math': 'true',
  'dart.library.mirrors': 'false',
  'dart.library.typed_data': 'true',
  'dart.library.indexed_db': 'true',
  'dart.library.html': 'true',
  'dart.library.html_common': 'true',
  'dart.library.svg': 'true',
  'dart.library.ui': 'false',
  'dart.library.web_audio': 'true',
  'dart.library.web_gl': 'true',
  'dart.library.web_sql': 'true',
};

/// Shared compiler options between `dartdevc` kernel and analyzer backends.
class SharedCompilerOptions {
  /// Whether to emit the source mapping file.
  ///
  /// This supports debugging the original source code instead of the generated
  /// code.
  final bool sourceMap;

  /// Whether to emit the source mapping file in the program text, so the
  /// runtime can enable synchronous stack trace deobsfuscation.
  final bool inlineSourceMap;

  /// Whether to emit a summary file containing API signatures.
  ///
  /// This is required for a modular build process.
  final bool summarizeApi;

  /// Whether to preserve metdata only accessible via mirrors.
  final bool emitMetadata;

  // Whether to enable assertions.
  final bool enableAsserts;

  /// Whether to compile code in a more permissive REPL mode allowing access
  /// to private members across library boundaries.
  ///
  /// This should only set `true` by our REPL compiler.
  bool replCompile;

  /// Mapping from absolute file paths to bazel short path to substitute in
  /// source maps.
  final Map<String, String> bazelMapping;

  final Map<String, String> summaryModules;

  final List<ModuleFormat> moduleFormats;

  /// Experimental language features that are enabled/disabled, see
  /// [the spec](https://github.com/dart-lang/sdk/blob/master/docs/process/experimental-flags.md)
  /// for more details.
  final Map<String, bool> experiments;

  /// The name of the module.
  ///
  /// This used when to support file concatenation. The JS module will contain
  /// its module name inside itself, allowing it to declare the module name
  /// independently of the file.
  String moduleName;

  SharedCompilerOptions(
      {this.sourceMap = true,
      this.inlineSourceMap = false,
      this.summarizeApi = true,
      this.emitMetadata = false,
      this.enableAsserts = true,
      this.replCompile = false,
      this.bazelMapping = const {},
      this.summaryModules = const {},
      this.moduleFormats = const [],
      this.experiments = const {},
      this.moduleName});

  SharedCompilerOptions.fromArguments(ArgResults args,
      [String moduleRoot, String summaryExtension])
      : this(
            sourceMap: args['source-map'] as bool,
            inlineSourceMap: args['inline-source-map'] as bool,
            summarizeApi: args['summarize'] as bool,
            emitMetadata: args['emit-metadata'] as bool,
            enableAsserts: args['enable-asserts'] as bool,
            experiments:
                _parseExperiments(args['enable-experiment'] as List<String>),
            bazelMapping:
                _parseBazelMappings(args['bazel-mapping'] as List<String>),
            summaryModules: _parseCustomSummaryModules(
                args['summary'] as List<String>, moduleRoot, summaryExtension),
            moduleFormats: parseModuleFormatOption(args),
            moduleName: _getModuleName(args, moduleRoot),
            replCompile: args['repl-compile'] as bool);

  static void addArguments(ArgParser parser, {bool hide = true}) {
    addModuleFormatOptions(parser, hide: hide);

    parser
      ..addMultiOption('summary',
          abbr: 's',
          help: 'summary file(s) of imported libraries, optionally\n'
              'with module import path: -s path.sum=js/import/path')
      ..addMultiOption('enable-experiment',
          help: 'used to enable/disable experimental language features',
          hide: hide)
      ..addFlag('summarize',
          help: 'emit an API summary file', defaultsTo: true, hide: hide)
      ..addFlag('source-map',
          help: 'emit source mapping', defaultsTo: true, hide: hide)
      ..addFlag('inline-source-map',
          help: 'emit source mapping inline', defaultsTo: false, hide: hide)
      ..addFlag('emit-metadata',
          help: 'emit metadata annotations queriable via mirrors', hide: hide)
      ..addFlag('enable-asserts',
          help: 'enable assertions', defaultsTo: true, hide: hide)
      ..addOption('module-name',
          help: 'The output module name, used in some JS module formats.\n'
              'Defaults to the output file name (without .js).')
      // TODO(jmesserly): rename this, it has nothing to do with bazel.
      ..addMultiOption('bazel-mapping',
          help: '--bazel-mapping=gen/to/library.dart,to/library.dart\n'
              'adjusts the path in source maps.',
          splitCommas: false,
          hide: hide)
      ..addOption('library-root',
          help: '(deprecated) used to name libraries inside the module, '
              'ignored with -k.',
          hide: hide)
      ..addFlag('repl-compile',
          help: 'compile in a more permissive REPL mode, allowing access'
              ' to private members across library boundaries. This should'
              ' only be used by debugging tools.',
          defaultsTo: false,
          hide: hide);
  }

  static String _getModuleName(ArgResults args, String moduleRoot) {
    var moduleName = args['module-name'] as String;
    if (moduleName == null) {
      var outPaths = args['out'];
      var outPath = outPaths is String
          ? outPaths
          : (outPaths as List<String>)
              .firstWhere((_) => true, orElse: () => null);

      // TODO(jmesserly): fix the debugger console so it's not passing invalid
      // options.
      if (outPath == null) return null;
      if (moduleRoot != null) {
        // TODO(jmesserly): remove this legacy support after a deprecation
        // period. (Mainly this is to give time for migrating build rules.)
        moduleName =
            path.withoutExtension(path.relative(outPath, from: moduleRoot));
      } else {
        moduleName = path.basenameWithoutExtension(outPath);
      }
    }
    // TODO(jmesserly): this should probably use sourcePathToUri.
    //
    // Also we should not need this logic if the user passed in the module name
    // explicitly. It is here for backwards compatibility until we can confirm
    // that build systems do not depend on passing windows-style paths here.
    return path.toUri(moduleName).toString();
  }
}

/// Finds explicit module names of the form `path=name` in [summaryPaths],
/// and returns the path to mapping in an ordered map from `path` to `name`.
///
/// A summary path can contain "=" followed by an explicit module name to
/// allow working with summaries whose physical location is outside of the
/// module root directory.
Map<String, String> _parseCustomSummaryModules(List<String> summaryPaths,
    [String moduleRoot, String summaryExt]) {
  var pathToModule = <String, String>{};
  if (summaryPaths == null) return pathToModule;
  for (var summaryPath in summaryPaths) {
    var equalSign = summaryPath.indexOf("=");
    String modulePath;
    var summaryPathWithoutExt = summaryExt != null
        ? summaryPath.substring(
            0,
            // Strip off the extension, including the last `.`.
            summaryPath.length - (summaryExt.length + 1))
        : path.withoutExtension(summaryPath);
    if (equalSign != -1) {
      modulePath = summaryPath.substring(equalSign + 1);
      summaryPath = summaryPath.substring(0, equalSign);
    } else if (moduleRoot != null && path.isWithin(moduleRoot, summaryPath)) {
      // TODO(jmesserly): remove this, it's legacy --module-root support.
      modulePath = path.url.joinAll(
          path.split(path.relative(summaryPathWithoutExt, from: moduleRoot)));
    } else {
      modulePath = path.basename(summaryPathWithoutExt);
    }
    pathToModule[summaryPath] = modulePath;
  }
  return pathToModule;
}

Map<String, bool> _parseExperiments(List<String> arguments) {
  var result = <String, bool>{};
  for (var argument in arguments) {
    for (var feature in argument.split(',')) {
      if (feature.startsWith('no-')) {
        result[feature.substring(3)] = false;
      } else {
        result[feature] = true;
      }
    }
  }
  return result;
}

Map<String, String> _parseBazelMappings(List<String> argument) {
  var mappings = <String, String>{};
  for (var mapping in argument) {
    var splitMapping = mapping.split(',');
    if (splitMapping.length >= 2) {
      mappings[path.absolute(splitMapping[0])] = splitMapping[1];
    }
  }
  return mappings;
}

/// Taken from analyzer to implement `--ignore-unrecognized-flags`
List<String> filterUnknownArguments(List<String> args, ArgParser parser) {
  if (!args.contains('--ignore-unrecognized-flags')) return args;

  var knownOptions = <String>{};
  var knownAbbreviations = <String>{};
  parser.options.forEach((String name, Option option) {
    knownOptions.add(name);
    var abbreviation = option.abbr;
    if (abbreviation != null) {
      knownAbbreviations.add(abbreviation);
    }
    if (option.negatable) {
      knownOptions.add('no-$name');
    }
  });

  String optionName(int prefixLength, String arg) {
    int equalsOffset = arg.lastIndexOf('=');
    if (equalsOffset < 0) {
      return arg.substring(prefixLength);
    }
    return arg.substring(prefixLength, equalsOffset);
  }

  var filtered = <String>[];
  for (var arg in args) {
    if (arg.startsWith('--') && arg.length > 2) {
      if (knownOptions.contains(optionName(2, arg))) {
        filtered.add(arg);
      }
    } else if (arg.startsWith('-') && arg.length > 1) {
      if (knownAbbreviations.contains(optionName(1, arg))) {
        filtered.add(arg);
      }
    } else {
      filtered.add(arg);
    }
  }
  return filtered;
}

/// Convert a [source] string to a Uri, where the source may be a
/// dart/file/package URI or a local win/mac/linux path.
///
/// If [source] is null, this will return null.
Uri sourcePathToUri(String source, {bool windows}) {
  if (source == null) return null;
  if (windows == null) {
    // Running on the web the Platform check will fail, and we can't use
    // fromEnvironment because internally it's set to true for dart.library.io.
    // So just catch the exception and if it fails then we're definitely not on
    // Windows.
    try {
      windows = Platform.isWindows;
    } catch (e) {
      windows = false;
    }
  }
  if (windows) {
    source = source.replaceAll("\\", "/");
  }

  Uri result = Uri.base.resolve(source);
  if (windows && result.scheme.length == 1) {
    // Assume c: or similar --- interpret as file path.
    return Uri.file(source, windows: true);
  }
  return result;
}

Uri sourcePathToRelativeUri(String source, {bool windows}) {
  var uri = sourcePathToUri(source, windows: windows);
  if (uri.scheme == 'file') {
    var uriPath = uri.path;
    var root = Uri.base.path;
    if (uriPath.startsWith(root)) {
      return path.toUri(uriPath.substring(root.length));
    }
  }
  return uri;
}

/// Adjusts the source paths in [sourceMap] to be relative to [sourceMapPath],
/// and returns the new map.  Relative paths are in terms of URIs ('/'), not
/// local OS paths (e.g., windows '\'). Sources with a multi-root scheme
/// matching [multiRootScheme] are adjusted to be relative to
/// [multiRootOutputPath].
// TODO(jmesserly): find a new home for this.
Map placeSourceMap(Map sourceMap, String sourceMapPath,
    Map<String, String> bazelMappings, String multiRootScheme,
    {String multiRootOutputPath}) {
  var map = Map.from(sourceMap);
  // Convert to a local file path if it's not.
  sourceMapPath = path.fromUri(sourcePathToUri(sourceMapPath));
  var sourceMapDir = path.dirname(path.absolute(sourceMapPath));
  var list = (map['sources'] as List).toList();

  String makeRelative(String sourcePath) {
    var uri = sourcePathToUri(sourcePath);
    var scheme = uri.scheme;
    if (scheme == 'dart' || scheme == 'package' || scheme == multiRootScheme) {
      if (scheme == multiRootScheme) {
        var multiRootPath = '$multiRootOutputPath${uri.path}';
        multiRootPath = path.relative(multiRootPath, from: sourceMapDir);
        return multiRootPath;
      }
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
    list[i] = makeRelative(list[i] as String);
  }
  map['sources'] = list;
  map['file'] = makeRelative(map['file'] as String);
  return map;
}

/// Invoke the compiler with [args], optionally with the kernel backend if
/// [isKernel] is set.
///
/// Returns a [CompilerResult], with a success flag indicating whether the
/// program compiled without any fatal errors.
///
/// The result may also contain a [previousResult], which can be passed back in
/// for batch/worker executions to attempt to existing state.
Future<CompilerResult> compile(ParsedArguments args,
    {CompilerResult previousResult, Map<Uri, List<int>> inputDigests}) {
  if (previousResult != null && !args.isBatchOrWorker) {
    throw ArgumentError(
        'previousResult requires --batch or --bazel_worker mode/');
  }
  if (args.isKernel) {
    return kernel_compiler.compile(args.rest,
        compilerState: previousResult?.kernelState,
        useIncrementalCompiler: args.useIncrementalCompiler,
        inputDigests: inputDigests);
  } else {
    var result = analyzer_compiler.compile(args.rest,
        compilerState: previousResult?.analyzerState);
    if (args.isBatchOrWorker) {
      AnalysisEngine.instance.clearCaches();
    }
    return Future.value(result);
  }
}

/// The result of a single `dartdevc` compilation.
///
/// Typically used for exiting the proceess with [exitCode] or checking the
/// [success] of the compilation.
///
/// For batch/worker compilations, the [compilerState] provides an opprotunity
/// to reuse state from the previous run, if the options/input summaries are
/// equiavlent. Otherwise it will be discarded.
class CompilerResult {
  /// Optionally provides the front_end state from the previous compilation,
  /// which can be passed to [compile] to potentially speeed up the next
  /// compilation.
  ///
  /// This field is unused when using the Analyzer-backend for DDC.
  final InitializedCompilerState kernelState;

  /// Optionally provides the analyzer state from the previous compilation,
  /// which can be passed to [compile] to potentially speeed up the next
  /// compilation.
  ///
  /// This field is unused when using the Kernel-backend for DDC.
  final CompilerAnalysisDriver analyzerState;

  /// The process exit code of the compiler.
  final int exitCode;

  CompilerResult(this.exitCode, {this.kernelState, this.analyzerState}) {
    assert(kernelState == null || analyzerState == null,
        'kernel and analyzer state should not both be supplied');
  }

  /// Gets the kernel or analyzer compiler state, if any.
  Object get compilerState => kernelState ?? analyzerState;

  /// Whether the program compiled without any fatal errors (equivalent to
  /// [exitCode] == 0).
  bool get success => exitCode == 0;

  /// Whether the compiler crashed (i.e. threw an unhandled exeception,
  /// typically indicating an internal error in DDC itself or its front end).
  bool get crashed => exitCode == 70;
}

/// Stores the result of preprocessing `dartdevc` command line arguments.
///
/// `dartdevc` preprocesses arguments to support some features that
/// `package:args` does not handle (training `@` to reference arguments in a
/// file).
///
/// [isBatch]/[isWorker] mode are preprocessed because they can combine
/// argument lists from the initial invocation and from batch/worker jobs.
///
/// [isKernel] is also preprocessed because the Kernel backend supports
/// different options compared to the Analyzer backend.
class ParsedArguments {
  /// The user's arguments to the compiler for this compialtion.
  final List<String> rest;

  /// Whether to run in `--batch` mode, e.g the Dart SDK and Language tests.
  ///
  /// Similar to [isWorker] but with a different protocol.
  /// See also [isBatchOrWorker].
  final bool isBatch;

  /// Whether to run in `--bazel_worker` mode, e.g. for Bazel builds.
  ///
  /// Similar to [isBatch] but with a different protocol.
  /// See also [isBatchOrWorker].
  final bool isWorker;

  /// Whether to use the Kernel-based back end for dartdevc.
  ///
  /// This is similar to the Analyzer-based back end, but uses Kernel trees
  /// instead of Analyzer trees for representing the Dart code.
  final bool isKernel;

  /// Whether to re-use the last compiler result when in a worker.
  ///
  /// This is useful if we are repeatedly compiling things in the same context,
  /// e.g. in a debugger REPL.
  final bool reuseResult;

  /// Whether to use the incremental compiler for compiling.
  ///
  /// Note that this only makes sense when also reusing results.
  final bool useIncrementalCompiler;

  ParsedArguments._(this.rest,
      {this.isBatch = false,
      this.isWorker = false,
      this.isKernel = false,
      this.reuseResult = false,
      this.useIncrementalCompiler = false});

  /// Preprocess arguments to determine whether DDK is used in batch mode or as a
  /// persistent worker.
  ///
  /// When used in batch mode, we expect a `--batch` parameter last.
  ///
  /// When used as a persistent bazel worker, the `--persistent_worker` might be
  /// present, and an argument of the form `@path/to/file` might be provided. The
  /// latter needs to be replaced by reading all the contents of the
  /// file and expanding them into the resulting argument list.
  factory ParsedArguments.from(List<String> args) {
    if (args.isEmpty) return ParsedArguments._(args);

    var newArgs = <String>[];
    bool isWorker = false;
    bool isBatch = false;
    bool isKernel = false;
    bool reuseResult = false;
    bool useIncrementalCompiler = false;
    var len = args.length;
    for (int i = 0; i < len; i++) {
      var arg = args[i];
      var isLastArg = i == len - 1;
      if (isLastArg && arg.startsWith('@')) {
        var extra = _readLines(arg.substring(1)).toList();
        if (extra.remove('--kernel') || extra.remove('-k')) {
          isKernel = true;
        }
        newArgs.addAll(extra);
      } else if (arg == '--persistent_worker') {
        isWorker = true;
      } else if (isLastArg && arg == '--batch') {
        isBatch = true;
      } else if (arg == '--kernel' || arg == '-k') {
        isKernel = true;
      } else if (arg == '--reuse-compiler-result') {
        reuseResult = true;
      } else if (arg == '--use-incremental-compiler') {
        useIncrementalCompiler = true;
      } else {
        newArgs.add(arg);
      }
    }
    return ParsedArguments._(newArgs,
        isWorker: isWorker,
        isBatch: isBatch,
        isKernel: isKernel,
        reuseResult: reuseResult,
        useIncrementalCompiler: useIncrementalCompiler);
  }

  /// Whether the compiler is running in [isBatch] or [isWorker] mode.
  ///
  /// Both modes are generally equivalent from the compiler's perspective,
  /// the main difference is that they use distinct protocols to communicate
  /// jobs to the compiler.
  bool get isBatchOrWorker => isBatch || isWorker;

  /// Merge [args] and return the new parsed arguments.
  ///
  /// Typically used when [isBatchOrWorker] is set to merge the compilation's
  /// arguments with any global ones that were provided when the worker started.
  ParsedArguments merge(List<String> arguments) {
    // Parse the arguments again so `--kernel` can be passed. This provides
    // added safety that we are really compiling in Kernel mode, if somehow the
    // worker was not initialized correctly.
    var newArgs = ParsedArguments.from(arguments);
    if (newArgs.isBatchOrWorker) {
      throw ArgumentError('cannot change batch or worker mode after startup.');
    }
    return ParsedArguments._(rest.toList()..addAll(newArgs.rest),
        isWorker: isWorker,
        isBatch: isBatch,
        isKernel: isKernel || newArgs.isKernel,
        reuseResult: reuseResult || newArgs.reuseResult,
        useIncrementalCompiler:
            useIncrementalCompiler || newArgs.useIncrementalCompiler);
  }
}

/// Return all lines in a file found at [path].
Iterable<String> _readLines(String path) {
  try {
    return File(path).readAsLinesSync().where((String line) => line.isNotEmpty);
  } on FileSystemException catch (e) {
    throw Exception('Failed to read $path: $e');
  }
}
