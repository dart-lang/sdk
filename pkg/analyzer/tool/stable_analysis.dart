// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:linter/src/rules.dart' as linter;

void main(List<String> args) {
  String? dirPath;
  bool registerLints = true;
  bool dumpPerformanceNumbers = false;

  for (String arg in args) {
    if (arg == "--no-lints") {
      registerLints = false;
    } else if (arg == "--dump-performance") {
      dumpPerformanceNumbers = true;
    } else if (!arg.startsWith("--") && dirPath == null) {
      dirPath = arg;
    } else {
      throw "Unknown argument: $arg";
    }
  }

  if (registerLints) {
    linter.registerLintRules();
  }
  if (dirPath == null) throw "Needs a directory to work on.";
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
          print(diagnostic);
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
