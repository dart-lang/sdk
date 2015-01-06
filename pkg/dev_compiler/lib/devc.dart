/// Command line tool to run the checker on a Dart program.
library ddc.devc;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart' show Level, Logger, LogRecord;
import 'package:path/path.dart' as path;

import 'package:ddc/src/checker/checker.dart';
import 'package:ddc/src/checker/resolver.dart' show TypeResolver;
import 'package:ddc/src/codegen/dart_codegen.dart';
import 'package:ddc/src/codegen/js_codegen.dart';
import 'package:ddc/src/report.dart';

/// Sets up the type checker logger to print a span that highlights error
/// messages.
StreamSubscription setupLogger(Level level, printFn) {
  Logger.root.level = level;
  return Logger.root.onRecord.listen((LogRecord rec) {
    printFn('${rec.level.name.toLowerCase()}: ${rec.message}');
  });
}

/// Compiles [inputFile] writing output as specified by the arguments.
/// [dumpInfoFile] will only be used if [dumpInfo] is true.
Future<bool> compile(String inputFile, TypeResolver resolver,
    {bool checkSdk: false, bool formatOutput: false, bool outputDart: false,
    String outputDir, bool dumpInfo: false, String dumpInfoFile,
    bool useColors: true}) {

  // Run checker
  var reporter = dumpInfo ? new SummaryReporter() : new LogReporter(useColors);
  var uri = new Uri.file(path.absolute(inputFile));
  var results = checkProgram(uri, resolver, reporter,
      checkSdk: checkSdk, useColors: useColors);

  // TODO(sigmund): return right after?
  if (dumpInfo) {
    print(summaryToString(reporter.result));
    if (dumpInfoFile != null) {
      new File(dumpInfoFile).writeAsStringSync(
          JSON.encode(reporter.result.toJsonMap()));
    }
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
