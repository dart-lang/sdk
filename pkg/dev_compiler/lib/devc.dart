// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line tool to run the checker on a Dart program.
library ddc.devc;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart' show Level, Logger, LogRecord;
import 'package:path/path.dart' as path;
import 'package:html5lib/parser.dart' show parse;

import 'src/checker/resolver.dart';
import 'src/checker/checker.dart';
import 'src/checker/rules.dart';
import 'src/codegen/code_generator.dart' show CodeGenerator;
import 'src/codegen/dart_codegen.dart';
import 'src/codegen/js_codegen.dart';
import 'src/codegen/html_codegen.dart';
import 'src/options.dart';
import 'src/report.dart';
import 'src/info.dart' show LibraryInfo, CheckerResults;
import 'src/utils.dart' show reachableSources, partsOf, colorOf;

/// Sets up the type checker logger to print a span that highlights error
/// messages.
StreamSubscription setupLogger(Level level, printFn) {
  Logger.root.level = level;
  return Logger.root.onRecord.listen((LogRecord rec) {
    printFn('${rec.level.name.toLowerCase()}: ${rec.message}');
  });
}

/// Compiles [inputFile] writing output as specified by the arguments.
CheckerResults compile(
    String inputFile, TypeResolver resolver, CompilerOptions options,
    [CheckerReporter reporter]) {
  if (inputFile.endsWith('.html')) {
    return _compileHtml(inputFile, resolver, options, reporter);
  } else {
    return _compileDart(inputFile, resolver, options, reporter);
  }
}

CheckerResults _compileHtml(
    String inputFile, TypeResolver resolver, CompilerOptions options,
    [CheckerReporter reporter]) {
  var doc = parse(new File(inputFile).readAsStringSync(), generateSpans: true);
  var scripts = doc.querySelectorAll('script[type="application/dart"]');
  if (scripts.isEmpty) {
    _log.severe('No <script type="application/dart"> found in $inputFile');
    return _earlyErrorResult;
  }
  var mainScriptTag = scripts[0];
  scripts.skip(1).forEach((s) {
    _log.warning(s.sourceSpan.message(
        'unexpected script. Only one Dart script tag allowed '
        '(see https://github.com/dart-lang/dart-dev-compiler/issues/53).',
        color: options.useColors ? colorOf('warning') : false));
  });

  var url = mainScriptTag.attributes['src'];
  if (url == null) {
    _log.severe(mainScriptTag.sourceSpan.message(
        'inlined script tags not supported at this time '
        '(see https://github.com/dart-lang/dart-dev-compiler/issues/54).',
        color: options.useColors ? colorOf('error') : false));
    return _earlyErrorResult;
  }

  var dartInputFile = path.join(path.dirname(inputFile), url);

  if (!new File(dartInputFile).existsSync()) {
    _log.severe(mainScriptTag.sourceSpan.message(
        'Script file $dartInputFile not found',
        color: options.useColors ? colorOf('error') : false));
    return _earlyErrorResult;
  }

  var results = _compileDart(dartInputFile, resolver, options, reporter);
  if (results.failure && !options.forceCompile) return results;

  if (options.outputDir != null) {
    generateEntryHtml(inputFile, options, results, doc);
  }
  return results;
}

CheckerResults _compileDart(
    String inputFile, TypeResolver resolver, CompilerOptions options,
    [CheckerReporter reporter]) {
  Uri uri;
  if (inputFile.startsWith('dart:') || inputFile.startsWith('package:')) {
    uri = Uri.parse(inputFile);
  } else {
    uri = new Uri.file(path.absolute(inputFile));
  }

  if (reporter == null) {
    reporter = options.dumpInfo
        ? new SummaryReporter()
        : new LogReporter(options.useColors);
  }

  var libraries = <LibraryInfo>[];
  var rules = new RestrictedRules(resolver.context.typeProvider, reporter,
      options: options);
  var codeChecker = new CodeChecker(rules, reporter, options);
  var generators = <CodeGenerator>[];
  if (options.dumpSrcDir != null) {
    generators
        .add(new EmptyDartGenerator(options.dumpSrcDir, uri, rules, options));
  }
  var outputDir = options.outputDir;
  if (outputDir != null) {
    var cg = options.outputDart
        ? new DartGenerator(outputDir, uri, rules, options)
        : new JSGenerator(outputDir, uri, rules, options);
    generators.add(cg);
  }

  bool failure = false;
  var rootSource = resolver.findSource(uri);
  // TODO(sigmund): switch to use synchronous codegen?
  for (var source in reachableSources(rootSource, resolver.context)) {
    var entryUnit = resolver.context.resolveCompilationUnit2(source, source);
    var lib = entryUnit.element.enclosingElement;
    if (!options.checkSdk && lib.isInSdk) continue;
    var current = new LibraryInfo(lib, source.uri == uri);
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
      if (!options.forceCompile) continue;
    }
    for (var cg in generators) {
      cg.generateLibrary(units, current, reporter);
    }
  }

  if (options.dumpInfo && reporter is SummaryReporter) {
    print(summaryToString(reporter.result));
    if (options.dumpInfoFile != null) {
      new File(options.dumpInfoFile)
          .writeAsStringSync(JSON.encode(reporter.result.toJsonMap()));
    }
  }
  return new CheckerResults(libraries, rules, failure || options.forceCompile);
}

final _log = new Logger('ddc');
final _earlyErrorResult = new CheckerResults(const [], null, true);
