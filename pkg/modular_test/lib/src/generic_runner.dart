// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A generic test runner that executes a list of tests, logs test results, and
/// adds sharding support.
///
/// This library contains no logic related to the modular_test framework. It is
/// used to help integrate tests with our test infrastructure.
// TODO(sigmund): this library should move somewhere else.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A generic test.
abstract class Test {
  /// Unique test name.
  String get name;

  /// Run the actual test.
  Future<void> run();
}

class RunnerOptions {
  /// Name of the test suite being run.
  String suiteName;

  /// Configuration name to use when writing result logs.
  String configurationName;

  /// Filter used to only run tests that match the filter name.
  String filter;

  /// Where log files are emitted.
  ///
  /// Note that all shards currently emit the same filenames, so two shards
  /// shouldn't be given the same [logDir] otherwise they will overwrite each
  /// other's log files.
  Uri logDir;

  /// Of [shards], which shard is currently being executed.
  int shard;

  /// How many shards will be used to run a suite.
  int shards;

  /// Whether to print verbose information.
  bool verbose;

  /// Template used to help developers reproduce the issue.
  ///
  /// The following substitutions are made:
  ///   * %executable is replaced with `Platform.executable`
  ///   * %script is replaced with the current `Platform.script`
  ///   * %name is replaced with the test name.
  String reproTemplate;
}

class _TestOutcome {
  /// Unique test name.
  String name;

  /// Whether, after running the test, the test matches its expectations. Null
  /// before the test is executed.
  bool matchedExpectations;

  /// Additional output emitted by the test, only used when expectations don't
  /// match and more details need to be provided.
  String output;

  /// Time used to run the test.
  Duration elapsedTime;
}

Future<void> runSuite<T>(List<Test> tests, RunnerOptions options) async {
  if (options.filter == null) {
    if (options.logDir == null) {
      print('warning: no output directory provided, logs wont be emitted.');
    }
    if (options.configurationName == null) {
      print('warning: please provide a configuration name.');
    }
  }
  var sortedTests = tests.toList()..sort((a, b) => a.name.compareTo(b.name));
  List<_TestOutcome> testOutcomes = [];
  int shard = options.shard;
  int shards = options.shards;
  for (int i = 0; i < sortedTests.length; i++) {
    if (shards > 1 && i % shards != shard) continue;
    var test = sortedTests[i];
    var name = test.name;
    if (options.verbose) stdout.write('$name: ');
    if (options.filter != null && !name.contains(options.filter)) {
      if (options.verbose) stdout.write('skipped\n');
      continue;
    }

    var watch = new Stopwatch()..start();
    var outcome = new _TestOutcome()..name = test.name;
    try {
      await test.run();
      if (options.verbose) stdout.write('pass\n');
      outcome.matchedExpectations = true;
    } catch (e, st) {
      var repro = options.reproTemplate
          .replaceAll('%executable', Platform.resolvedExecutable)
          .replaceAll('%script', Platform.script.path)
          .replaceAll('%name', test.name);
      outcome.matchedExpectations = false;
      outcome.output = 'uncaught exception: $e\n$st\nTo repro run:\n  $repro';
      if (options.verbose) stdout.write('fail\n${outcome.output}');
    }
    watch.stop();
    outcome.elapsedTime = watch.elapsed;
    testOutcomes.add(outcome);
  }

  if (options.logDir == null) {
    // TODO(sigmund): delete. This is only added to ensure the bots show test
    // failures until support for `--output-directory` is added to the test
    // matrix.
    if (testOutcomes.any((o) => !o.matchedExpectations)) {
      exitCode = 1;
    }
    return;
  }

  List<String> results = [];
  List<String> logs = [];
  for (int i = 0; i < testOutcomes.length; i++) {
    var test = testOutcomes[i];
    final record = jsonEncode({
      'name': '${options.suiteName}/${test.name}',
      'configuration': options.configurationName,
      'suite': options.suiteName,
      'test_name': test.name,
      'time_ms': test.elapsedTime.inMilliseconds,
      'expected': 'Pass',
      'result': test.matchedExpectations ? 'Pass' : 'Fail',
      'matches': test.matchedExpectations,
    });
    results.add(record);
    if (!test.matchedExpectations) {
      final log = jsonEncode({
        'name': '${options.suiteName}/${test.name}',
        'configuration': options.configurationName,
        'result': test.matchedExpectations ? 'Pass' : 'Fail',
        'log': test.output,
      });
      logs.add(log);
    }
  }

  // Ensure the directory URI ends with a path separator.
  var logDir = Directory.fromUri(options.logDir).uri;
  var resultJsonUri = logDir.resolve('results.json');
  var logsJsonUri = logDir.resolve('logs.json');
  File.fromUri(resultJsonUri)
      .writeAsStringSync(results.map((s) => '$s\n').join(), flush: true);
  File.fromUri(logsJsonUri)
      .writeAsStringSync(logs.map((s) => '$s\n').join(), flush: true);
  print('log files emitted to ${resultJsonUri} and ${logsJsonUri}');
}
