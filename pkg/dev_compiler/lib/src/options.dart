// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Set of flags and options passed to the compiler
library dev_compiler.src.options;

import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:logging/logging.dart' show Level;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'package:dev_compiler/strong_mode.dart' show StrongModeOptions;

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

  /// File where to start compilation from.
  // TODO(jmesserly): this is used to configure SourceFactory resolvers only
  // when [useImplicitHtml] is set. Probably useImplicitHtml should be factored
  // out into ServerOptions or something along those lines.
  final String entryPointFile;

  // True if the resolver should implicitly provide an html entry point.
  final bool useImplicitHtml;
  static const String implicitHtmlFile = 'index.html';

  /// Whether to use a mock-sdk during compilation.
  final bool useMockSdk;

  /// Path to the dart-sdk. Null if `useMockSdk` is true or if the path couldn't
  /// be determined
  final String dartSdkPath;

  const SourceResolverOptions({this.useMockSdk: false, this.dartSdkPath,
      this.useMultiPackage: false, this.customUrlMappings: const {},
      this.packageRoot: 'packages/', this.packagePaths: const <String>[],
      this.resources: const <String>[], this.entryPointFile: null,
      this.useImplicitHtml: false});
}

// TODO(jmesserly): refactor all codegen options here.
class CodegenOptions {
  /// Whether to emit the source map files.
  final bool emitSourceMaps;

  /// Whether to force compilation of code with static errors.
  final bool forceCompile;

  /// Output directory for generated code.
  final String outputDir;

  const CodegenOptions(
      {this.emitSourceMaps: true, this.forceCompile: false, this.outputDir});
}

/// General options used by the dev compiler and server.
class CompilerOptions {
  final StrongModeOptions strongOptions;
  final SourceResolverOptions sourceOptions;
  final CodegenOptions codegenOptions;

  /// Whether to check the sdk libraries.
  final bool checkSdk;

  /// Whether to dump summary information on the console.
  final bool dumpInfo;

  /// If not null, path to a file that will store a json representation of the
  /// summary information (only used if [dumpInfo] is true).
  final String dumpInfoFile;

  /// Whether to use colors when interacting on the console.
  final bool useColors;

  /// Whether the user asked for help.
  final bool help;

  /// Minimum log-level reported on the command-line.
  final Level logLevel;

  /// Whether to run as a development server.
  final bool serverMode;

  /// Whether to enable hash-based caching of files.
  final bool enableHashing;

  /// Port used for the HTTP server when [serverMode] is on.
  final int port;

  /// Host name or address for HTTP server when [serverMode] is on.
  final String host;

  /// Location for runtime files, such as `dart_runtime.js`. By default this is
  /// inferred to be under `lib/runtime/` in the location of the `dev_compiler`
  /// package (if we can infer where that is located).
  final String runtimeDir;

  CompilerOptions({this.strongOptions: const StrongModeOptions(),
      this.sourceOptions: const SourceResolverOptions(),
      this.codegenOptions: const CodegenOptions(), this.checkSdk: false,
      this.dumpInfo: false, this.dumpInfoFile, this.useColors: true,
      this.help: false, this.logLevel: Level.SEVERE, this.serverMode: false,
      this.enableHashing: false, this.host: 'localhost', this.port: 8080,
      this.runtimeDir});
}

