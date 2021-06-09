// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:front_end/src/api_unstable/ddc.dart'
    show InitializedCompilerState, parseExperimentalArguments;
import 'package:path/path.dart' as p;

import '../kernel/command.dart' as kernel_compiler;
import 'module_builder.dart';

// TODO(nshahan) Merge all of this file the locations where they are used in
// the kernel (only) version of DDC.

/// Previously was shared code between Analyzer and Kernel CLI interfaces.
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

/// Compiler options for the `dartdevc` backend.
class SharedCompilerOptions {
  /// Whether to emit the source mapping file.
  ///
  /// This supports debugging the original source code instead of the generated
  /// code.
  final bool sourceMap;

  /// Whether to emit the source mapping file in the program text, so the
  /// runtime can enable synchronous stack trace deobsfuscation.
  final bool inlineSourceMap;

  /// Whether to emit the full compiled kernel.
  ///
  /// This is used by expression compiler worker, launched from the debugger
  /// in webdev and google3 scenarios, for expression evaluation features.
  /// Full kernel for compiled files is needed to be able to compile
  /// expressions on demand in the current scope of a breakpoint.
  final bool emitFullCompiledKernel;

  /// Whether to emit a summary file containing API signatures.
  ///
  /// This is required for a modular build process.
  final bool summarizeApi;

  // Whether to enable assertions.
  final bool enableAsserts;

  /// Whether to compile code in a more permissive REPL mode allowing access
  /// to private members across library boundaries.
  ///
  /// This should only set `true` by our REPL compiler.
  bool replCompile;

  /// Whether to emit the debug metadata
  ///
  /// Debugger uses this information about to construct mapping between
  /// modules and libraries that otherwise requires expensive communication with
  /// the browser.
  final bool emitDebugMetadata;

  final Map<String, String> summaryModules;

  final List<ModuleFormat> moduleFormats;

  /// The name of the module.
  ///
  /// This is used to support file concatenation. The JS module will contain its
  /// module name inside itself, allowing it to declare the module name
  /// independently of the file.
  final String moduleName;

  /// Custom scheme to indicate a multi-root uri.
  final String multiRootScheme;

  /// Path to set multi-root files relative to when generating source-maps.
  final String multiRootOutputPath;

  /// Experimental language features that are enabled/disabled, see
  /// [the spec](https://github.com/dart-lang/sdk/blob/master/docs/process/experimental-flags.md)
  /// for more details.
  final Map<String, bool> experiments;

  final bool soundNullSafety;

  SharedCompilerOptions(
      {this.sourceMap = true,
      this.inlineSourceMap = false,
      this.summarizeApi = true,
      this.enableAsserts = true,
      this.replCompile = false,
      this.emitDebugMetadata = false,
      this.emitFullCompiledKernel = false,
      this.summaryModules = const {},
      this.moduleFormats = const [],
      this.moduleName,
      this.multiRootScheme,
      this.multiRootOutputPath,
      this.experiments = const {},
      this.soundNullSafety = false});

  SharedCompilerOptions.fromArguments(ArgResults args)
      : this(
            sourceMap: args['source-map'] as bool,
            inlineSourceMap: args['inline-source-map'] as bool,
            summarizeApi: args['summarize'] as bool,
            enableAsserts: args['enable-asserts'] as bool,
            replCompile: args['repl-compile'] as bool,
            emitDebugMetadata: args['experimental-emit-debug-metadata'] as bool,
            emitFullCompiledKernel:
                args['experimental-output-compiled-kernel'] as bool,
            summaryModules:
                _parseCustomSummaryModules(args['summary'] as List<String>),
            moduleFormats: parseModuleFormatOption(args),
            moduleName: _getModuleName(args),
            multiRootScheme: args['multi-root-scheme'] as String,
            multiRootOutputPath: args['multi-root-output-path'] as String,
            experiments: parseExperimentalArguments(
                args['enable-experiment'] as List<String>),
            soundNullSafety: args['sound-null-safety'] as bool);

