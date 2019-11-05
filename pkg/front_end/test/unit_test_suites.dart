// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'dart:async' show Timer;
import 'dart:convert' show jsonEncode;
import 'dart:io' show File, Platform, exitCode;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;

import 'package:args/args.dart' show ArgParser;

import 'package:testing/src/chain.dart' show CreateContext, Result, Step;
import 'package:testing/src/expectation.dart' show Expectation;
import 'package:testing/src/log.dart' show Logger;
import 'package:testing/src/run.dart' show runMe;
import 'package:testing/src/suite.dart' as testing show Suite;
import 'package:testing/src/test_description.dart' show TestDescription;

import 'fasta/expression_suite.dart' as expression show createContext;
import 'fasta/outline_suite.dart' as outline show createContext;
import 'fasta/fast_strong_suite.dart' as fast_strong show createContext;
import 'fasta/incremental_suite.dart' as incremental show createContext;
import 'fasta/messages_suite.dart' as messages show createContext;
import 'fasta/strong_tester.dart' as strong show createContext;
import 'fasta/text_serialization_suite.dart' as text_serialization
    show createContext;
import 'fasta/type_promotion_look_ahead_suite.dart' as type_promotion
    show createContext;
import 'incremental_bulk_compiler_smoke_suite.dart' as incremental_bulk_compiler
    show createContext;
import 'incremental_load_from_dill_suite.dart' as incremental_load
    show createContext;
import 'lint_suite.dart' as lint show createContext;
import 'old_dill_suite.dart' as old_dill show createContext;
import 'parser_suite.dart' as parser show createContext;
import 'spelling_test_not_src_suite.dart' as spelling_not_src
    show createContext;
import 'spelling_test_src_suite.dart' as spelling_src show createContext;

class Options {
  final String configurationName;
  final bool verbose;
  final Uri outputDirectory;

  Options(this.configurationName, this.verbose, this.outputDirectory);

  static Options parse(List<String> args) {
    var parser = new ArgParser()
      ..addOption("named-configuration",
          abbr: "n",
          help: "configuration name to use for emitting json result files")
      ..addOption("output-directory",
          help: "directory to which results.json and logs.json are written")
      ..addFlag("verbose",
          abbr: "v", help: "print additional information", defaultsTo: false);
    var parsedArguments = parser.parse(args);
    String outputPath = parsedArguments["output-directory"] ?? ".";
    Uri outputDirectory = Uri.base.resolveUri(Uri.directory(outputPath));
    return Options(parsedArguments["named-configuration"],
        parsedArguments["verbose"], outputDirectory);
  }
}

class ResultLogger implements Logger {
  final String suiteName;
  final String prefix;
  final bool verbose;
  final SendPort resultsPort;
  final SendPort logsPort;
  final Map<String, Stopwatch> stopwatches = {};
  final String configurationName;
  final Set<String> seenTests = {};

  ResultLogger(this.suiteName, this.prefix, this.resultsPort, this.logsPort,
      this.verbose, this.configurationName);

  String getTestName(TestDescription description) {
    return "$prefix/${description.shortName}";
  }

  @override
  void logMessage(Object message) {}

  @override
  void logNumberedLines(String text) {}

  @override
  void logProgress(String message) {}

  @override
  void logStepComplete(int completed, int failed, int total,
      testing.Suite suite, TestDescription description, Step step) {}

  @override
  void logStepStart(int completed, int failed, int total, testing.Suite suite,
      TestDescription description, Step step) {}

  @override
  void logSuiteStarted(testing.Suite suite) {}

  @override
  void logSuiteComplete(testing.Suite suite) {}

