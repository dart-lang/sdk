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
import 'fasta/fast_strong_suite.dart' as fast_strong show createContext;
import 'fasta/incremental_suite.dart' as incremental show createContext;
import 'fasta/messages_suite.dart' as messages show createContext;
import 'fasta/outline_suite.dart' as outline show createContext;
import 'fasta/strong_tester.dart' as strong show createContext;
import 'fasta/text_serialization_tester.dart' as text_serialization
    show createContext;
import 'fasta/textual_outline_suite.dart' as textual_outline show createContext;
import 'fasta/weak_suite.dart' as weak show createContext;
import 'incremental_bulk_compiler_smoke_suite.dart' as incremental_bulk_compiler
    show createContext;
import 'incremental_load_from_dill_suite.dart' as incremental_load
    show createContext;
import 'lint_suite.dart' as lint show createContext;
import 'parser_suite.dart' as parser show createContext;
import 'parser_all_suite.dart' as parserAll show createContext;
import 'spelling_test_not_src_suite.dart' as spelling_not_src
    show createContext;
import 'spelling_test_src_suite.dart' as spelling_src show createContext;

const suiteNamePrefix = "pkg/front_end/test";

class Options {
  final String configurationName;
  final bool verbose;
  final bool printFailureLog;
  final Uri outputDirectory;
  final String testFilter;
  final List<String> environmentOptions;

  Options(this.configurationName, this.verbose, this.printFailureLog,
      this.outputDirectory, this.testFilter, this.environmentOptions);

  static Options parse(List<String> args) {
    var parser = new ArgParser()
      ..addOption("named-configuration",
          abbr: "n",
          help: "configuration name to use for emitting json result files")
      ..addOption("output-directory",
          help: "directory to which results.json and logs.json are written")
      ..addFlag("verbose",
          abbr: "v", help: "print additional information", defaultsTo: false)
      ..addFlag("print",
          abbr: "p", help: "print failure logs", defaultsTo: false)
      ..addMultiOption('environment',
          abbr: 'D', help: "environment options for the test suite");
    var parsedArguments = parser.parse(args);
    String outputPath = parsedArguments["output-directory"] ?? ".";
    Uri outputDirectory = Uri.base.resolveUri(Uri.directory(outputPath));
    String filter;
    if (parsedArguments.rest.length == 1) {
      filter = parsedArguments.rest.single;
      if (filter.startsWith("$suiteNamePrefix/")) {
        filter = filter.substring(suiteNamePrefix.length + 1);
      }
    }
    return Options(
        parsedArguments["named-configuration"],
        parsedArguments["verbose"],
        parsedArguments["print"],
        outputDirectory,
        filter,
        parsedArguments['environment']);
  }
}

class ResultLogger implements Logger {
  final String prefix;
  final bool verbose;
  final bool printFailureLog;
  final SendPort resultsPort;
  final SendPort logsPort;
  final Map<String, Stopwatch> stopwatches = {};
  final String configurationName;
  final Set<String> seenTests = {};

  ResultLogger(this.prefix, this.resultsPort, this.logsPort, this.verbose,
      this.printFailureLog, this.configurationName);

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
      if (result.autoFixCommand != null) {
        failureLog = "$failureLog\n\n"
            "To re-run this test, run:\n\n"
            "   dart pkg/front_end/test/unit_test_suites.dart -p $testName\n\n"
            "To automatically update the test expectations, run:\n\n"
            "   dart pkg/front_end/test/unit_test_suites.dart -p $testName "
            "-D${result.autoFixCommand}\n";
      } else {
        failureLog = "$failureLog\n\nRe-run this test: dart "
            "pkg/front_end/test/unit_test_suites.dart -p $testName";
      }
      String outcome = "${result.outcome}";
      logsPort.send(jsonEncode({
        "name": testName,
        "configuration": configurationName,
        "result": outcome,
        "log": failureLog,
      }));
      if (printFailureLog) {
        print('FAILED: $testName: $outcome');
        print(failureLog);
      }
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
  final String prefix;

  const Suite(this.name, this.createContext, this.testingRootPath,
      {this.path, this.shardCount: 1, this.shard: 0, String prefix})
      : prefix = prefix ?? name;
}