  SharedCompilerOptions.fromSdkRequiredArguments(ArgResults args)
      : this(
            summarizeApi: false,
            moduleFormats: parseModuleFormatOption(args),
            // When compiling the SDK use dart_sdk as the default. This is the
            // assumed name in various places around the build systems.
            moduleName:
                args['module-name'] != null ? _getModuleName(args) : 'dart_sdk',
            multiRootScheme: args['multi-root-scheme'] as String,
            multiRootOutputPath: args['multi-root-output-path'] as String,
            experiments: parseExperimentalArguments(
                args['enable-experiment'] as List<String>),
            soundNullSafety: args['sound-null-safety'] as bool);

  static void addArguments(ArgParser parser, {bool hide = true}) {
    addSdkRequiredArguments(parser, hide: hide);

    parser
      ..addMultiOption('summary',
          abbr: 's',
          help: 'API summary file(s) of imported libraries, optionally\n'
              'with module import path: -s path.dill=js/import/path')
      ..addFlag('summarize',
          help: 'Emit an API summary file.', defaultsTo: true, hide: hide)
      ..addFlag('source-map',
          help: 'Emit source mapping.', defaultsTo: true, hide: hide)
      ..addFlag('inline-source-map',
          help: 'Emit source mapping inline.', defaultsTo: false, hide: hide)
      ..addFlag('enable-asserts',
          help: 'Enable assertions.', defaultsTo: true, hide: hide)
      ..addFlag('repl-compile',
          help: 'Compile in a more permissive REPL mode, allowing access'
              ' to private members across library boundaries. This should'
              ' only be used by debugging tools.',
          defaultsTo: false,
          hide: hide)
      // TODO(41852) Define a process for breaking changes before graduating from
      // experimental.
      ..addFlag('experimental-emit-debug-metadata',
          help: 'Experimental option for compiler development.\n'
              'Output a metadata file for debug tools next to the .js output.',
          defaultsTo: false,
          hide: true)
      ..addFlag('experimental-output-compiled-kernel',
          help: 'Experimental option for compiler development.\n'
              'Output a full kernel file for currently compiled module next to '
              'the .js output.',
          defaultsTo: false,
          hide: true);
  }

  /// Adds only the arguments used to compile the SDK from a full dill file.
  ///
  /// NOTE: The 'module-name' option will have a special default value of
  /// 'dart_sdk' when compiling the SDK.
  /// See [SharedCompilerOptions.fromSdkRequiredArguments].
  static void addSdkRequiredArguments(ArgParser parser, {bool hide = true}) {
    addModuleFormatOptions(parser, hide: hide);
    parser
      ..addMultiOption('out', abbr: 'o', help: 'Output file (required).')
      ..addOption('module-name',
          help: 'The output module name, used in some JS module formats.\n'
              'Defaults to the output file name (without .js).')
      ..addOption('multi-root-scheme',
          help: 'The custom scheme to indicate a multi-root uri.',
          defaultsTo: 'org-dartlang-app')
      ..addOption('multi-root-output-path',
          help: 'Path to set multi-root files relative to when generating'
              ' source-maps.',
          hide: true)
      ..addMultiOption('enable-experiment',
          help: 'Enable/disable experimental language features.', hide: hide)
      ..addFlag('sound-null-safety',
          help: 'Compile for sound null safety at runtime.',
          negatable: true,
          defaultsTo: false);
  }

