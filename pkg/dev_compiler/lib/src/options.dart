// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Set of flags and options passed to the compiler

import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:logging/logging.dart' show Level;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'utils.dart' show parseEnum, getEnumName;

const String _V8_BINARY_DEFAULT = 'node';
const bool _CLOSURE_DEFAULT = false;

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
///
// TODO(ochafik): Simplify this code when our target platforms catch up.
const bool _DESTRUCTURE_NAMED_PARAMS_DEFAULT = false;

/// Options used to set up Source URI resolution in the analysis context.
class SourceResolverOptions {
  /// Whether to resolve 'package:' uris using the multi-package resolver.
  final bool useMultiPackage;

  /// Custom URI mappings, such as "dart:foo" -> "path/to/foo.dart"
  final Map<String, String> customUrlMappings;

  /// Package root when resolving 'package:' urls the standard way.
  final String packageRoot;

  /// List of paths used for the multi-package resolver.
  final List<String> packagePaths;

  /// Whether to use a mock-sdk during compilation.
  final bool useMockSdk;

  /// Path to the dart-sdk. Null if `useMockSdk` is true or if the path couldn't
  /// be determined
  final String dartSdkPath;

  const SourceResolverOptions(
      {this.useMockSdk: false,
      this.dartSdkPath,
      this.useMultiPackage: false,
      this.customUrlMappings: const {},
      this.packageRoot: 'packages/',
      this.packagePaths: const <String>[]});
}

enum ModuleFormat { es6, legacy, node }
ModuleFormat parseModuleFormat(String s) => parseEnum(s, ModuleFormat.values);

// TODO(jmesserly): refactor all codegen options here.
class CodegenOptions {
  /// Whether to emit the source map files.
  final bool emitSourceMaps;

  /// Whether to force compilation of code with static errors.
  final bool forceCompile;

  /// Output directory for generated code.
  final String outputDir;

  /// Emit Closure Compiler-friendly code.
  final bool closure;

  /// Enable ES6 destructuring of named parameters.
  final bool destructureNamedParams;

  /// Which module format to support.
  /// Currently 'es6' and 'legacy' are supported.
  final ModuleFormat moduleFormat;

  const CodegenOptions(
      {this.emitSourceMaps: true,
      this.forceCompile: false,
      this.closure: _CLOSURE_DEFAULT,
      this.destructureNamedParams: _DESTRUCTURE_NAMED_PARAMS_DEFAULT,
      this.outputDir,
      this.moduleFormat: ModuleFormat.legacy});
}

/// Options for devrun.
class RunnerOptions {
  /// V8-based binary to be used to run the .js output (d8, iojs, node).
  /// Can be just the executable name if it's in the path, or a path to the
  /// executable.
  final String v8Binary;

  const RunnerOptions({this.v8Binary: _V8_BINARY_DEFAULT});
}

/// General options used by the dev compiler and server.
class CompilerOptions {
  final SourceResolverOptions sourceOptions;
  final CodegenOptions codegenOptions;
  final RunnerOptions runnerOptions;

  /// Whether to check the sdk libraries.
  final bool checkSdk;

  /// Whether to use colors when interacting on the console.
  final bool useColors;

  /// Whether the user asked for help.
  final bool help;

  /// Whether the user asked for the app version.
  final bool version;

  /// Minimum log-level reported on the command-line.
  final Level logLevel;

  /// Location for runtime files, such as `dart_runtime.js`. By default this is
  /// inferred to be under `lib/runtime/` in the location of the `dev_compiler`
  /// package (if we can infer where that is located).
  final String runtimeDir;

  /// The files to compile.
  final List<String> inputs;

  /// The base directory for [inputs]. Module imports will be generated relative
  /// to this directory.
  final String inputBaseDir;