  handleTestResult(TestDescription testDescription, Result result,
      String fullSuiteName, bool matchedExpectations) {
    String testName = getTestName(testDescription);
    String suite = "pkg";
    String shortTestName = testName.substring(suite.length + 1);
    resultsPort.send(jsonEncode({
      "name": testName,
      "configuration": configurationName,
      "suite": suite,
      "test_name": shortTestName,
      "time_ms": stopwatches[testName].elapsedMilliseconds,
      "expected": "Pass",
      "result": matchedExpectations ? "Pass" : "Fail",
      "matches": matchedExpectations,
    }));
    if (!matchedExpectations) {
      String failureLog = result.log;
      if (result.error != null) {
        failureLog = "$failureLog\n\n${result.error}";
      }
      if (result.trace != null) {
        failureLog = "$failureLog\n\n${result.trace}";
      }
      String outcome = "${result.outcome}";
      logsPort.send(jsonEncode({
        "name": testName,
        "configuration": configurationName,
        "result": outcome,
        "log": failureLog,
      }));
    }
    if (verbose) {
      String result = matchedExpectations ? "PASS" : "FAIL";
      print("${testName}: ${result}");
    }
  }

  void logTestStart(int completed, int failed, int total, testing.Suite suite,
      TestDescription description) {
    String name = getTestName(description);
    stopwatches[name] = Stopwatch()..start();
  }

  @override
  void logTestComplete(int completed, int failed, int total,
      testing.Suite suite, TestDescription description) {}

  @override
  void logUncaughtError(error, StackTrace stackTrace) {}

  void logExpectedResult(testing.Suite suite, TestDescription description,
      Result result, Set<Expectation> expectedOutcomes) {
    handleTestResult(description, result, prefix, true);
  }

  @override
  void logUnexpectedResult(testing.Suite suite, TestDescription description,
      Result result, Set<Expectation> expectedOutcomes) {
    // The test framework (pkg/testing) calls the logger with an unexpected
    // results a second time to create a summary. We ignore the second call
    // here.
    String testName = getTestName(description);
    if (seenTests.contains(testName)) return;
    seenTests.add(testName);
    handleTestResult(description, result, prefix, false);
  }
}

class Suite {
  final String name;
  final CreateContext createContext;
  final String testingRootPath;
  final String path;
  final int shardCount;
  final int shard;

  const Suite(this.name, this.createContext, this.testingRootPath,
      {this.path, this.shardCount: 1, this.shard: 0});
}

final List<Suite> suites = [
  const Suite(
      "fasta/expression", expression.createContext, "../../testing.json"),
  const Suite("fasta/outline", outline.createContext, "../../testing.json"),
  const Suite(
      "fasta/fast_strong", fast_strong.createContext, "../../testing.json"),
  const Suite(
      "fasta/incremental", incremental.createContext, "../../testing.json"),
  const Suite("fasta/messages", messages.createContext, "../../testing.json"),
  const Suite("fasta/text_serialization", text_serialization.createContext,
      "../../testing.json"),
  const Suite("fasta/strong1", strong.createContext, "../../testing.json",
      path: "fasta/strong_tester.dart", shardCount: 4, shard: 0),
  const Suite("fasta/strong2", strong.createContext, "../../testing.json",
      path: "fasta/strong_tester.dart", shardCount: 4, shard: 1),
  const Suite("fasta/strong3", strong.createContext, "../../testing.json",
      path: "fasta/strong_tester.dart", shardCount: 4, shard: 2),
  const Suite("fasta/strong4", strong.createContext, "../../testing.json",
      path: "fasta/strong_tester.dart", shardCount: 4, shard: 3),
  const Suite("fasta/type_promotion_look_ahead", type_promotion.createContext,
      "../../testing.json"),
  const Suite("incremental_bulk_compiler_smoke",
      incremental_bulk_compiler.createContext, "../testing.json"),
  const Suite("incremental_load_from_dill", incremental_load.createContext,
      "../testing.json"),
  const Suite("lint", lint.createContext, "../testing.json"),
  const Suite("old_dill", old_dill.createContext, "../testing.json"),
  const Suite("parser", parser.createContext, "../testing.json"),
  const Suite("spelling_test_not_src", spelling_not_src.createContext,
      "../testing.json"),
  const Suite(
      "spelling_test_src", spelling_src.createContext, "../testing.json"),
];

