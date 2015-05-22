// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Set of flags and options passed to the compiler
library dev_compiler.src.options;

import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:dev_compiler/config.dart';
import 'package:logging/logging.dart' show Level;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Options used by our checker.
// TODO(jmesserly): move useMultiPackage/packageRoot to CompilerOptions.
class ResolverOptions {
  /// Whether to resolve 'package:' uris using the multi-package resolver.
  final bool useMultiPackage;

  /// Package root when resolving 'package:' urls the standard way.
  final String packageRoot;

  /// List of paths used for the multi-package resolver.
  final List<String> packagePaths;

  /// List of additional non-Dart resources to resolve and serve.
  final List<String> resources;

  /// Whether to infer return types and field types from overriden members.
  final bool inferFromOverrides;
  static const inferFromOverridesDefault = true;

  /// Whether to infer types for consts and fields by looking at initializers on
  /// the RHS. For example, in a constant declaration like:
  ///
  ///      const A = B;
  ///
  /// We can infer the type of `A` based on the type of `B`.
  ///
  /// The inference algorithm determines what variables depend on others, and
  /// computes types by visiting the variable dependency graph in topological
  /// order. This ensures that the inferred type is deterministic when applying
  /// inference on library cycles.
  ///
  /// When this feature is turned off, we don't use the type of `B` to infer the
  /// type of `A`, even if `B` has a declared type.
  final bool inferTransitively;
  static const inferTransitivelyDefault = true;

  /// Restrict inference of fields and top-levels to those that are final and
  /// const.
  final bool onlyInferConstsAndFinalFields;
  static const onlyInferConstAndFinalFieldsDefault = false;

  /// File where to start compilation from.
  final String entryPointFile;

  // True if the resolver should implicitly provide an html entry point.
  final bool useImplicitHtml;
  static const String implicitHtmlFile = 'index.html';

  ResolverOptions({this.useMultiPackage: false, this.packageRoot: 'packages/',
      this.packagePaths: const <String>[], this.resources: const <String>[],
      this.inferFromOverrides: inferFromOverridesDefault,
      this.inferTransitively: inferTransitivelyDefault,
      this.onlyInferConstsAndFinalFields: onlyInferConstAndFinalFieldsDefault,
      this.entryPointFile: null, this.useImplicitHtml: false});
}

// TODO(vsm): Merge RulesOptions and TypeOptions
/// Options used by our RestrictedRules.
class RulesOptions extends TypeOptions {
  /// Whether to allow casts in constant contexts.
  final bool allowConstCasts;

  /// Whether to use covariant generics
  final bool covariantGenerics;

  /// Whether to infer types downwards from local context
  final bool inferDownwards;
  static const inferDownwardsDefault = true;

  /// Whether to inject casts between Dart assignable types.
  final bool relaxedCasts;

  /// Whether to use static types for code generation.
  final bool ignoreTypes;

  /// Whether to wrap closures for compatibility.
  final bool wrapClosures;
  static const wrapClosuresDefault = false;

  RulesOptions({this.allowConstCasts: true, this.covariantGenerics: true,
      this.inferDownwards: inferDownwardsDefault, this.relaxedCasts: true,
      this.ignoreTypes: false, this.wrapClosures: wrapClosuresDefault});
}

class JSCodeOptions {
  /// Whether to emit the source map files.
  final bool emitSourceMaps;

  JSCodeOptions({this.emitSourceMaps: true});
}

/// General options used by the dev compiler.
class CompilerOptions implements RulesOptions, ResolverOptions, JSCodeOptions {
  /// Whether to check the sdk libraries.
  final bool checkSdk;

  /// Whether to dump summary information on the console.
  final bool dumpInfo;

  /// If not null, path to a file that will store a json representation of the
  /// summary information (only used if [dumpInfo] is true).
  final String dumpInfoFile;

  /// Directory where to dump the orignal but formatted Dart sources. This is
  /// mainly used to make it easier to compare input and output files.
  final String dumpSrcDir;

  /// Whether to force compilation of code with static errors.
  final bool forceCompile;

  /// Whether to run the dart_style formatter on the generated Dart code.
  final bool formatOutput;

  /// Whether to use a cheap formatter instead of dart_style. This might not be
  /// a semantically correct formatter and it is used for testing only.
  final bool cheapTestFormat;