  const CompilerOptions(
      {this.sourceOptions: const SourceResolverOptions(),
      this.codegenOptions: const CodegenOptions(),
      this.runnerOptions: const RunnerOptions(),
      this.checkSdk: false,
      this.useColors: true,
      this.help: false,
      this.version: false,
      this.logLevel: Level.WARNING,
      this.runtimeDir,
      this.inputs,
      this.inputBaseDir});
}

/// Parses options from the command-line
CompilerOptions parseOptions(List<String> argv, {bool forceOutDir: false}) {
  ArgResults args = argParser.parse(argv);
  bool showUsage = args['help'];
  bool showVersion = args['version'];

  var logLevel = Level.WARNING;
  var levelName = args['log'];
  if (levelName != null) {
    levelName = levelName.toUpperCase();
    logLevel = Level.LEVELS
        .firstWhere((l) => l.name == levelName, orElse: () => logLevel);
  }
  var useColors = stdioType(stdout) == StdioType.TERMINAL;
  var sdkPath = args['dart-sdk'];
  if (sdkPath == null && !args['mock-sdk']) {
    sdkPath = getSdkDir(argv).path;
  }
  var runtimeDir = args['runtime-dir'];
  if (runtimeDir == null) {
    runtimeDir = _computeRuntimeDir();
  }
  var outputDir = args['out'];
  if (outputDir == null && forceOutDir) {
    outputDir = Directory.systemTemp.createTempSync("dev_compiler_out_").path;
  }

  var v8Binary = args['v8-binary'];
  if (v8Binary == null) v8Binary = _V8_BINARY_DEFAULT;

  var customUrlMappings = <String, String>{};
  for (var mapping in args['url-mapping']) {
    var splitMapping = mapping.split(',');
    if (splitMapping.length != 2) {
      showUsage = true;
      continue;
    }
    customUrlMappings[splitMapping[0]] = splitMapping[1];
  }

  return new CompilerOptions(
      codegenOptions: new CodegenOptions(
          emitSourceMaps: args['source-maps'],
          forceCompile: args['force-compile'],
          closure: args['closure'],
          destructureNamedParams: args['destructure-named-params'],
          outputDir: outputDir,
          moduleFormat: parseModuleFormat(args['modules'])),
      sourceOptions: new SourceResolverOptions(
          useMockSdk: args['mock-sdk'],
          dartSdkPath: sdkPath,
          customUrlMappings: customUrlMappings,
          useMultiPackage: args['use-multi-package'],
          packageRoot: args['package-root'],
          packagePaths: args['package-paths'].split(',')),
      runnerOptions: new RunnerOptions(v8Binary: v8Binary),
      checkSdk: args['sdk-check'],
      useColors: useColors,
      help: showUsage,
      version: showVersion,
      logLevel: logLevel,
      runtimeDir: runtimeDir,
      inputs: args.rest);
}

