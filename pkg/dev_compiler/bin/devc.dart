/// Command line tool to run the checker on a Dart program.
library ddc.bin.checker;

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart' show Logger, Level;

import 'package:ddc/devc.dart';
import 'package:ddc/src/checker/dart_sdk.dart' show dartSdkDirectory, mockSdkSources;
import 'package:ddc/src/checker/resolver.dart' show TypeResolver;

ArgResults parse(List argv) {
  var parser = new ArgParser()
    ..addFlag(
        'sdk-check', abbr: 's', help: 'Typecheck sdk libs', defaultsTo: false)
    ..addOption('log', abbr: 'l', help: 'Logging level', defaultsTo: 'severe')
    ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null)
    ..addFlag(
        'dart-gen', abbr: 'd', help: 'Generate dart output', defaultsTo: false)
    ..addFlag(
        'dart-gen-fmt', help: 'Generate readable dart output', defaultsTo: true)
    ..addFlag(
        'mock-sdk', abbr: 'm', help: 'Use a mock Dart SDK', defaultsTo: false)
    ..addFlag('new-checker', abbr: 'n', help: 'Use the new type checker',
        defaultsTo: false)
    ..addOption('out', abbr: 'o', help: 'Output directory', defaultsTo: null);
  return parser.parse(argv);
}

void main(List argv) {
  ArgResults args = parse(argv);
  bool shouldMockSdk = args['mock-sdk'];
  String dartSdkPath;
  if (!shouldMockSdk) {
    dartSdkPath = args['dart-sdk'];
    if (dartSdkPath == null) dartSdkPath = dartSdkDirectory;
    if (dartSdkPath == null) {
      print('Could not automatically find dart sdk path.');
      print('Please pass in explicitly: --dart-sdk <path>');
      exit(1);
    }
  }

  if (args.rest.length == 0) {
    print('Expected filename.');
    exit(1);
  }

  String levelName = args['log'].toUpperCase();
  Level level = Level.LEVELS.firstWhere((Level l) => l.name == levelName);
  var useColors = stdioType(stdout) != StdioType.TERMINAL;
  setupLogger(level, print, useColors: useColors);

  var typeResolver = new TypeResolver(shouldMockSdk ?
      TypeResolver.sdkResolverFromMock(mockSdkSources) :
      TypeResolver.sdkResolverFromDir(dartSdkPath));

  var filename = args.rest[0];
  compile(filename, typeResolver, checkSdk: args['sdk-check'],
      formatOutput: args['dart-gen-fmt'], outputDart: args['dart-gen'],
      outputDir: args['out'], useColors: useColors).then((success) {
    exit(success ? 0 : 1);
  });
}