/// Parses options from the command-line
CompilerOptions parseOptions(List<String> argv) {
  ArgResults args = argParser.parse(argv);
  bool showUsage = args['help'];

  var serverMode = args['server'];
  var enableHashing = args['hashing'];
  if (enableHashing == null) {
    enableHashing = serverMode;
  }
  // TODO(jmesserly): shouldn't level always default to warning?
  var logLevel = serverMode ? Level.WARNING : Level.SEVERE;
  var levelName = args['log'];
  if (levelName != null) {
    levelName = levelName.toUpperCase();
    logLevel = Level.LEVELS.firstWhere((l) => l.name == levelName,
        orElse: () => logLevel);
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
  if (outputDir == null && serverMode) {
    outputDir = Directory.systemTemp.createTempSync("dev_compiler_out_").path;
  }
  var dumpInfo = args['dump-info'];
  if (dumpInfo == null) dumpInfo = serverMode;

  var customUrlMappings = <String, String>{};
  for (var mapping in args['url-mapping']) {
    var splitMapping = mapping.split(',');
    if (splitMapping.length != 2) {
      showUsage = true;
      continue;
    }
    customUrlMappings[splitMapping[0]] = splitMapping[1];
  }

  var entryPointFile = args.rest.length == 0 ? null : args.rest.first;

  return new CompilerOptions(
      codegenOptions: new CodegenOptions(
          emitSourceMaps: args['source-maps'],
          forceCompile: args['force-compile'] || serverMode,
          outputDir: outputDir),
      sourceOptions: new SourceResolverOptions(
          useMockSdk: args['mock-sdk'],
          dartSdkPath: sdkPath,
          entryPointFile: entryPointFile,
          useImplicitHtml: serverMode && entryPointFile.endsWith('.dart'),
          customUrlMappings: customUrlMappings,
          useMultiPackage: args['use-multi-package'],
          packageRoot: args['package-root'],
          packagePaths: args['package-paths'].split(','),
          resources: args['resources']
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList()),
      strongOptions: new StrongModeOptions.fromArguments(args),
      checkSdk: args['sdk-check'],
      dumpInfo: dumpInfo,
      dumpInfoFile: args['dump-info-file'],
      useColors: useColors,
      help: showUsage,
      logLevel: logLevel,
      serverMode: serverMode,
      enableHashing: enableHashing,
      host: args['host'],
      port: int.parse(args['port']),
      runtimeDir: runtimeDir);
}

final ArgParser argParser = StrongModeOptions.addArguments(new ArgParser()
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
      'look for packages in.', defaultsTo: '')
  ..addOption('resources',
      help: 'Additional resources to serve', defaultsTo: '')
  ..addFlag('source-maps',
      help: 'Whether to emit source map files', defaultsTo: true)
  ..addOption('runtime-dir',
      help: 'Where to find dev_compiler\'s runtime files', defaultsTo: null)

  // general options
  ..addFlag('help', abbr: 'h', help: 'Display this message')
  ..addFlag('server', help: 'Run as a development server.', defaultsTo: false)
  ..addFlag('hashing',
      help: 'Enable hash-based file caching.', defaultsTo: null)
  ..addOption('host',
      help: 'Host name or address to serve files from, e.g. --host=0.0.0.0\n'
      'to listen on all interfaces (used only when --serve is on)',
      defaultsTo: 'localhost')
  ..addOption('port',
      help: 'Port to serve files from (used only when --serve is on)',
      defaultsTo: '8080')
  ..addFlag('force-compile',
      help: 'Compile code with static errors', defaultsTo: false)
  ..addOption('log', abbr: 'l', help: 'Logging level (defaults to severe)')
  ..addFlag('dump-info',
      abbr: 'i', help: 'Dump summary information', defaultsTo: null)
  ..addOption('dump-info-file',
      abbr: 'f',
      help: 'Dump info json file (requires dump-info)',
      defaultsTo: null));

/// Tries to find the `lib/runtime/` directory of the dev_compiler package. This
/// works when running devc from it's sources or from a snapshot that is
/// activated via `pub global activate`.
String _computeRuntimeDir() {
  var scriptUri = Platform.script;
  var scriptPath = scriptUri.path;
  var file = path.basename(scriptPath);
  var dir = path.dirname(scriptPath);
  var lastdir = path.basename(dir);
  dir = path.dirname(dir);

  // Both the source devc.dart and the snapshot generated by pub global activate
  // are under a bin folder.
  if (lastdir != 'bin') return null;

  // And both under a project directory containing a pubspec.lock file.
  var lockfile = path.join(dir, 'pubspec.lock');
  if (!new File(lockfile).existsSync()) return null;

  // If running from sources we found it!
  if (file == 'devc.dart') return path.join(dir, 'lib', 'runtime');

  // If running from a pub global snapshot, we need to read the lock file to
  // find where the actual sources are located in the pub cache.
  if (file == 'devc.dart.snapshot') {
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
