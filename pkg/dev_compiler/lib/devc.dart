/// Command line tool to run the checker on a Dart program.
library ddc.devc;

import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:logging/logging.dart' show Level, Logger, LogRecord;

import 'package:ddc/src/checker/checker.dart';
import 'package:ddc/src/checker/resolver.dart' show TypeResolver;
import 'package:ddc/src/emitter/dart_emitter.dart';
import 'package:ddc/src/emitter/js_emitter.dart';
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

Future<bool> compile(String inputFile, TypeResolver resolver,
    {bool checkSdk: false, bool formatOutput: false, bool outputDart: false,
    String outputDir, bool useColors: true}) {

  // Run checker
  var uri = new Uri.file(path.absolute(inputFile));
  var results =
      checkProgram(uri, resolver, checkSdk: checkSdk, useColors: useColors);

  if (results.failure) {
    return new Future.value(false);
  }

  // Generate code.
  if (outputDir != null) {
    var cg = outputDart ?
        new DartGenerator(outputDir, uri, results.libraries, results.infoMap,
            results.rules, formatOutput) : new JSGenerator(
            outputDir, uri, results.libraries, results.infoMap, results.rules);
    return cg.generate().then((_) => true);
  }

  return new Future.value(true);
}

final _log = new Logger('ddc');
