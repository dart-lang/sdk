// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as path;

import '../../test/mocks.dart';
import '../util/formatter.dart';
import 'rules/no_solo_tests.dart';
import 'rules/no_trailing_spaces.dart';
import 'rules/visit_registered_nodes.dart';

Future<void> main() async {
  var results = await runChecks();
  if (results.isNotEmpty) {
    io.exitCode = 3;
  }
}

var customChecks = [VisitRegisteredNodes(), NoSoloTests(), NoTrailingSpaces()];

Future<List<Diagnostic>> runChecks() async {
  var rules = path.normalize(
    io.File(path.join('lib', 'src', 'rules')).absolute.path,
  );
  var tests = path.normalize(io.File(path.join('test')).absolute.path);
  var results = await Driver(customChecks).analyze([rules, tests]);
  return results;
}

class Driver {
  Logger logger = Logger.standard();

  final List<AnalysisRule> lints;
  final bool silent;

  Driver(this.lints, {this.silent = true});

  Future<List<Diagnostic>> analyze(List<String> sources) async {
    if (sources.isEmpty) {
      _print('Specify one or more files and directories.');
      return [];
    }
    ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
    var failedChecks = await _analyzeFiles(resourceProvider, sources);
    _print('Finished.');
    return failedChecks;
  }

  Future<List<Diagnostic>> _analyzeFiles(
    ResourceProvider resourceProvider,
    List<String> analysisRoots,
  ) async {
    _print('Analyzing...');

    // Register our checks.
    lints.forEach(Registry.ruleRegistry.registerLintRule);

    // Track failures.
    var failedChecks = <Diagnostic>{};

    for (var root in analysisRoots) {
      var collection = AnalysisContextCollection(
        includedPaths: [root],
        resourceProvider: resourceProvider,
      );

      var diagnostics = <Diagnostic>[];

      for (var context in collection.contexts) {
        // Add lints.
        var allOptions =
            (context as DriverBasedAnalysisContext).allAnalysisOptions;
        for (var options in allOptions) {
          options as AnalysisOptionsImpl;
          options.lintRules = [...options.lintRules, ...lints];
          options.lint = true;
        }

        for (var filePath in context.contextRoot.analyzedFiles()) {
          if (isDartFileName(filePath)) {
            try {
              var result = await context.currentSession.getErrors(filePath);
              if (result is ErrorsResult) {
                diagnostics.addAll(result.diagnostics);
              }
            } on Exception catch (e) {
              _print('Exception caught analyzing: $filePath');
              _print(e.toString());
            }
          }
        }
      }
      ReportFormatter(diagnostics, silent ? MockIOSink() : io.stdout).write();

      failedChecks.addAll(diagnostics);
    }

    // Unregister our checks.
    lints.forEach(Registry.ruleRegistry.unregisterLintRule);

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