  /// Output directory for generated code.
  final String outputDir;

  /// Whether to emit Dart output (false means to emit JS output).
  final bool outputDart;

  /// Whether to use colors when interacting on the console.
  final bool useColors;

  /// Whether the user asked for help.
  final bool help;

  /// Whether to use a mock-sdk during compilation.
  final bool useMockSdk;

  /// Path to the dart-sdk. Null if `useMockSdk` is true or if the path couldn't
  /// be determined
  final String dartSdkPath;

  /// Minimum log-level reported on the command-line.
  final Level logLevel;

  /// File where to start compilation from.
  final String entryPointFile;

  /// Whether to allow casts in constant contexts.
  @override
  final bool allowConstCasts;

  /// Whether to run as a development server.
  final bool serverMode;

  /// Whether to create an implicit HTML entry file in server mode.
  final bool useImplicitHtml;

  /// Whether to enable hash-based caching of files.
  final bool enableHashing;

  /// Port used for the HTTP server when [serverMode] is on.
  final int port;

  /// Host name or address for HTTP server when [serverMode] is on.
  final String host;

  /// Whether to use covariant generics
  @override
  final bool covariantGenerics;

  /// Whether to inject casts between Dart assignable types.
  @override
  final bool relaxedCasts;

  /// Whether to resolve 'package:' uris using the multi-package resolver.
  @override
  final bool useMultiPackage;

  /// Package root when resolving 'package:' urls the standard way.
  @override
  final String packageRoot;

  /// List of paths used for the multi-package resolver.
  @override
  final List<String> packagePaths;

  /// List of additional non-Dart resources to resolve and serve.
  @override
  final List<String> resources;

  /// Whether to infer types downwards from local context
  @override
  final bool inferDownwards;

  /// Whether to infer return types and field types from overriden members.
  @override
  final bool inferFromOverrides;

  /// Whether to infer types for consts and static fields by looking at
  /// identifiers on the RHS.
  @override
  final bool inferTransitively;

  /// Restrict inference of fields and top-levels to those that are final and
  /// const.
  @override
  final bool onlyInferConstsAndFinalFields;

  /// List of non-nullable types.
  @override
  final List<String> nonnullableTypes;

  /// Whether to use static types for code generation.
  @override
  final bool ignoreTypes;

  /// Whether to wrap closures for compatibility.
  @override
  final bool wrapClosures;

  /// Whether to emit the source map files.
  @override
  final bool emitSourceMaps;

  /// Location for runtime files, such as `dart_runtime.js`. By default this is
  /// inferred to be under `lib/runtime/` in the location of the `dev_compiler`
  /// package (if we can infer where that is located).
  final String runtimeDir;

  CompilerOptions({this.allowConstCasts: true, this.checkSdk: false,
      this.dumpInfo: false, this.dumpInfoFile, this.dumpSrcDir,
      this.forceCompile: false, this.formatOutput: false,
      this.cheapTestFormat: false, this.ignoreTypes: false,
      this.wrapClosures: RulesOptions.wrapClosuresDefault, this.outputDir,
      this.outputDart: false, this.useColors: true,
      this.covariantGenerics: true, this.relaxedCasts: true,
      this.useMultiPackage: false, this.packageRoot: 'packages/',
      this.packagePaths: const <String>[], this.resources: const <String>[],
      this.inferDownwards: RulesOptions.inferDownwardsDefault,
      this.inferFromOverrides: ResolverOptions.inferFromOverridesDefault,
      this.inferTransitively: ResolverOptions.inferTransitivelyDefault,
      this.onlyInferConstsAndFinalFields: ResolverOptions.onlyInferConstAndFinalFieldsDefault,
      this.nonnullableTypes: TypeOptions.NONNULLABLE_TYPES, this.help: false,
      this.useMockSdk: false, this.dartSdkPath, this.logLevel: Level.SEVERE,
      this.emitSourceMaps: true, this.entryPointFile: null,
      this.serverMode: false, this.useImplicitHtml: false,
      this.enableHashing: false, this.host: 'localhost', this.port: 8080,
      this.runtimeDir});
}

