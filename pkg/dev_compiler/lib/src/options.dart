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

  /// List of additional non-Dart resources to resolve and serve.
  final List<String> resources;

  // True if the resolver should implicitly provide an html entry point.
  final bool useImplicitHtml;
  static const String implicitHtmlFile = 'index.html';

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
      this.packagePaths: const <String>[],
      this.resources: const <String>[],
      this.useImplicitHtml: false});
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

  /// Whether to dump summary information on the console.
  final bool dumpInfo;

  final bool htmlReport;

  /// If not null, path to a file that will store a json representation of the
  /// summary information (only used if [dumpInfo] is true).
  final String dumpInfoFile;

  /// Whether to use colors when interacting on the console.
  final bool useColors;

  /// Whether the user asked for help.
  final bool help;

  /// Whether the user asked for the app version.
  final bool version;

  /// Minimum log-level reported on the command-line.
  final Level logLevel;

  /// Whether to run as a development server.
  final bool serverMode;

  /// Whether to enable hash-based caching of files.
  final bool enableHashing;

  /// Whether to serve the error / warning widget.
  final bool widget;

  /// Port used for the HTTP server when [serverMode] is on.
  final int port;

  /// Host name or address for HTTP server when [serverMode] is on.
  final String host;

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
      this.dumpInfo: false,
      this.htmlReport: false,
      this.dumpInfoFile,
      this.useColors: true,
      this.help: false,
      this.version: false,
      this.logLevel: Level.WARNING,
      this.serverMode: false,
      this.enableHashing: false,
      this.widget: true,
      this.host: 'localhost',
      this.port: 8080,
      this.runtimeDir,
      this.inputs,
      this.inputBaseDir});
}

/// Parses options from the command-line
CompilerOptions parseOptions(List<String> argv, {bool forceOutDir: false}) {
  ArgResults args = argParser.parse(argv);
  bool showUsage = args['help'];
  bool showVersion = args['version'];

  var serverMode = args['server'];
  var enableHashing = args['hashing'];
  if (enableHashing == null) {
    enableHashing = serverMode;
  }
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
  if (outputDir == null && (serverMode || forceOutDir)) {
    outputDir = Directory.systemTemp.createTempSync("dev_compiler_out_").path;
  }
  var dumpInfo = args['dump-info'];
  if (dumpInfo == null) dumpInfo = serverMode;

  var htmlReport = args['html-report'];

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
          forceCompile: args['force-compile'] || serverMode,
          closure: args['closure'],
          destructureNamedParams: args['destructure-named-params'],
          outputDir: outputDir,
          moduleFormat: parseModuleFormat(args['modules'])),
      sourceOptions: new SourceResolverOptions(
          useMockSdk: args['mock-sdk'],
          dartSdkPath: sdkPath,
          useImplicitHtml: serverMode &&
              args.rest.length == 1 &&
              args.rest[0].endsWith('.dart'),
          customUrlMappings: customUrlMappings,
          useMultiPackage: args['use-multi-package'],
          packageRoot: args['package-root'],
          packagePaths: args['package-paths'].split(','),
          resources:
              args['resources'].split(',').where((s) => s.isNotEmpty).toList()),
      runnerOptions: new RunnerOptions(v8Binary: v8Binary),
      checkSdk: args['sdk-check'],
      dumpInfo: dumpInfo,
      htmlReport: htmlReport,
      dumpInfoFile: args['dump-info-file'],
      useColors: useColors,
      help: showUsage,
      version: showVersion,
      logLevel: logLevel,
      serverMode: serverMode,
      enableHashing: enableHashing,
      widget: args['widget'],
      host: args['host'],
      port: int.parse(args['port']),
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
  ..addOption('dump-src-to', help: 'Dump dart src code', defaultsTo: null)
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
  ..addOption('resources',
      help: 'Additional resources to serve', defaultsTo: '')
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
  ..addFlag('server', help: 'Run as a development server.', defaultsTo: false)
  ..addFlag('hashing',
      help: 'Enable hash-based file caching.', defaultsTo: null)
  ..addFlag('widget',
      help: 'Serve embedded widget with static errors and warnings.',
      defaultsTo: true)
  ..addOption('host',
      help: 'Host name or address to serve files from, e.g. --host=0.0.0.0\n'
          'to listen on all interfaces (used only when --serve is on)',
      defaultsTo: 'localhost')
  ..addOption('port',
      help: 'Port to serve files from (used only when --serve is on)',
      defaultsTo: '8080')
  ..addFlag('closure',
      help: 'Emit Closure Compiler-friendly code (experimental)',
      defaultsTo: _CLOSURE_DEFAULT)
  ..addFlag('destructure-named-params',
      help: 'Destructure named parameters (requires ES6-enabled runtime)',
      defaultsTo: _DESTRUCTURE_NAMED_PARAMS_DEFAULT)
  ..addFlag('force-compile',
      abbr: 'f', help: 'Compile code with static errors', defaultsTo: false)
  ..addOption('log', abbr: 'l', help: 'Logging level (defaults to warning)')
  ..addFlag('dump-info',
      abbr: 'i', help: 'Dump summary information', defaultsTo: null)
  ..addFlag('html-report',
      help: 'Output compilation results to html', defaultsTo: false)
  ..addOption('v8-binary',
      help: 'V8-based binary to run JavaScript output with (iojs, node, d8)',
      defaultsTo: _V8_BINARY_DEFAULT)
  ..addOption('dump-info-file',
      help: 'Dump info json file (requires dump-info)', defaultsTo: null);

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
