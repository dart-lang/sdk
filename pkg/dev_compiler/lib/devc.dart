/// Command line tool to run the checker on a Dart program.
library ddc.devc;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart' show Level, Logger, LogRecord;
import 'package:path/path.dart' as path;

import 'src/checker/resolver.dart';
import 'src/checker/checker.dart';
import 'src/checker/rules.dart';
import 'src/codegen/code_generator.dart' show CodeGenerator;
import 'src/codegen/dart_codegen.dart';
import 'src/codegen/js_codegen.dart';
import 'src/report.dart';
import 'src/info.dart' show LibraryInfo, CheckerResults;
import 'src/utils.dart' show reachableSources, partsOf;

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
CheckerResults compile(String inputFile, TypeResolver resolver,
    {CheckerReporter reporter, bool checkSdk: false, bool formatOutput: false,
    bool outputDart: false, String outputDir, bool dumpInfo: false,
    String dumpInfoFile, String dumpSrcTo: null, bool forceCompile: false,
    bool useColors: true, bool covariantGenerics: true,
    bool relaxedCasts: true}) {
  var uri = new Uri.file(path.absolute(inputFile));
  if (reporter == null) {
    reporter = dumpInfo ? new SummaryReporter() : new LogReporter(useColors);
  }

  var libraries = <LibraryInfo>[];
  var rules = new RestrictedRules(resolver.context.typeProvider, reporter,
      covariantGenerics: covariantGenerics, relaxedCasts: relaxedCasts);
  var codeChecker = new CodeChecker(rules, reporter);
  var generators = <CodeGenerator>[];
  if (dumpSrcTo != null) {
    generators.add(new EmptyDartGenerator(dumpSrcTo, uri, rules, formatOutput));
  }
  if (outputDir != null) {
    var cg = outputDart
        ? new DartGenerator(outputDir, uri, rules, formatOutput)
        : new JSGenerator(outputDir, uri, rules);
    generators.add(cg);
  }

  bool failure = false;
  var rootSource = resolver.findSource(uri);
  // TODO(sigmund): switch to use synchronous codegen?
  for (var source in reachableSources(rootSource, resolver.context)) {
    var entryUnit = resolver.context.resolveCompilationUnit2(source, source);
    var lib = entryUnit.element.enclosingElement;
    if (!checkSdk && lib.isInSdk) continue;
    var current = new LibraryInfo(lib);
    reporter.enterLibrary(current);
    libraries.add(current);
    rules.currentLibraryInfo = current;

    var units = [entryUnit]
      ..addAll(partsOf(entryUnit, resolver.context)
          .map((p) => resolver.context.resolveCompilationUnit2(p, source)));
    bool failureInLib = false;
    for (var unit in units) {
      var unitSource = unit.element.source;
      reporter.enterSource(unitSource);
      // TODO(sigmund): integrate analyzer errors with static-info (issue #6).
      failureInLib = resolver.logErrors(unitSource, reporter) || failureInLib;
      unit.visitChildren(codeChecker);
      if (codeChecker.failure) failureInLib = true;
      reporter.leaveSource();
    }
    reporter.leaveLibrary();

    if (failureInLib) {
      failure = true;
      if (!forceCompile) continue;
    }
    for (var cg in generators) {
      cg.generateLibrary(units, current, reporter);
    }
  }

  if (dumpInfo && reporter is SummaryReporter) {
    print(summaryToString(reporter.result));
    if (dumpInfoFile != null) {
      new File(dumpInfoFile)
          .writeAsStringSync(JSON.encode(reporter.result.toJsonMap()));
    }
  }
  return new CheckerResults(libraries, rules, failure || forceCompile);
}

final _log = new Logger('ddc');