  static String _getModuleName(ArgResults args) {
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

      moduleName = p.basenameWithoutExtension(outPath);
    }
    // TODO(jmesserly): this should probably use sourcePathToUri.
    //
    // Also we should not need this logic if the user passed in the module name
    // explicitly. It is here for backwards compatibility until we can confirm
    // that build systems do not depend on passing windows-style paths here.
    return p.toUri(moduleName).toString();
  }

  // TODO(nshahan) Cleanup when NNBD graduates experimental status.
  bool get enableNullSafety => experiments['non-nullable'] ?? false;
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
    var equalSign = summaryPath.indexOf('=');
    String modulePath;
    var summaryPathWithoutExt = summaryExt != null
        ? summaryPath.substring(
            0,
            // Strip off the extension, including the last `.`.
            summaryPath.length - (summaryExt.length + 1))
        : p.withoutExtension(summaryPath);
    if (equalSign != -1) {
      modulePath = summaryPath.substring(equalSign + 1);
      summaryPath = summaryPath.substring(0, equalSign);
    } else if (moduleRoot != null && p.isWithin(moduleRoot, summaryPath)) {
      // TODO(jmesserly): remove this, it's legacy --module-root support.
      modulePath = p.url.joinAll(
          p.split(p.relative(summaryPathWithoutExt, from: moduleRoot)));
    } else {
      modulePath = p.basename(summaryPathWithoutExt);
    }
    pathToModule[summaryPath] = modulePath;
  }
  return pathToModule;
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
    var equalsOffset = arg.lastIndexOf('=');
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
    source = source.replaceAll('\\', '/');
  }

  var result = Uri.base.resolve(source);
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
      return p.toUri(uriPath.substring(root.length));
    }
  }
  return uri;
}

/// Adjusts the source uris in [sourceMap] to be relative uris, and returns
/// the new map.
///
/// Source uris show up in two forms, absolute `file:` uris and custom
/// [multiRootScheme] uris (also "absolute" uris, but always relative to some
/// multi-root).
///
/// - `file:` uris are converted to be relative to [sourceMapBase], which
///   defaults to the dirname of [sourceMapPath] if not provided.
///
/// - [multiRootScheme] uris are prefixed by [multiRootOutputPath]. If the
///   path starts with `/lib`, then we strip that before making it relative
///   to the [multiRootOutputPath], and assert that [multiRootOutputPath]
///   starts with `/packages` (more explanation inline).
///
// TODO(#40251): Remove this logic from dev_compiler itself, push it to the
// invokers of dev_compiler which have more knowledge about how they want
// source paths to look.
Map placeSourceMap(Map sourceMap, String sourceMapPath, String multiRootScheme,
    {String multiRootOutputPath, String sourceMapBase}) {
  var map = Map.from(sourceMap);
  // Convert to a local file path if it's not.
  sourceMapPath = sourcePathToUri(p.absolute(p.fromUri(sourceMapPath))).path;
  var sourceMapDir = p.url.dirname(sourceMapPath);
  sourceMapBase ??= sourceMapDir;
  var list = (map['sources'] as List).toList();

  String makeRelative(String sourcePath) {
    var uri = sourcePathToUri(sourcePath);
    var scheme = uri.scheme;
    if (scheme == 'dart' || scheme == 'package' || scheme == multiRootScheme) {
      if (scheme == multiRootScheme) {
        // TODO(sigmund): extract all source-map normalization outside ddc. This
        // custom logic is BUILD specific and could be shared with other tools
        // like dart2js.
        var shortPath = uri.path.replaceAll('/sdk/', '/dart-sdk/');
        var multiRootPath = "${multiRootOutputPath ?? ''}$shortPath";
        multiRootPath = p.url.relative(multiRootPath, from: sourceMapDir);
        return multiRootPath;
      }
      return sourcePath;
    }

    if (uri.scheme == 'http') return sourcePath;

    // Convert to a local file path if it's not.
    sourcePath = sourcePathToUri(p.absolute(p.fromUri(uri))).path;

    // Fall back to a relative path against the source map itself.
    sourcePath = p.url.relative(sourcePath, from: sourceMapBase);

    // Convert from relative local path to relative URI.
    return p.toUri(sourcePath).path;
  }

  for (var i = 0; i < list.length; i++) {
    list[i] = makeRelative(list[i] as String);
  }
  map['sources'] = list;
  map['file'] =
      map['file'] != null ? makeRelative(map['file'] as String) : null;
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

  return kernel_compiler.compile(args.rest,
      compilerState: previousResult?.kernelState,
      isWorker: args.isWorker,
      useIncrementalCompiler: args.useIncrementalCompiler,
      inputDigests: inputDigests);
}

