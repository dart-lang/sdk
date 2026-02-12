// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/lint/registry.dart' as linter;
import 'package:linter/src/rules.dart' as linter;

void main(List<String> args) {
  String? dirPath;
  bool withFineDependencies = true;
  bool silent = false;
  bool lints = true;
  bool warnings = true;
  bool comments = true;
  bool dumpPerformanceNumbers = false;
  // Hardcoded for now, but could be interesting to try them one at a time and
  // see what the cost of each individual lint is.
  Set<String> wantedLints = {
    "collection_methods_unrelated_type",
    "curly_braces_in_flow_control_structures",
    "depend_on_referenced_packages",
    "prefer_adjacent_string_concatenation",
    "unawaited_futures",
    "avoid_void_async",
    "recursive_getters",
    "avoid_empty_else",
    "empty_statements",
    "valid_regexps",
    "lines_longer_than_80_chars",
    "unrelated_type_equality_checks",
    "annotate_overrides",
    "always_declare_return_types",
  };

  for (String arg in args) {
    if (arg == "--silent") {
      silent = true;
    } else if (arg == "--no-lints") {
      lints = false;
    } else if (arg == "--no-fine-dependencies") {
      withFineDependencies = false;
    } else if (arg == "--no-warnings") {
      warnings = false;
    } else if (arg == "--no-comments") {
      comments = false;
    } else if (arg == "--dump-performance") {
      dumpPerformanceNumbers = true;
    } else if (!arg.startsWith("--") && dirPath == null) {
      dirPath = arg;
    } else {
      throw "Unknown argument: $arg";
    }
  }
  if (dirPath == null) throw "Needs a directory to work on.";
  if (dirPath.endsWith("/")) dirPath = dirPath.substring(0, dirPath.length - 1);
  Directory dir = Directory(dirPath);
  List<String> filesToAnalyze = [];
  for (FileSystemEntity entity in dir.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File && entity.path.endsWith('.dart')) {
      filesToAnalyze.add(entity.path);
    }
  }

  if (lints) {
    linter.registerLintRules();
  }

  // ignore: invalid_use_of_visible_for_testing_member
  Scanner.preserveCommentsDefaultForTesting = comments;

  // Creating the Scheduler here, and not starting it, means it's not going to
  // get started. It's good for stability :).
  // To make sure the 'start' method is overwritten below.
  PerformanceLog performanceLog = PerformanceLog(null);
  AnalysisDriverScheduler scheduler = BypassedAnalysisDriverScheduler(
    performanceLog,
  );
  AnalysisContextCollectionImpl collection = AnalysisContextCollectionImpl(
    includedPaths: [dir.path],
    scheduler: scheduler,
    updateAnalysisOptions4: ({required AnalysisOptionsImpl analysisOptions}) {
      analysisOptions.warning = warnings;
      analysisOptions.lint = lints;
      if (lints) {
        int added = 0;
        for (var rule in linter.Registry.ruleRegistry.rules) {
          if (wantedLints.contains(rule.name)) {
            analysisOptions.lintRules.add(rule);
            added++;
          }
        }
        if (!silent) print("Enabled $added lints");
      }
    },
    withFineDependencies: withFineDependencies,
  );
  DriverBasedAnalysisContext context = collection.contexts[0];
  AnalysisDriver analysisDriver = context.driver;
  List<String> libPaths = [];
  analysisDriver.scheduler.accumulatedPerformance.run('getFileForPath', (_) {
    for (var path in filesToAnalyze) {
      var file = analysisDriver.fsState.getFileForPath(path);
      var kind = file.kind;
      if (kind is LibraryFileKind) {
        libPaths.add(path);
      }
    }
  });
  for (var path in libPaths) {
    // ignore: invalid_use_of_visible_for_testing_member
    var library = analysisDriver.analyzeFileForTesting(path);
    if (library == null) {
      throw 'Got null for $path';
    } else {
      for (var unit in library.units) {
        for (var diagnostic in unit.diagnostics) {
          if (diagnostic.diagnosticCode.type == DiagnosticType.TODO) continue;
          if (!silent) print(diagnostic);
        }
      }
    }
  }

  if (dumpPerformanceNumbers) {
    var buffer = StringBuffer();
    analysisDriver.scheduler.accumulatedPerformance.write(buffer: buffer);
    print(buffer);
  }
}

class BypassedAnalysisDriverScheduler extends AnalysisDriverScheduler {
  BypassedAnalysisDriverScheduler(super.logger);

  @override
  void start() {
    throw 'This scheduler should not be started.';
  }
}
