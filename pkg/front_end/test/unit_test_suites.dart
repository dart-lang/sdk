// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

import 'dartdoctest_suite.dart' as dartdoctest show createContext;
import 'fasta/expression_suite.dart' as expression show createContext;
import 'fasta/incremental_dartino_suite.dart' as incremental_dartino
    show createContext;
import 'fasta/messages_suite.dart' as messages show createContext;
import 'fasta/modular_suite.dart' as modular show createContext;
import 'fasta/outline_suite.dart' as outline show createContext;
import 'fasta/strong_suite.dart' as strong show createContext;
import 'fasta/textual_outline_suite.dart' as textual_outline show createContext;
import 'fasta/weak_suite.dart' as weak show createContext;
import 'incremental_bulk_compiler_smoke_suite.dart' as incremental_bulk_compiler
    show createContext;
import 'incremental_suite.dart' as incremental show createContext;
import 'lint_suite.dart' as lint show createContext;
import 'outline_extractor_suite.dart' as outline_extractor show createContext;
import 'parser_all_suite.dart' as parserAll show createContext;
import 'parser_equivalence_suite.dart' as parserEquivalence show createContext;
import 'parser_suite.dart' as parser show createContext;
import 'spelling_test_not_src_suite.dart' as spelling_not_src
    show createContext;
import 'spelling_test_src_suite.dart' as spelling_src show createContext;

const suiteNamePrefix = "pkg/front_end/test";

int getDefaultThreads() {
  int numberOfWorkers = 1;
  if (Platform.numberOfProcessors > 2) {
    numberOfWorkers = Platform.numberOfProcessors - 1;
  }
  return numberOfWorkers;
}

class Options {
  final String? configurationName;
  final bool verbose;
  final bool printFailureLog;
  final Uri outputDirectory;
  final String? testFilter;
  final List<String> environmentOptions;
  final int shardCount;
  final int shard;
  final bool skipTestsThatRequireGit;
  final bool onlyTestsThatRequireGit;
  final int numberOfWorkers;

  Options(
    this.configurationName,
    this.verbose,
    this.printFailureLog,
    this.outputDirectory,
    this.testFilter,
    this.environmentOptions, {
    required this.shardCount,
    required this.shard,
    required this.skipTestsThatRequireGit,
    required this.onlyTestsThatRequireGit,
    required this.numberOfWorkers,
  });

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
          abbr: 'D', help: "environment options for the test suite")
      ..addOption("tasks",
          abbr: "j",
          help: "The number of parallel tasks to run.",
          defaultsTo: "${getDefaultThreads()}")
      ..addOption("shards", help: "Number of shards", defaultsTo: "1")
      ..addOption("shard", help: "Which shard to run", defaultsTo: "1")
      ..addFlag("skipTestsThatRequireGit",
          help: "Whether to skip tests that require git to run",
          defaultsTo: false)
      ..addFlag("onlyTestsThatRequireGit",
          help: "Whether to only run tests that require git",
          defaultsTo: false);
    var parsedOptions = parser.parse(args);
    String outputPath = parsedOptions["output-directory"] ?? ".";
    Uri outputDirectory = Uri.base.resolveUri(Uri.directory(outputPath));

    bool verbose = parsedOptions["verbose"];

    String? filter;
    if (parsedOptions.rest.length == 1) {
      filter = parsedOptions.rest.single;
      if (filter.startsWith("$suiteNamePrefix/")) {
        filter = filter.substring(suiteNamePrefix.length + 1);
      }
    }
    String tasksString = parsedOptions["tasks"];
    int? tasks = int.tryParse(tasksString);
    if (tasks == null || tasks < 1) {
      throw "--tasks (-j) has to be an integer >= 1";
    }

    String shardsString = parsedOptions["shards"];
    int? shardCount = int.tryParse(shardsString);
    if (shardCount == null || shardCount < 1) {
      throw "--shards has to be an integer >= 1";
    }
    String shardString = parsedOptions["shard"];
    int? shard = int.tryParse(shardString);
    if (shard == null || shard < 1 || shard > shardCount) {
      throw "--shard has to be an integer >= 1 (and <= --shards)";
    }
    bool skipTestsThatRequireGit = parsedOptions["skipTestsThatRequireGit"];
    bool onlyTestsThatRequireGit = parsedOptions["onlyTestsThatRequireGit"];
    if (skipTestsThatRequireGit && onlyTestsThatRequireGit) {
      throw "Only one of --skipTestsThatRequireGit and "
          "--onlyTestsThatRequireGit can be provided.";
    }

    if (verbose) {
      print("NOTE: Created with options\n  "
          "${parsedOptions["named-configuration"]},\n  "
          "${verbose},\n  "
          "${parsedOptions["print"]},\n  "
          "${outputDirectory},\n  "
          "${filter},\n  "
          "${parsedOptions['environment']},\n  "
          "shardCount: ${shardCount},\n  "
          "shard: ${shard - 1 /* make it 0-indexed */},\n  "
          "onlyTestsThatRequireGit: ${onlyTestsThatRequireGit},\n  "
          "skipTestsThatRequireGit: ${skipTestsThatRequireGit},\n  "
          "numberOfWorkers: ${tasks}");
    }

    return Options(
      parsedOptions["named-configuration"],
      verbose,
      parsedOptions["print"],
      outputDirectory,
      filter,
      parsedOptions['environment'],
      shardCount: shardCount,
      shard: shard - 1 /* make it 0-indexed */,
      onlyTestsThatRequireGit: onlyTestsThatRequireGit,
      skipTestsThatRequireGit: skipTestsThatRequireGit,
      numberOfWorkers: tasks,
    );
  }
}