/// The result of a single `dartdevc` compilation.
///
/// Typically used for exiting the process with [exitCode] or checking the
/// [success] of the compilation.
///
/// For batch/worker compilations, the [compilerState] provides an opportunity
/// to reuse state from the previous run, if the options/input summaries are
/// equivalent. Otherwise it will be discarded.
class CompilerResult {
  /// Optionally provides the front_end state from the previous compilation,
  /// which can be passed to [compile] to potentially speed up the next
  /// compilation.
  final InitializedCompilerState kernelState;

  /// The process exit code of the compiler.
  final int exitCode;

  CompilerResult(this.exitCode, {this.kernelState});

  /// Gets the kernel compiler state, if any.
  Object get compilerState => kernelState;

  /// Whether the program compiled without any fatal errors (equivalent to
  /// [exitCode] == 0).
  bool get success => exitCode == 0;

  /// Whether the compiler crashed (i.e. threw an unhandled exception,
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
class ParsedArguments {
  /// The user's arguments to the compiler for this compialtion.
  final List<String> rest;

  /// Whether to run in `--batch` mode, e.g the Dart SDK and Language tests.
  ///
  /// Similar to [isWorker] but with a different protocol.
  /// See also [isBatchOrWorker].
  final bool isBatch;

  /// Whether to run in `--experimental-expression-compiler` mode.
  ///
  /// This is a special mode that is optimized for only compiling expressions.
  ///
  /// All dependencies must come from precompiled dill files, and those must
  /// be explicitly invalidated as needed between expression compile requests.
  /// Invalidation of dill is performed using [updateDeps] from the client (i.e.
  /// debugger) and should be done every time a dill file changes, for example,
  /// on hot reload or rebuild.
  final bool isExpressionCompiler;

  /// Whether to run in `--bazel_worker` mode, e.g. for Bazel builds.
  ///
  /// Similar to [isBatch] but with a different protocol.
  /// See also [isBatchOrWorker].
  final bool isWorker;

  /// Whether to re-use the last compiler result when in a worker.
  ///
  /// This is useful if we are repeatedly compiling things in the same context,
  /// e.g. in a debugger REPL.
  final bool reuseResult;

  /// Whether to use the incremental compiler for compiling.
  ///
  /// Note that this only makes sense when also reusing results.
  final bool useIncrementalCompiler;

  ParsedArguments._(
    this.rest, {
    this.isBatch = false,
    this.isWorker = false,
    this.reuseResult = false,
    this.useIncrementalCompiler = false,
    this.isExpressionCompiler = false,
  });

  /// Preprocess arguments to determine whether DDK is used in batch mode or as a
  /// persistent worker.
  ///
  /// When used in batch mode, we expect a `--batch` parameter.
  ///
  /// When used as a persistent bazel worker, the `--persistent_worker` might be
  /// present, and an argument of the form `@path/to/file` might be provided. The
  /// latter needs to be replaced by reading all the contents of the
  /// file and expanding them into the resulting argument list.
  factory ParsedArguments.from(List<String> args) {
    if (args.isEmpty) return ParsedArguments._(args);

    var newArgs = <String>[];
    var isWorker = false;
    var isBatch = false;
    var reuseResult = false;
    var useIncrementalCompiler = false;
    var isExpressionCompiler = false;

    Iterable<String> argsToParse = args;

    // Expand `@path/to/file`
    if (args.last.startsWith('@')) {
      var extra = _readLines(args.last.substring(1));
      argsToParse = args.take(args.length - 1).followedBy(extra);
    }

    for (var arg in argsToParse) {
      if (arg == '--persistent_worker') {
        isWorker = true;
      } else if (arg == '--batch') {
        isBatch = true;
      } else if (arg == '--reuse-compiler-result') {
        reuseResult = true;
      } else if (arg == '--use-incremental-compiler') {
        useIncrementalCompiler = true;
      } else if (arg == '--experimental-expression-compiler') {
        isExpressionCompiler = true;
      } else {
        newArgs.add(arg);
      }
    }
    return ParsedArguments._(newArgs,
        isWorker: isWorker,
        isBatch: isBatch,
        reuseResult: reuseResult,
        useIncrementalCompiler: useIncrementalCompiler,
        isExpressionCompiler: isExpressionCompiler);
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