const Duration timeoutDuration = Duration(minutes: 10);

class SuiteConfiguration {
  final String name;
  final SendPort resultsPort;
  final SendPort logsPort;
  final bool verbose;
  final String configurationName;
  const SuiteConfiguration(this.name, this.resultsPort, this.logsPort,
      this.verbose, this.configurationName);
}

void runSuite(SuiteConfiguration configuration) {
  Suite suite = suites.where((s) => s.name == configuration.name).single;
  String name = suite.name;
  String fullSuiteName = "pkg/front_end/test/$name";
  Uri suiteUri = Platform.script.resolve(suite.path ?? "${name}_suite.dart");
  ResultLogger logger = ResultLogger(
      name,
      fullSuiteName,
      configuration.resultsPort,
      configuration.logsPort,
      configuration.verbose,
      configuration.configurationName);
  runMe(<String>[], suite.createContext,
      me: suiteUri,
      configurationPath: suite.testingRootPath,
      logger: logger,
      shards: suite.shardCount,
      shard: suite.shard);
}

void writeLinesToFile(Uri uri, List<String> lines) async {
  await File.fromUri(uri).writeAsString(lines.map((line) => "$line\n").join());
}

main([List<String> arguments = const <String>[]]) async {
  List<String> results = [];
  List<String> logs = [];
  Options options = Options.parse(arguments);
  ReceivePort resultsPort = new ReceivePort()
    ..listen((resultEntry) => results.add(resultEntry));
  ReceivePort logsPort = new ReceivePort()
    ..listen((logEntry) => logs.add(logEntry));
  List<Future<bool>> futures = [];
  // Run test suites and record the results and possible failure logs.
  for (Suite suite in suites) {
    // Start the test suite in a new isolate.
    ReceivePort exitPort = new ReceivePort();
    String name = suite.name;
    SuiteConfiguration configuration = SuiteConfiguration(
        name,
        resultsPort.sendPort,
        logsPort.sendPort,
        options.verbose,
        options.configurationName);
    Future future = Future<bool>(() async {
      Stopwatch stopwatch = Stopwatch()..start();
      print("Running suite $name");
      // TODO(karlklose): Implement --filter to select tests to run
      // to implement deflaking (dartbug.com/38607).
      Isolate isolate = await Isolate.spawn<SuiteConfiguration>(
          runSuite, configuration,
          onExit: exitPort.sendPort);
      bool timedOut = false;
      Timer timer = Timer(timeoutDuration, () {
        timedOut = true;
        print("Suite $name timed out after "
            "${timeoutDuration.inMilliseconds}ms");
        isolate.kill(priority: Isolate.immediate);
      });
      await exitPort.first;
      timer.cancel();
      if (!timedOut) {
        print(
            "Suite $name finished (took ${stopwatch.elapsedMilliseconds}ms).");
      }
      return timedOut;
    });
    futures.add(future);
  }
  // Wait for isolates to terminate and clean up.
  Iterable<bool> timeouts = await Future.wait(futures);
  resultsPort.close();
  logsPort.close();
  // Write results.json and logs.json.
  Uri resultJsonUri = options.outputDirectory.resolve("results.json");
  Uri logsJsonUri = options.outputDirectory.resolve("logs.json");
  await writeLinesToFile(resultJsonUri, results);
  await writeLinesToFile(logsJsonUri, logs);
  print("Log files written to ${resultJsonUri.toFilePath()} and"
      " ${logsJsonUri.toFilePath()}");
  // Return with exit code 1 if at least one suite timed out.
  bool timeout = timeouts.any((timeout) => timeout);
  if (timeout) {
    exitCode = 1;
  } else {
    // The testing framework (pkg/testing) sets the exitCode to 1 if any test
    // failed, so we reset it here to indicate that the test runner was
    // successful.
    exitCode = 0;
  }
}
