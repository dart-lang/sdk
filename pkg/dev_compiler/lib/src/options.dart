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

/// Options used by our TypeResolver.
class ResolverOptions {
  /// Whether to resolve 'package:' uris using the multi-package resolver.
  final bool useMultiPackage;

  /// Package root when resolving 'package:' urls the standard way.
  final String packageRoot;

  /// List of paths used for the multi-package resolver.
  final List<String> packagePaths;

  /// Whether to infer return types and field types from overriden members.
  final bool inferFromOverrides;
  static const inferFromOverridesDefault = false;

  /// Whether to infer types for consts and fields by looking at initializers on
  /// the RHS. For example, in a constant declaration like:
  ///
  ///      const A = B;
  ///
  /// We can infer the type of `A` based on the type of `B`. The current
  /// implementation of this inference is limited to ensure the answer is
  /// deterministic when applying inference on library cycles. In the example
  /// above, `A` is inferred to have `B`'s declared type if they are both in the
  /// same library cycle. However, if `B`'s definition is not in the same
  /// connected component as `A`, we use `B`'s inferred type instead.
  ///
  /// Because this might be surprising to users, this is turned off by default.
  /// In the future, inference might track dependencies between variables in
  /// more detail so that, in the example above, we can use `B`'s inferred type
  /// always.
  final bool inferStaticsFromIdentifiers;
  static const inferStaticsFromIdentifiersDefault = false;

  /// Restrict inference of fields and top-levels to those that are final and
  /// const.
  final bool onlyInferConstsAndFinalFields;
  static const onlyInferConstAndFinalFieldsDefault = false;

  ResolverOptions({this.useMultiPackage: false, this.packageRoot: 'packages/',
      this.packagePaths: const <String>[],
      this.inferFromOverrides: inferFromOverridesDefault,
      this.inferStaticsFromIdentifiers: inferStaticsFromIdentifiersDefault,
      this.onlyInferConstsAndFinalFields: onlyInferConstAndFinalFieldsDefault});
}

// TODO(vsm): Merge RulesOptions and TypeOptions
/// Options used by our RestrictedRules.
class RulesOptions extends TypeOptions {
  /// Whether to allow casts in constant contexts.
  final bool allowConstCasts;

  /// Whether to use covariant generics
  final bool covariantGenerics;

  /// Whether to inject casts between Dart assignable types.
  final bool relaxedCasts;

  /// Whether to use static types for code generation.
  final bool ignoreTypes;

  RulesOptions({this.allowConstCasts: true, this.covariantGenerics: true,
      this.relaxedCasts: true, this.ignoreTypes: false});
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

  /// Port used for the HTTP server when [serverMode] is on.
  final int port;

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

  /// Whether to infer return types and field types from overriden members.
  @override
  final bool inferFromOverrides;

  /// Whether to infer types for consts and static fields by looking at
  /// identifiers on the RHS.
  @override
  final bool inferStaticsFromIdentifiers;

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

  /// Whether to emit the source map files.
  @override
  final bool emitSourceMaps;

  CompilerOptions({this.allowConstCasts: true, this.checkSdk: false,
      this.dumpInfo: false, this.dumpInfoFile, this.dumpSrcDir,
      this.forceCompile: false, this.formatOutput: false,
      this.cheapTestFormat: false, this.ignoreTypes: false, this.outputDir,
      this.outputDart: false, this.useColors: true,
      this.covariantGenerics: true, this.relaxedCasts: true,
      this.useMultiPackage: false, this.packageRoot: 'packages/',
      this.packagePaths: const <String>[],
      this.inferFromOverrides: ResolverOptions.inferFromOverridesDefault,
      this.inferStaticsFromIdentifiers: ResolverOptions.inferStaticsFromIdentifiersDefault,
      this.onlyInferConstsAndFinalFields: ResolverOptions.onlyInferConstAndFinalFieldsDefault,
      this.nonnullableTypes: TypeOptions.NONNULLABLE_TYPES, this.help: false,
      this.useMockSdk: false, this.dartSdkPath, this.logLevel: Level.SEVERE,
      this.emitSourceMaps: true, this.entryPointFile: null,
      this.serverMode: false, this.port: 8080});
}

