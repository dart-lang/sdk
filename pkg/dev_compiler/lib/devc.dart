/// Command line tool to run the checker on a Dart program.
library ddc;

import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:logging/logging.dart' show Level, Logger, LogRecord;

import 'package:ddc/codegenerator.dart';
import 'package:ddc/typechecker.dart';
import 'package:ddc/src/resolver.dart' show TypeResolver;
import 'package:ddc/src/utils.dart';

/// Sets up the type checker logger to print a span that highlights error
/// messages.
StreamSubscription setupLogger(Level level, printFn, {bool useColors: true}) {
  Logger.root.level = level;
  return Logger.root.onRecord.listen((LogRecord rec) {
    AstNode node = rec.error;
    if (node == null) {
      printFn('${rec.level.name.toLowerCase()}: ${rec.message}');
      return;
    }

    final root = node.root as CompilationUnit;
    final source = (root.element as CompilationUnitElementImpl).source;
    final begin = node is AnnotatedNode ?
        node.firstTokenAfterCommentAndMetadata.offset : node.offset;
    final span = spanFor(source, begin, node.end);
    final color = useColors ? colorOf(rec.level.name) : null;
    printFn('${span.message(rec.message, color: color)}');
  });
}

Future<bool> compile(String inputFile, TypeResolver resolver, {String outputDir,
    bool checkSdk: false, bool useColors: true}) {

  // Run checker
  var uri = new Uri.file(path.absolute(inputFile));
  var results =
      checkProgram(uri, resolver, checkSdk: checkSdk, useColors: useColors);

  if (results.failure) {
    return new Future.value(false);
  }

  // Generate code.
  if (outputDir != null) {
    var cg = new CodeGenerator(
        outputDir, uri, results.libraries, results.infoMap, results.rules);
    return cg.generate().then((_) => true);
  }

  return new Future.value(true);
}

final _log = new Logger('ddc');