class ResultLogger implements Logger {
  final String prefix;
  final bool verbose;
  final bool printFailureLog;
  final SendPort resultsPort;
  final SendPort logsPort;
  final Map<String, Stopwatch> stopwatches = {};
  final String? configurationName;
  final Set<String> seenTests = {};
  bool gotFrameworkError = false;

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

  void handleTestResult(
      testing.Suite suite,
      TestDescription testDescription,
      Result result,
      String fullSuiteName,
      bool matchedExpectations,
      Set<Expectation> expectedOutcomes) {
    String testName = getTestName(testDescription);
    String suiteName = "pkg";
    String shortTestName = testName.substring(suiteName.length + 1);
    resultsPort.send(jsonEncode({
      "name": testName,
      "configuration": configurationName,
      "suite": suiteName,
      "test_name": shortTestName,
      "time_ms": stopwatches[testName]!.elapsedMilliseconds,
      "expected": "Pass",
      "result": matchedExpectations ? "Pass" : "Fail",
      "matches": matchedExpectations,
    }));
    if (!matchedExpectations) {
      StringBuffer sb = new StringBuffer();
      if (printFailureLog) {
        String outcome = "${result.outcome}";
        sb.write("FAILED: $testName: $outcome");
      }
      sb.write(result.log);
      if (result.error != null) {
        sb.write("\n\n${result.error}");
      }
      if (result.trace != null) {
        sb.write("\n\n${result.trace}");
      }
      sb.write("\n\nTo re-run this test, run:");
      var extraFlags = _assertsEnabled ? ' --enable-asserts' : '';
      sb.write(
          "\n\n   dart$extraFlags pkg/front_end/test/unit_test_suites.dart -p "
          "$testName");
      if (result.autoFixCommand != null) {
        sb.write("\n\nTo automatically update the test expectations, run:");
        sb.write("\n\n   dart pkg/front_end/test/unit_test_suites.dart -p "
            "$testName -D${result.autoFixCommand}");
        if (result.canBeFixWithUpdateExpectations) {
          sb.write('\n\nTo update test expectations for all tests at once, '
              'run:');
          sb.write('\n\n  dart pkg/front_end/tool/update_expectations.dart');
          sb.write('\n\nNote that this takes a long time and should only be '
              'used when many tests need updating.\n');
        }
      }
      if (result.outcome == Expectation.pass) {
        String expectedString =
            expectedOutcomes.map((e) => e.toString()).join(", ");
        sb.write("\n\nThe test passed, but wasn't expected to. "
            "You should update the status file for this test."
            "\nThere's a status entry looking something like"
            "\n\n  ${testDescription.shortName}: ${expectedString}"
            "\n\nwhich should be removed."
            "\n\nThe status file is ${suite.statusFile}.");
      } else if (result.autoFixCommand == null) {
        String expectedString =
            expectedOutcomes.map((e) => e.toString()).join(", ");
        sb.write("\n\nThe test has outcome ${result.outcome}, "
            "but was expected to have outcome(s) ${expectedOutcomes}. "
            "You might have to update the status file to the new outcome"
            "\nThere's a status entry looking something like"
            "\n\n  ${testDescription.shortName}: ${expectedString}"
            "\n\nwhich should be updated."
            "\n\nThe status file is ${suite.statusFile}.");
      }
      String failureLog = sb.toString();
      String outcome = "${result.outcome}";
      logsPort.send(jsonEncode({
        "name": testName,
        "configuration": configurationName,
        "result": outcome,
        "log": failureLog,
      }));
      if (printFailureLog) {
        print(failureLog);
      }
    }
    if (verbose) {
      String result = matchedExpectations ? "PASS" : "FAIL";
      print("${testName}: ${result}");
    }
  }

