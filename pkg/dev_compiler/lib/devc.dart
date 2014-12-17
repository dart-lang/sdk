/// Command line tool to run the checker on a Dart program.
library ddc.devc;

import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:logging/logging.dart' show Level, Logger, LogRecord;

import 'package:ddc/src/checker/checker.dart';
import 'package:ddc/src/checker/resolver.dart' show TypeResolver;
import 'package:ddc/src/codegen/dart_codegen.dart';
import 'package:ddc/src/codegen/js_codegen.dart';
import 'package:ddc/src/report.dart';
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

    final span = spanForNode(node);
    final color = useColors ? colorOf(rec.level.name) : null;
    printFn('${span.message(rec.message, color: color)}');
  });
}

Future<bool> compile(String inputFile, TypeResolver resolver,
    {bool checkSdk: false, bool formatOutput: false, bool outputDart: false,
    String outputDir, bool dumpInfo: false, bool useColors: true}) {

  // Run checker
  var uri = new Uri.file(path.absolute(inputFile));
  var results =
      checkProgram(uri, resolver, checkSdk: checkSdk, useColors: useColors);

  if (dumpInfo) {
    // TODO(sigmund): return right after?
    var summary = checkerResultsToSummary(results);
    print(summaryToString(summary));
  }

  if (results.failure) return new Future.value(false);

  // Generate code.
  if (outputDir != null) {
    var cg = outputDart ?
        new DartGenerator(
            outputDir, uri, results.libraries, results.rules, formatOutput) :
        new JSGenerator(outputDir, uri, results.libraries, results.rules);
    return cg.generate().then((_) => true);
  }

  return new Future.value(true);
}

final _log = new Logger('ddc');