/// Parses options from the command-line
CompilerOptions parseOptions(List<String> argv) {
  ArgResults args = argParser.parse(argv);
  var levelName = args['log'].toUpperCase();
  var useColors = stdioType(stdout) == StdioType.TERMINAL;
  var sdkPath = args['dart-sdk'];
  if (sdkPath == null && !args['mock-sdk']) {
    sdkPath = getSdkDir(argv).path;
  }
  return new CompilerOptions(
      allowConstCasts: args['allow-const-casts'],
      checkSdk: args['sdk-check'],
      dumpInfo: args['dump-info'],
      dumpInfoFile: args['dump-info-file'],
      dumpSrcDir: args['dump-src-to'],
      forceCompile: args['force-compile'],
      formatOutput: args['dart-gen-fmt'],
      ignoreTypes: args['ignore-types'],
      outputDart: args['dart-gen'],
      outputDir: args['out'],
      covariantGenerics: args['covariant-generics'],
      relaxedCasts: args['relaxed-casts'],
      useColors: useColors,
      useMultiPackage: args['use-multi-package'],
      packageRoot: args['package-root'],
      packagePaths: args['package-paths'].split(','),
      inferFromOverrides: args['infer-from-overrides'],
      inferStaticsFromIdentifiers: args['infer-transitively'],
      onlyInferConstsAndFinalFields: args['infer-only-finals'],
      nonnullableTypes: optionsToList(args['nonnullable'],
          defaultValue: TypeOptions.NONNULLABLE_TYPES),
      help: args['help'],
      useMockSdk: args['mock-sdk'],
      dartSdkPath: sdkPath,
      logLevel: Level.LEVELS.firstWhere((Level l) => l.name == levelName,
          orElse: () => Level.SEVERE),
      emitSourceMaps: args['source-maps'],
      entryPointFile: args.rest.length == 0 ? null : args.rest.first,
      serverMode: args['server'],
      port: int.parse(args['port']));
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
  ..addFlag('relaxed-casts',
      help: 'Cast between Dart assignable types', defaultsTo: true)
  ..addOption('nonnullable',
      abbr: 'n',
      help: 'Comma separated string of non-nullable types',
      defaultsTo: null)
  ..addFlag('infer-from-overrides',
      help: 'Infer unspecified types of fields and return types from '
      'definitions in supertypes',
      defaultsTo: ResolverOptions.inferFromOverridesDefault)
  ..addFlag('infer-transitively',
      help: 'Infer consts/fields from definitions in other libraries',
      defaultsTo: ResolverOptions.inferStaticsFromIdentifiersDefault)
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
  ..addOption('package-paths', help: 'if using the multi-package resolver, '
      'the list of directories where to look for packages.', defaultsTo: '')
  ..addFlag('source-maps',
      help: 'Whether to emit source map files', defaultsTo: true)

  // general options
  ..addFlag('help', abbr: 'h', help: 'Display this message')
  ..addFlag('server', help: 'Run as a development server.', defaultsTo: false)
  ..addOption('port',
      help: 'Port where to serve files from (used only when --serve is on)',
      defaultsTo: '8080')
  ..addFlag('force-compile',
      help: 'Compile code with static errors', defaultsTo: false)
  ..addOption('log', abbr: 'l', help: 'Logging level', defaultsTo: 'severe')
  ..addFlag('dump-info',
      abbr: 'i', help: 'Dump summary information', defaultsTo: false)
  ..addOption('dump-info-file',
      abbr: 'f',
      help: 'Dump info json file (requires dump-info)',
      defaultsTo: null);