  @override
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

  @override
  void logExpectedResult(testing.Suite suite, TestDescription description,
      Result result, Set<Expectation> expectedOutcomes) {
    handleTestResult(
        suite, description, result, prefix, true, expectedOutcomes);
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
    handleTestResult(
        suite, description, result, prefix, false, expectedOutcomes);
  }

  @override
  void noticeFrameworkCatchError(error, StackTrace stackTrace) {
    gotFrameworkError = true;
  }
}

class Suite {
  final CreateContext createContext;
  final String testingRootPath;
  final String? path;
  final int shardCount;
  final String prefix;
  final bool requiresGit;

  const Suite(
    this.prefix,
    this.createContext,
    this.testingRootPath, {
    required this.shardCount,
    this.path,
    this.requiresGit = false,
  });
}

const List<Suite> suites = [
  const Suite(
    "dartdoctest",
    dartdoctest.createContext,
    "../testing.json",
    shardCount: 1,
  ),
  const Suite(
    "fasta/expression",
    expression.createContext,
    "../../testing.json",
    shardCount: 1,
  ),
  const Suite(
    "fasta/outline",
    outline.createContext,
    "../../testing.json",
    shardCount: 2,
  ),
  const Suite(
    "fasta/incremental_dartino",
    incremental_dartino.createContext,
    "../../testing.json",
    shardCount: 1,
  ),
  const Suite(
    "fasta/messages",
    messages.createContext,
    "../../testing.json",
    shardCount: 1,
    requiresGit: true,
  ),
  const Suite(
    "fasta/strong",
    strong.createContext,
    "../../testing.json",
    path: "fasta/strong_suite.dart",
    shardCount: 2,
  ),
  const Suite(
    "incremental_bulk_compiler_smoke",
    incremental_bulk_compiler.createContext,
    "../testing.json",
    shardCount: 1,
  ),
  const Suite(
    "incremental",
    incremental.createContext,
    "../testing.json",
    shardCount: 2,
  ),
  const Suite(
    "lint",
    lint.createContext,
    "../testing.json",
    shardCount: 1,
    requiresGit: true,
  ),
  const Suite(
    "parser",
    parser.createContext,
    "../testing.json",
    shardCount: 1,
  ),
  const Suite(
    "parser_equivalence",
    parserEquivalence.createContext,
    "../testing.json",
    shardCount: 1,
  ),
  const Suite(
    "parser_all",
    parserAll.createContext,
    "../testing.json",
    shardCount: 4,
    requiresGit:
        true /* technically not true, but tests *many* more files
         than in test_matrix.json file set */
    ,
  ),
  const Suite(
    "spelling_test_not_src",
    spelling_not_src.createContext,
    "../testing.json",
    shardCount: 1,
    requiresGit: true,
  ),
  const Suite(
    "spelling_test_src",
    spelling_src.createContext,
    "../testing.json",
    shardCount: 1,
    requiresGit: true,
  ),
  const Suite(
    "fasta/modular",
    modular.createContext,
    "../../testing.json",
    path: "fasta/modular_suite.dart",
    shardCount: 4,
  ),
  const Suite(
    "fasta/weak",
    weak.createContext,
    "../../testing.json",
    path: "fasta/weak_suite.dart",
    shardCount: 10,
  ),
  const Suite(
    "fasta/textual_outline",
    textual_outline.createContext,
    "../../testing.json",
    shardCount: 1,
  ),
  const Suite(
    "outline_extractor",
    outline_extractor.createContext,
    "../testing.json",
    shardCount: 1,
  ),
];

