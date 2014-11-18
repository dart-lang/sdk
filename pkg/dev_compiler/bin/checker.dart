library checker;

import 'dart:io';

import 'package:args/args.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/options.dart';
import 'package:analyzer/src/analyzer_impl.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:logging/logging.dart' as logger;
import 'package:source_span/source_span.dart';

import 'package:ddc/typechecker.dart';

final parser = new ArgParser();

ArgResults parse(List argv) {
  parser.addFlag('type-check', abbr: 't', help: 'Typecheck only', defaultsTo: false);
  parser.addOption('log', abbr: 'l', help: 'Logging level', defaultsTo: 'severe');
  parser.addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null);
  parser.addOption('out', abbr: 'o', help: 'Output directory', defaultsTo: null);
  return parser.parse(argv);
}

String findSdk() {
  // Find the SDK from the Platform.
  String dart = Platform.executable;
  const dartExec = 'bin/dart';
  if (dart.endsWith(dartExec)) {
    return dart.substring(0, dart.length - dartExec.length);
  }
  if (dart == 'dart') {
    // Check if dart is on the path.
    final path = Platform.environment['PATH'];
    List<String> dirs = path.split(':');
    for (final dir in dirs) {
      if (dir.endsWith('/bin')) {
        final file = new File('$dir/$dart');
        if (file.existsSync())
          return file.parent.parent.path;
      }
    }
  }
  return null;
}

void main(List argv) {
  // Parse the command-line options.
  ArgResults args = parse(argv);
  String dartPath = Platform.executable;
  const dartExec = 'bin/dart';
  String dartSdk = args['dart-sdk'];
  if (dartSdk == null) {
    dartSdk = findSdk();
    if (dartSdk == null) {
      // TODO(vsm): Search path.
      print('Could not automatically find dart sdk path.');
      print('Please pass in explicitly: --dart-sdk <path>');
      return;
    }
  }

  // Pass the remaining options to the analyzer.
  final analyzerArgv = ['--dart-sdk', dartSdk, '--no-hints'];
  analyzerArgv.addAll(args.rest);
  CommandLineOptions options = CommandLineOptions.parse(analyzerArgv);

  // Configure logger
  log = new logger.Logger('checker');
  String levelName = args['log'];
  levelName = levelName.toUpperCase();
  logger.Level level = logger.Level.LEVELS.firstWhere((logger.Level l) => l.name == levelName);
  logger.Logger.root.level = level;
  logger.Logger.root.onRecord.listen((logger.LogRecord rec) {
    AstNode node = rec.error;
    if (node == null) {
      print('${rec.level.name}: ${rec.message}');
      return;
    }

    final root = node.root as CompilationUnit;
    final source = (root.element as CompilationUnitElementImpl).source;
    final file = new SourceFile(source.contents.data, url: source.uri);
    final span = file.span(node.beginToken.offset, node.endToken.end);
    print(span.message(rec.message, color: true));
  });

  // Run dart analyzer.  We rely on it for resolution.
  int exitCode = 0;
  if (options.sourceFiles.length != 1)
    throw 'Filename expected';
  final filename = options.sourceFiles[0];
  AnalyzerImpl analyzer = new AnalyzerImpl(filename, options, 0);
  var errorSeverity = analyzer.analyzeSync();
  if (errorSeverity == ErrorSeverity.ERROR) {
    exitCode = errorSeverity.ordinal;
  }
  if (options.warningsAreFatal && errorSeverity == ErrorSeverity.WARNING) {
    exitCode = errorSeverity.ordinal;
  }
  if (exitCode != 0) {
    log.severe('error');
    return;
  }

  // Invoke the checker on the entry point.
  AnalysisContext context = analyzer.context;
  TypeProvider provider = (context as AnalysisContextImpl).typeProvider;
  final source = analyzer.librarySource;
  final uri = new Uri.file(filename);
  final visitor = new ProgramChecker(context, new StartRules(provider), uri, source);
  visitor.check();
  visitor.finalizeImports();

  if (visitor.failure)
    log.shout('Program is not valid');
  else
    log.shout('Program is valid');
}