final ArgParser argParser = new ArgParser()
  ..addFlag('sdk-check',
      abbr: 's', help: 'Typecheck sdk libs', defaultsTo: false)
  ..addFlag('mock-sdk',
      abbr: 'm', help: 'Use a mock Dart SDK', defaultsTo: false)

  // input/output options
  ..addOption('out', abbr: 'o', help: 'Output directory', defaultsTo: null)
  ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null)
  ..addOption('package-root',
      abbr: 'p',
      help: 'Package root to resolve "package:" imports',
      defaultsTo: 'packages/')
  ..addOption('url-mapping',
      help: '--url-mapping=libraryUri,/path/to/library.dart uses library.dart\n'
          'as the source for an import of of "libraryUri".',
      allowMultiple: true,
      splitCommas: false)
  ..addFlag('use-multi-package',
      help: 'Whether to use the multi-package resolver for "package:" imports',
      defaultsTo: false)
  ..addOption('package-paths',
      help: 'if using the multi-package resolver, the list of directories to\n'
          'look for packages in.',
      defaultsTo: '')
  ..addFlag('source-maps',
      help: 'Whether to emit source map files', defaultsTo: true)
  ..addOption('runtime-dir',
      help: 'Where to find dev_compiler\'s runtime files', defaultsTo: null)
  ..addOption('modules',
      help: 'Which module pattern to emit',
      allowed: ModuleFormat.values.map(getEnumName).toList(),
      allowedHelp: {
        getEnumName(ModuleFormat.es6): 'es6 modules',
        getEnumName(ModuleFormat.legacy):
            'a custom format used by dartdevc, similar to AMD',
        getEnumName(ModuleFormat.node):
            'node.js modules (https://nodejs.org/api/modules.html)'
      },
      defaultsTo: getEnumName(ModuleFormat.legacy))

  // general options
  ..addFlag('help', abbr: 'h', help: 'Display this message')
  ..addFlag('version',
      negatable: false, help: 'Display the Dev Compiler verion')
  ..addFlag('closure',
      help: 'Emit Closure Compiler-friendly code (experimental)',
      defaultsTo: _CLOSURE_DEFAULT)
  ..addFlag('destructure-named-params',
      help: 'Destructure named parameters (requires ES6-enabled runtime)',
      defaultsTo: _DESTRUCTURE_NAMED_PARAMS_DEFAULT)
  ..addFlag('force-compile',
      abbr: 'f', help: 'Compile code with static errors', defaultsTo: false)
  ..addOption('log', abbr: 'l', help: 'Logging level (defaults to warning)')
  ..addOption('v8-binary',
      help: 'V8-based binary to run JavaScript output with (iojs, node, d8)',
      defaultsTo: _V8_BINARY_DEFAULT);

// TODO: Switch over to the `pub_cache` package (or the Resource API)?

const _ENTRY_POINTS = const [
  'dartdevc.dart',
  'dev_compiler.dart',
  'devrun.dart'
];

final _ENTRY_POINT_SNAPSHOTS = _ENTRY_POINTS.map((f) => "$f.snapshot");

/// Tries to find the `lib/runtime/` directory of the dev_compiler package. This
/// works when running devc from it's sources or from a snapshot that is
/// activated via `pub global activate`.
String _computeRuntimeDir() {
  var scriptPath = path.fromUri(Platform.script);
  var file = path.basename(scriptPath);
  var dir = path.dirname(scriptPath);
  var lastdir = path.basename(dir);
  dir = path.dirname(dir);

  // Both the source dartdevc.dart and the snapshot generated by pub global activate
  // are under a bin folder.
  if (lastdir != 'bin') return null;

  // And both under a project directory containing a pubspec.lock file.
  var lockfile = path.join(dir, 'pubspec.lock');
  if (!new File(lockfile).existsSync()) return null;

  // If running from sources we found it!
  if (_ENTRY_POINTS.contains(file)) {
    return path.join(dir, 'lib', 'runtime');
  }

  // If running from a pub global snapshot, we need to read the lock file to
  // find where the actual sources are located in the pub cache.
  if (_ENTRY_POINT_SNAPSHOTS.contains(file)) {
    // Note: this depends on implementation details of pub.
    var yaml = loadYaml(new File(lockfile).readAsStringSync());
    var info = yaml['packages']['dev_compiler'];
    if (info == null) return null;

    var cacheDir;
    if (info['source'] == 'hosted') {
      cacheDir = path.join(
          'hosted', 'pub.dartlang.org', 'dev_compiler-${info["version"]}');
    } else if (info['source'] == 'git') {
      var ref = info['description']['resolved-ref'];
      cacheDir = path.join('git', 'dev_compiler-${ref}');
    }

    // We should be under "/path/to/pub-cache/global_packages/dev_compiler".
    // The pub-cache directory is two levels up, but we verify that the layout
    // looks correct.
    if (path.basename(dir) != 'dev_compiler') return null;
    dir = path.dirname(dir);
    if (path.basename(dir) != 'global_packages') return null;
    dir = path.dirname(dir);
    return path.join(dir, cacheDir, 'lib', 'runtime');
  }
  return null;
}