const Duration timeoutDuration = Duration(minutes: 30);

class SuiteConfiguration {
  final Suite suite;
  final SendPort resultsPort;
  final SendPort logsPort;
  final bool verbose;
  final bool printFailureLog;
  final String? configurationName;
  final String? testFilter;
  final List<String> environmentOptions;
  final int shard;

  const SuiteConfiguration(
    this.suite,
    this.resultsPort,
    this.logsPort,
    this.verbose,
    this.printFailureLog,
    this.configurationName,
    this.testFilter,
    this.environmentOptions,
    this.shard,
  );
}

Future<void> runSuite(SuiteConfiguration configuration) async {
  Suite suite = configuration.suite;
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
  await runMe(
    <String>[
      if (configuration.testFilter != null) configuration.testFilter!,
      for (String option in configuration.environmentOptions) '-D${option}',
    ],
    suite.createContext,
    me: suiteUri,
    configurationPath: suite.testingRootPath,
    logger: logger,
    shards: suite.shardCount,
    shard: configuration.shard,
  );
  if (logger.gotFrameworkError) {
    throw "Got framework error!";
  }
}

Future<void> writeLinesToFile(Uri uri, List<String> lines) async {
  await File.fromUri(uri).writeAsString(lines.map((line) => "$line\n").join());
}