const List<Suite> suites = [
  const Suite(
      "fasta/expression", expression.createContext, "../../testing.json"),
  const Suite("fasta/outline", outline.createContext, "../../testing.json"),
  const Suite(
      "fasta/fast_strong", fast_strong.createContext, "../../testing.json"),
  const Suite(
      "fasta/incremental", incremental.createContext, "../../testing.json"),
  const Suite("fasta/messages", messages.createContext, "../../testing.json"),
  const Suite("fasta/text_serialization1", text_serialization.createContext,
      "../../testing.json",
      path: "fasta/text_serialization_tester.dart",
      shardCount: 4,
      shard: 0,
      prefix: "fasta/text_serialization"),
  const Suite("fasta/text_serialization2", text_serialization.createContext,
      "../../testing.json",
      path: "fasta/text_serialization_tester.dart",
      shardCount: 4,
      shard: 1,
      prefix: "fasta/text_serialization"),
  const Suite("fasta/text_serialization3", text_serialization.createContext,
      "../../testing.json",
      path: "fasta/text_serialization_tester.dart",
      shardCount: 4,
      shard: 2,
      prefix: "fasta/text_serialization"),
  const Suite("fasta/text_serialization4", text_serialization.createContext,
      "../../testing.json",
      path: "fasta/text_serialization_tester.dart",
      shardCount: 4,
      shard: 3,
      prefix: "fasta/text_serialization"),
  const Suite("fasta/strong1", strong.createContext, "../../testing.json",
      path: "fasta/strong_tester.dart",
      shardCount: 4,
      shard: 0,
      prefix: "fasta/strong"),
  const Suite("fasta/strong2", strong.createContext, "../../testing.json",
      path: "fasta/strong_tester.dart",
      shardCount: 4,
      shard: 1,
      prefix: "fasta/strong"),
  const Suite("fasta/strong3", strong.createContext, "../../testing.json",
      path: "fasta/strong_tester.dart",
      shardCount: 4,
      shard: 2,
      prefix: "fasta/strong"),
  const Suite("fasta/strong4", strong.createContext, "../../testing.json",
      path: "fasta/strong_tester.dart",
      shardCount: 4,
      shard: 3,
      prefix: "fasta/strong"),
  const Suite("incremental_bulk_compiler_smoke",
      incremental_bulk_compiler.createContext, "../testing.json"),
  const Suite("incremental_load_from_dill", incremental_load.createContext,
      "../testing.json"),
  const Suite("lint", lint.createContext, "../testing.json"),
  const Suite("parser", parser.createContext, "../testing.json"),
  const Suite("parser_all", parserAll.createContext, "../testing.json"),
  const Suite("spelling_test_not_src", spelling_not_src.createContext,
      "../testing.json"),
  const Suite(
      "spelling_test_src", spelling_src.createContext, "../testing.json"),
  const Suite("fasta/weak", weak.createContext, "../../testing.json"),
  const Suite("fasta/textual_outline", textual_outline.createContext,
      "../../testing.json"),
];

const Duration timeoutDuration = Duration(minutes: 30);

class SuiteConfiguration {
  final String name;
  final SendPort resultsPort;
  final SendPort logsPort;
  final bool verbose;
  final bool printFailureLog;
  final String configurationName;
  final String testFilter;
  final List<String> environmentOptions;

  const SuiteConfiguration(
      this.name,
      this.resultsPort,
      this.logsPort,
      this.verbose,
      this.printFailureLog,
      this.configurationName,
      this.testFilter,
      this.environmentOptions);
}

void runSuite(SuiteConfiguration configuration) {
  Suite suite = suites.where((s) => s.name == configuration.name).single;
  String name = suite.prefix;
  String fullSuiteName = "$suiteNamePrefix/$name";
  Uri suiteUri = Platform.script.resolve(suite.path ?? "${name}_suite.dart");
  if (!new File.fromUri(suiteUri).existsSync()) {
    throw "File doesn't exist: $suiteUri";
  }
  ResultLogger logger = ResultLogger(
      fullSuiteName,
      configuration.resultsPort,
      configuration.logsPort,
      configuration.verbose,
      configuration.printFailureLog,
      configuration.configurationName);
  runMe(<String>[
    if (configuration.testFilter != null) configuration.testFilter,
    if (configuration.environmentOptions != null)
      for (String option in configuration.environmentOptions) '-D${option}',
  ], suite.createContext,
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
    String name = suite.name;
    String filter = options.testFilter;
    if (filter != null) {
      // Skip suites that are not hit by the test filter, is there is one.
      if (!filter.startsWith(suite.prefix)) {
        continue;
      }
      // Remove the 'fasta/' from filters, if there, because it is not used
      // in the name defined in testing.json.
      if (filter.startsWith("fasta/")) {
        filter = filter.substring("fasta/".length);
      }
    }
    // Start the test suite in a new isolate.
    ReceivePort exitPort = new ReceivePort();
    SuiteConfiguration configuration = SuiteConfiguration(
        name,
        resultsPort.sendPort,
        logsPort.sendPort,
        options.verbose,
        options.printFailureLog,
        options.configurationName,
        filter,
        options.environmentOptions);
    Future future = Future<bool>(() async {
      Stopwatch stopwatch = Stopwatch()..start();
      print("Running suite $name");
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
        int seconds = stopwatch.elapsedMilliseconds ~/ 1000;
        print("Suite $name finished (took ${seconds} seconds)");
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
    // The testing framework (package:testing) sets the exitCode to `1` if any
    // test failed, so we reset it here to indicate that the test runner was
    // successful.
    exitCode = 0;
  }
}
