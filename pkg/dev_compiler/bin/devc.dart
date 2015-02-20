#!/usr/bin/env dart

/// Command line tool to run the checker on a Dart program.
library ddc.bin.checker;

import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:logging/logging.dart' show Logger, Level;

import 'package:ddc/config.dart';
import 'package:ddc/devc.dart';
import 'package:ddc/src/checker/dart_sdk.dart' show mockSdkSources;
import 'package:ddc/src/checker/resolver.dart' show TypeResolver;
import 'package:ddc/src/options.dart';

final ArgParser argParser = new ArgParser()
  ..addFlag(
      'covariant-generics', help: 'Use covariant generics', defaultsTo: true)
  ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null)
  ..addFlag('dart-gen',
      abbr: 'd', help: 'Generate dart output', defaultsTo: false)
  ..addFlag('dart-gen-fmt',
      help: 'Generate readable dart output', defaultsTo: true)
  ..addFlag('dump-info',
      abbr: 'i', help: 'Dump summary information', defaultsTo: false)
  ..addOption('dump-info-file',
      abbr: 'f',
      help: 'Dump info json file (requires dump-info)',
      defaultsTo: null)
  ..addOption('dump-src-to', help: 'Dump dart src code', defaultsTo: null)
  ..addFlag('force-compile',
      help: 'Compile code with static errors', defaultsTo: false)
  ..addFlag('help', abbr: 'h', help: 'Display this message')
  ..addOption('log', abbr: 'l', help: 'Logging level', defaultsTo: 'severe')
  ..addFlag('mock-sdk',
      abbr: 'm', help: 'Use a mock Dart SDK', defaultsTo: false)
  ..addOption('out', abbr: 'o', help: 'Output directory', defaultsTo: null)
  ..addFlag('relaxed-casts',
      help: 'Cast between Dart assignable types', defaultsTo: true)
  ..addOption('package-root',
      abbr: 'p',
      help: 'Package root to resolve "package:" imports',
      defaultsTo: 'packages/')
  ..addFlag('use-multi-package',
      help: 'Whether to use the multi-package resolver for "package:" imports',
      defaultsTo: false)
  ..addOption('nonnullable',
      abbr: 'n',
      help: 'Comma separated string of non-nullable types',
      defaultsTo: null)
  ..addOption('package-paths', help: 'if using the multi-package resolver, '
      'the list of directories where to look for packages.', defaultsTo: '')
  ..addFlag('sdk-check',
      abbr: 's', help: 'Typecheck sdk libs', defaultsTo: false)
  ..addFlag('infer-from-overrides',
      help: 'Infer unspecified types of fields and return types from '
      'definitions in supertypes', defaultsTo: true)
  ..addFlag('infer-transitively',
      help: 'Infer consts/fields from definitions in other libraries',
      defaultsTo: false)
  ..addFlag('infer-only-finals',
      help: 'Do not infer non-const or non-final fields', defaultsTo: false)
  ..addFlag('infer-eagerly',
      help: 'experimental: allows a non-stable order of transitive inference on'
      ' consts and fields. This is used to test for possible inference with a '
      'proper implementation in the future.', defaultsTo: false);

void _showUsageAndExit() {
  print('usage: dartdevc [<options>] <file.dart>\n');
  print('<file.dart> is a single Dart file to process.\n');
  print('<options> include:\n');
  print(argParser.usage);
  exit(1);
}

void main(List<String> argv) {
  ArgResults args = argParser.parse(argv);
  if (args['help']) _showUsageAndExit();

  bool shouldMockSdk = args['mock-sdk'];
  String dartSdkPath;
  if (!shouldMockSdk) {
    var sdkDir = getSdkDir(argv);
    if (sdkDir == null) {
      print('Could not automatically find dart sdk path.');
      print('Please pass in explicitly: --dart-sdk <path>');
      exit(1);
    }
    dartSdkPath = sdkDir.path;
  }

  if (args.rest.length == 0) {
    print('Expected filename.');
    _showUsageAndExit();
  }

  String levelName = args['log'].toUpperCase();
  Level level = Level.LEVELS.firstWhere((Level l) => l.name == levelName,
      orElse: () => Level.SEVERE);
  var useColors = stdioType(stdout) == StdioType.TERMINAL;
  if (!args['dump-info']) setupLogger(level, print);

  var options = new CompilerOptions(
      checkSdk: args['sdk-check'],
      dumpInfo: args['dump-info'],
      dumpInfoFile: args['dump-info-file'],
      dumpSrcDir: args['dump-src-to'],
      forceCompile: args['force-compile'],
      formatOutput: args['dart-gen-fmt'],
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
      inferInNonStableOrder: args['infer-eagerly'],
      onlyInferConstsAndFinalFields: args['infer-only-finals'],
      nonnullableTypes: optionsToList(args['nonnullable'],
          defaultValue: TypeOptions.NONNULLABLE_TYPES));

  var typeResolver = shouldMockSdk
      ? new TypeResolver.fromMock(mockSdkSources, options)
      : new TypeResolver.fromDir(dartSdkPath, options);
  var filename = args.rest.first;
  var result = compile(filename, typeResolver, options);
  exit(result.failure ? 1 : 0);
}