Future<void> main([List<String> arguments = const <String>[]]) async {
  Stopwatch totalRuntime = new Stopwatch()..start();

  List<String> results = [];
  List<String> logs = [];
  Options options = Options.parse(arguments);
  ReceivePort resultsPort = new ReceivePort()
    ..listen((resultEntry) => results.add(resultEntry));
  ReceivePort logsPort = new ReceivePort()
    ..listen((logEntry) => logs.add(logEntry));
  List<Future<bool>> futures = [];

  if (options.verbose) {
    print("NOTE: Willing to run with ${options.numberOfWorkers} 'workers'");
    print("");
  }

  int numberOfFreeWorkers = options.numberOfWorkers;
  // Run test suites and record the results and possible failure logs.
  int chunkNum = 0;
  for (Suite suite in suites) {
    if (options.onlyTestsThatRequireGit && !suite.requiresGit) continue;
    if (options.skipTestsThatRequireGit && suite.requiresGit) continue;
    String prefix = suite.prefix;
    String? filter = options.testFilter;
    if (filter != null) {
      // Skip suites that are not hit by the test filter, is there is one.
      if (!filter.startsWith(prefix)) {
        continue;
      }
      // Remove the 'fasta/' from filters, if there, because it is not used
      // in the name defined in testing.json.
      if (filter.startsWith("fasta/")) {
        filter = filter.substring("fasta/".length);
      }
    }
    for (int shard = 0; shard < suite.shardCount; shard++) {
      if (chunkNum++ % options.shardCount != options.shard) continue;

      while (numberOfFreeWorkers <= 0) {
        // This might not be great design, but it'll work fine.
        await Future.delayed(const Duration(milliseconds: 50));
      }
      numberOfFreeWorkers--;
      // Start the test suite in a new isolate.
      ReceivePort exitPort = new ReceivePort();
      ReceivePort errorPort = new ReceivePort();
      SuiteConfiguration configuration = new SuiteConfiguration(
          suite,
          resultsPort.sendPort,
          logsPort.sendPort,
          options.verbose,
          options.printFailureLog,
          options.configurationName,
          filter,
          options.environmentOptions,
          shard);
      Future<bool> future = new Future<bool>(() async {
        try {
          Stopwatch stopwatch = new Stopwatch()..start();
          String naming = "$prefix";
          if (suite.shardCount > 1) {
            naming += " (${shard + 1} of ${suite.shardCount})";
          }
          print("Running suite $naming");
          Isolate isolate = await Isolate.spawn<SuiteConfiguration>(
              runSuite, configuration,
              onExit: exitPort.sendPort, onError: errorPort.sendPort);
          bool timedOutOrCrash = false;
          Timer timer = new Timer(timeoutDuration, () {
            timedOutOrCrash = true;
            print("Suite $naming timed out after "
                "${timeoutDuration.inMilliseconds}ms");
            isolate.kill(priority: Isolate.immediate);
          });
          await exitPort.first;
          errorPort.close();
          List<dynamic> allErrors = await errorPort.toList();
          bool gotError = allErrors.isNotEmpty;
          if (gotError) {
            print("Suite $naming encountered ${allErrors.length} error(s).");
            print("Errors:");
            for (int i = 0; i < allErrors.length; i++) {
              print("-----------");
              print("Error #$i:");
              print(allErrors[i]);
            }
            print("-----------");
            timedOutOrCrash = true;
          }
          timer.cancel();
          int seconds = stopwatch.elapsedMilliseconds ~/ 1000;
          if (!timedOutOrCrash) {
            print("Suite $naming finished (took ${seconds} seconds)");
          } else {
            print("Suite $naming finished badly (see above) "
                "(took ${seconds} seconds)");
          }
          return timedOutOrCrash;
        } finally {
          numberOfFreeWorkers++;
        }
      });
      futures.add(future);
    }
  }
  // Wait for isolates to terminate and clean up.
  Iterable<bool> timeoutsOrCrashes = await Future.wait(futures);
  resultsPort.close();
  logsPort.close();
  // Write results.json and logs.json.
  Uri resultJsonUri = options.outputDirectory.resolve("results.json");
  Uri logsJsonUri = options.outputDirectory.resolve("logs.json");
  await writeLinesToFile(resultJsonUri, results);
  await writeLinesToFile(logsJsonUri, logs);
  print("Log files written to ${resultJsonUri.toFilePath()} and"
      " ${logsJsonUri.toFilePath()}");
  print("Entire run took ${totalRuntime.elapsed}.");
  // Return with exit code 1 if at least one suite timed out.
  bool timedOutOrCrashed = timeoutsOrCrashes.any((timeout) => timeout);
  if (timedOutOrCrashed) {
    throw "Crashed or timed out. Check stdout for more details.";
  } else {
    // The testing framework (package:testing) sets the exitCode to `1` if any
    // test failed, so we reset it here to indicate that the test runner was
    // successful.
    exitCode = 0;
  }
}

final bool _assertsEnabled = () {
  bool assertsEnabled = false;
  assert(assertsEnabled = true);
  return assertsEnabled;
}();
