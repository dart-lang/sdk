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

import 'package:ddc/codegenerator.dart';
import 'package:ddc/typechecker.dart';
import 'package:ddc/src/type_rules.dart' show RestrictedRules;

ArgResults parse(List argv) {
  var parser = new ArgParser()
      ..addFlag(
          'sdk-check', abbr: 's', help: 'Typecheck sdk libs', defaultsTo: false)
      ..addOption('log', abbr: 'l', help: 'Logging level', defaultsTo: 'severe')
      ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null)
      ..addOption('out', abbr: 'o', help: 'Output directory', defaultsTo: null);
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
        if (file.existsSync()) return file.parent.parent.path;
      }
    }
  }
  return null;
}

void main(List argv) {
  // Parse the command-line options.
  ArgResults args = parse(argv);
  String dartPath = Platform.executable;
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
  logger.Level level = logger.Level.LEVELS
      .firstWhere((logger.Level l) => l.name == levelName);
  logger.Logger.root.level = level;
  int total = 0;
  logger.Logger.root.onRecord.listen((logger.LogRecord rec) {
    total++;
    AstNode node = rec.error;
    if (node == null) {
      print('#$total: ${rec.level.name}: ${rec.message}');
      return;
    }

    final root = node.root as CompilationUnit;
    final source = (root.element as CompilationUnitElementImpl).source;
    final file = new SourceFile(source.contents.data, url: source.uri);
    final begin = node is AnnotatedNode ?
        node.firstTokenAfterCommentAndMetadata.offset : node.offset;
    final span = file.span(begin, node.end);
    print('#$total: ${span.message(rec.message, color: _color(rec.level))}');
  });

  // Run dart analyzer.  We rely on it for resolution.
  int exitCode = 0;
  if (options.sourceFiles.length != 1) throw 'Filename expected';
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
  final visitor = new ProgramChecker(
      context, new RestrictedRules(provider), uri, source, args['sdk-check']);
  visitor.check();
  visitor.finalizeImports();

  // Generate code.
  if (args['out'] != null) {
    String outDir = args['out'];
    final cg =
        new CodeGenerator(outDir, uri, visitor.libraries, visitor.infoMap);
    cg.generate();
  }

  if (visitor.failure) {
    log.shout('Program is not valid');
  } else {
    log.shout('Program is valid');
  }
}

const String _RED_COLOR = '\u001b[31m';
const String _MAGENTA_COLOR = '\u001b[35m';

String _color(logger.Level level) {
  if (stdioType(stdout) != StdioType.TERMINAL) return null;
  return level == logger.Level.SEVERE ? _RED_COLOR : _MAGENTA_COLOR;
}
