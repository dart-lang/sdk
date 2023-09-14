// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart' // ignore: implementation_imports
    show
        AnalysisErrorInfoImpl,
        AnalysisOptionsImpl;
import 'package:analyzer/src/lint/registry.dart'; // ignore: implementation_imports
import 'package:cli_util/cli_logging.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/formatter.dart';
import 'package:path/path.dart' as path;

import '../../test/mocks.dart';
import 'rules/no_solo_tests.dart';
import 'rules/visit_registered_nodes.dart';

Future<void> main() async {
  var results = await runChecks();
  if (results.isNotEmpty) {
    io.exitCode = 3;
  }
}

var customChecks = [VisitRegisteredNodes(), NoSoloTests()];

Future<List<AnalysisError>> runChecks() async {
  var rules =
      path.normalize(io.File(path.join('lib', 'src', 'rules')).absolute.path);
  var tests = path.normalize(io.File(path.join('test')).absolute.path);
  var results = await Driver(customChecks).analyze([rules, tests]);
  return results;
}

class Driver {
  Logger logger = Logger.standard();

  final List<LintRule> lints;
  final bool silent;

  Driver(this.lints, {this.silent = true});

  Future<List<AnalysisError>> analyze(List<String> sources) async {
    if (sources.isEmpty) {
      _print('Specify one or more files and directories.');
      return [];
    }
    ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
    var failedChecks = await _analyzeFiles(resourceProvider, sources);
    _print('Finished.');
    return failedChecks;
  }

  Future<List<AnalysisError>> _analyzeFiles(
      ResourceProvider resourceProvider, List<String> analysisRoots) async {
    _print('Analyzing...');

    // Register our checks.
    lints.forEach(Registry.ruleRegistry.register);

    // Track failures.
    var failedChecks = <AnalysisError>{};

    for (var root in analysisRoots) {
      var collection = AnalysisContextCollection(
        includedPaths: [root],
        resourceProvider: resourceProvider,
      );

      var errors = <AnalysisErrorInfo>[];

      for (var context in collection.contexts) {
        // Add lints.
        var options = context.analysisOptions as AnalysisOptionsImpl;
        options.lintRules = context.analysisOptions.lintRules.toList();
        lints.forEach(options.lintRules.add);
        options.lint = true;

        for (var filePath in context.contextRoot.analyzedFiles()) {
          if (isDartFileName(filePath)) {
            try {
              var result = await context.currentSession.getErrors(filePath);
              if (result is ErrorsResult) {
                var filtered = result.errors
                    .where((e) => e.errorCode.name != 'TODO')
                    .toList();
                if (filtered.isNotEmpty) {
                  errors.add(AnalysisErrorInfoImpl(filtered, result.lineInfo));
                }
              }
            } on Exception catch (e) {
              _print('Exception caught analyzing: $filePath');
              _print(e.toString());
            }
          }
        }
      }
      ReportFormatter(
              errors, null /*_TodoFilter()*/, silent ? MockIOSink() : io.stdout)
          .write();

      for (var info in errors) {
        failedChecks.addAll(info.errors);
      }
    }

    return failedChecks.toList();
  }

  /// Pass the following [msg] to the [logger] instance iff [silent] is false.
  void _print(String msg) {
    if (!silent) {
      logger.stdout(msg);
    }
  }

  /// Returns `true` if this [fileName] is a Dart file.
  static bool isDartFileName(String fileName) => fileName.endsWith('.dart');
}