/// Parses options from the command-line
CompilerOptions parseOptions(List<String> argv) {
  ArgResults args = argParser.parse(argv);
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

  var entryPointFile = args.rest.length == 0 ? null : args.rest.first;

  return new CompilerOptions(
      allowConstCasts: args['allow-const-casts'],
      checkSdk: args['sdk-check'],
      dumpInfo: dumpInfo,
      dumpInfoFile: args['dump-info-file'],
      dumpSrcDir: args['dump-src-to'],
      forceCompile: args['force-compile'] || serverMode,
      formatOutput: args['dart-gen-fmt'],
      ignoreTypes: args['ignore-types'],
      wrapClosures: args['wrap-closures'],
      outputDart: args['dart-gen'],
      outputDir: outputDir,
      covariantGenerics: args['covariant-generics'],
      relaxedCasts: args['relaxed-casts'],
      useColors: useColors,
      useMultiPackage: args['use-multi-package'],
      packageRoot: args['package-root'],
      packagePaths: args['package-paths'].split(','),
      resources: args['resources'].split(','),
      inferDownwards: args['infer-downwards'],
      inferFromOverrides: args['infer-from-overrides'],
      inferTransitively: args['infer-transitively'],
      onlyInferConstsAndFinalFields: args['infer-only-finals'],
      nonnullableTypes: optionsToList(args['nonnullable'],
          defaultValue: TypeOptions.NONNULLABLE_TYPES),
      help: args['help'],
      useMockSdk: args['mock-sdk'],
      dartSdkPath: sdkPath,
      logLevel: logLevel,
      emitSourceMaps: args['source-maps'],
      entryPointFile: entryPointFile,
      serverMode: serverMode,
      useImplicitHtml: serverMode && entryPointFile.endsWith('.dart'),
      enableHashing: enableHashing,
      host: args['host'],
      port: int.parse(args['port']),
      runtimeDir: runtimeDir);
}

final ArgParser argParser = new ArgParser()
  // resolver/checker options
  ..addFlag('allow-const-casts',
      help: 'Allow casts in const contexts', defaultsTo: true)
  ..addFlag('sdk-check',
      abbr: 's', help: 'Typecheck sdk libs', defaultsTo: false)
  ..addFlag('mock-sdk',
      abbr: 'm', help: 'Use a mock Dart SDK', defaultsTo: false)
  ..addFlag('covariant-generics',
      help: 'Use covariant generics', defaultsTo: true)
  ..addFlag('ignore-types',
      help: 'Ignore types during codegen', defaultsTo: false)
  ..addFlag('wrap-closures',
      help: 'wrap closures implicitly',
      defaultsTo: RulesOptions.wrapClosuresDefault)
  ..addFlag('relaxed-casts',
      help: 'Cast between Dart assignable types', defaultsTo: true)
  ..addOption('nonnullable',
      abbr: 'n',
      help: 'Comma separated string of non-nullable types',
      defaultsTo: null)
  ..addFlag('infer-downwards',
      help: 'Infer types downwards from local context',
      defaultsTo: RulesOptions.inferDownwardsDefault)
  ..addFlag('infer-from-overrides',
      help: 'Infer unspecified types of fields and return types from\n'
      'definitions in supertypes',
      defaultsTo: ResolverOptions.inferFromOverridesDefault)
  ..addFlag('infer-transitively',
      help: 'Infer consts/fields from definitions in other libraries',
      defaultsTo: ResolverOptions.inferTransitivelyDefault)
  ..addFlag('infer-only-finals',
      help: 'Do not infer non-const or non-final fields',
      defaultsTo: ResolverOptions.onlyInferConstAndFinalFieldsDefault)

  // input/output options
  ..addOption('out', abbr: 'o', help: 'Output directory', defaultsTo: null)
  ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null)
  ..addFlag('dart-gen',
      abbr: 'd', help: 'Generate dart output', defaultsTo: false)
  ..addFlag('dart-gen-fmt',
      help: 'Generate readable dart output', defaultsTo: true)
  ..addOption('dump-src-to', help: 'Dump dart src code', defaultsTo: null)
  ..addOption('package-root',
      abbr: 'p',
      help: 'Package root to resolve "package:" imports',
      defaultsTo: 'packages/')
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
      defaultsTo: null);

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
