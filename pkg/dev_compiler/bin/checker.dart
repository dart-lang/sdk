/// Command line tool to run the checker on a Dart program.
library ddc.bin.checker;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:args/args.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:logging/logging.dart' as logger;

import 'package:ddc/codegenerator.dart';
import 'package:ddc/typechecker.dart';
import 'package:ddc/src/dart_sdk.dart' show dartSdkDirectory, mockSdkSources;
import 'package:ddc/src/utils.dart';

ArgResults parse(List argv) {
  var parser = new ArgParser()
      ..addFlag(
          'sdk-check', abbr: 's', help: 'Typecheck sdk libs', defaultsTo: false)
      ..addOption('log', abbr: 'l', help: 'Logging level', defaultsTo: 'severe')
      ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null)
      ..addFlag(
          'mock-sdk', abbr: 'm', help: 'Use a mock Dart SDK', defaultsTo: false)
      ..addOption('out', abbr: 'o', help: 'Output directory', defaultsTo: null);
  return parser.parse(argv);
}

/// Sets up the type checker logger to print a span that highlights error
/// messages.
void setupLogger(String levelName, bool useColors) {
  levelName = levelName.toUpperCase();
  logger.Level level = logger.Level.LEVELS
      .firstWhere((logger.Level l) => l.name == levelName);
  logger.Logger.root.level = level;
  logger.Logger.root.onRecord.listen((logger.LogRecord rec) {
    AstNode node = rec.error;
    if (node == null) {
      print('${rec.level.name.toLowerCase()}: ${rec.message}');
      return;
    }

    final root = node.root as CompilationUnit;
    final source = (root.element as CompilationUnitElementImpl).source;
    final begin = node is AnnotatedNode ?
        node.firstTokenAfterCommentAndMetadata.offset : node.offset;
    final span = spanFor(source, begin, node.end);
    final color = colorOf(rec.level.name);
    print('${span.message(rec.message, color: color)}');
  });
}

void main(List argv) {
  // Parse the command-line options.
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

  var useColors = stdioType(stdout) != StdioType.TERMINAL;
  setupLogger(args['log'], useColors);

  // Run checker
  var uri = new Uri.file(path.absolute(args.rest[0]));
  var results = checkProgram(uri,
      sdkDir: shouldMockSdk ? null : dartSdkPath,
      mockSdkSources: shouldMockSdk ? mockSdkSources : null,
      checkSdk: args['sdk-check'],
      useColors: useColors);

  // Generate code.
  if (args['out'] != null) {
    String outDir = args['out'];
    var cg = new CodeGenerator(outDir, uri, results.libraries, results.infoMap);
    cg.generate();
  }

  if (results.failure) {
    _log.shout('Program is not valid');
  } else {
    _log.shout('Program is valid');
  }
}


final _log = new logger.Logger('ddc.bin.checker');
