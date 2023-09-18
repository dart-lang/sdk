// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show StreamSubscription, Timer;
import 'dart:convert' show jsonEncode;
import 'dart:io' show File, exitCode;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;

import 'package:args/args.dart' show ArgParser;

import "frontend_server_flutter.dart" show Logger, compileTests;

const suiteNamePrefix = "flutter_frontend";

class Options {
  final String configurationName;
  final bool verbose;
  final bool printFailureLog;
  final Uri outputDirectory;
  final String? testFilter;
  final String flutterDir;
  final String flutterPlatformDir;

  Options(
      this.configurationName,
      this.verbose,
      this.printFailureLog,
      this.outputDirectory,
      this.testFilter,
      this.flutterDir,
      this.flutterPlatformDir);

  static Options parse(List<String> args) {
    var parser = ArgParser()
      ..addOption("named-configuration",
          abbr: "n",
          defaultsTo: suiteNamePrefix,
          help: "configuration name to use for emitting json result files")
      ..addOption("output-directory",
          help: "directory to which results.json and logs.json are written")
      ..addFlag("verbose",
          abbr: "v", help: "print additional information", defaultsTo: false)
      ..addFlag("print",
          abbr: "p", help: "print failure logs", defaultsTo: false)
      ..addOption("flutterDir")
      ..addOption("flutterPlatformDir");
    var parsedArguments = parser.parse(args);
    String outputPath = parsedArguments["output-directory"] ?? ".";
    Uri outputDirectory = Uri.base.resolveUri(Uri.directory(outputPath));
    String? filter;
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
      parsedArguments["flutterDir"],
      parsedArguments["flutterPlatformDir"],
    );
  }
}

class ResultLogger extends Logger {
  final SuiteConfiguration suiteConfiguration;
  final Map<String, Stopwatch> stopwatches = {};
  final List<String> _log = <String>[];

  ResultLogger(this.suiteConfiguration);

  handleTestResult(String testName, bool matchedExpectations) {
    String fullTestName = "$suiteNamePrefix/$testName";
    suiteConfiguration.resultsPort.send(jsonEncode({
      "name": fullTestName,
      "configuration": suiteConfiguration.configurationName,
      "suite": suiteNamePrefix,
      "test_name": testName,
      "time_ms": stopwatches[testName]!.elapsedMilliseconds,
      "expected": "Pass",
      "result": matchedExpectations ? "Pass" : "Fail",
      "matches": matchedExpectations,
    }));
    if (!matchedExpectations) {
      String failureLog = _log.join("\n");
      failureLog = "$failureLog\n\nRe-run this test: dart --enable-asserts "
          "pkg/frontend_server/test/test.dart "
          "--flutterDir=${suiteConfiguration.flutterDir} "
          "--flutterPlatformDir=${suiteConfiguration.flutterPlatformDir} "
          "-p $testName";
      suiteConfiguration.logsPort.send(jsonEncode({
        "name": fullTestName,
        "configuration": suiteConfiguration.configurationName,
        "result": matchedExpectations ? "OK" : "Failure",
        "log": failureLog,
      }));
      if (suiteConfiguration.printFailureLog) {
        print('FAILED: $fullTestName');
        print(failureLog);
      }
    }
    if (suiteConfiguration.verbose) {
      String result = matchedExpectations ? "PASS" : "FAIL";
      print("$fullTestName: $result");
    }
  }

  @override
  void logTestStart(String testName) {
    stopwatches[testName] = Stopwatch()..start();
    _log.clear();
  }

  @override
  void log(String s) {
    _log.add(s);
  }

  @override
  void notice(String s) {
    // ignored.
  }

  @override
  void logExpectedResult(String testName) {
    handleTestResult(testName, true);
  }

  @override
  void logUnexpectedResult(String testName) {
    handleTestResult(testName, false);
  }
}

const Duration timeoutDuration = Duration(minutes: 45);

class SuiteConfiguration {
  final SendPort resultsPort;
  final SendPort logsPort;
  final bool verbose;
  final bool printFailureLog;
  final String configurationName;
  final String? testFilter;

  final int shard;
  final int shards;

  final String flutterDir;
  final String flutterPlatformDir;

  const SuiteConfiguration(
      this.resultsPort,
      this.logsPort,
      this.verbose,
      this.printFailureLog,
      this.configurationName,
      this.testFilter,
      this.flutterDir,
      this.flutterPlatformDir,
      this.shard,
      this.shards);
}

void runSuite(SuiteConfiguration configuration) async {
  ResultLogger logger = ResultLogger(configuration);
  try {
    await compileTests(
      configuration.flutterDir,
      configuration.flutterPlatformDir,
      logger,
      filter: configuration.testFilter,
      shard: configuration.shard,
      shards: configuration.shards,
    );
  } catch (e) {
    logger.logUnexpectedResult("startup");
  }
}

void writeLinesToFile(Uri uri, List<String> lines) {
  File.fromUri(uri).writeAsStringSync(lines.map((line) => "$line\n").join());
}

main([List<String> arguments = const <String>[]]) async {
  List<String> results = [];
  List<String> logs = [];
  Options options = Options.parse(arguments);
  ReceivePort resultsPort = ReceivePort()
    ..listen((resultEntry) => results.add(resultEntry));
  ReceivePort logsPort = ReceivePort()
    ..listen((logEntry) => logs.add(logEntry));
  String? filter = options.testFilter;

  const int shards = 4;
  List<Future<bool>> futures = [];
  for (int shard = 0; shard < shards; shard++) {
    // Start the test suite in a new isolate.
    ReceivePort exitPort = ReceivePort();
    ReceivePort errorPort = ReceivePort();
    SuiteConfiguration configuration = SuiteConfiguration(
      resultsPort.sendPort,
      logsPort.sendPort,
      options.verbose,
      options.printFailureLog,
      options.configurationName,
      filter,
      options.flutterDir,
      options.flutterPlatformDir,
      shard,
      shards,
    );
    Future<bool> future = Future<bool>(() async {
      Stopwatch stopwatch = Stopwatch()..start();
      print("Running suite shard $shard of $shards");
      Isolate isolate = await Isolate.spawn<SuiteConfiguration>(
          runSuite, configuration,
          onExit: exitPort.sendPort, onError: errorPort.sendPort);
      bool gotError = false;
      StreamSubscription errorSubscription = errorPort.listen((message) {
        print("Got error: $message!");
        gotError = true;
        logs.add("$message");
      });
      bool timedOut = false;
      Timer timer = Timer(timeoutDuration, () {
        timedOut = true;
        print("Suite timed out after "
            "${timeoutDuration.inMilliseconds}ms");
        isolate.kill(priority: Isolate.immediate);
      });
      await exitPort.first;
      await errorSubscription.cancel();
      timer.cancel();
      if (!timedOut && !gotError) {
        int seconds = stopwatch.elapsedMilliseconds ~/ 1000;
        print("Suite finished (shard #$shard) (took $seconds seconds)");
      }
      return timedOut || gotError;
    });
    futures.add(future);
  }

  // Wait for isolate to terminate and clean up.
  Iterable<bool> timeoutsOrCrashes = await Future.wait(futures);
  bool timeoutOrCrash = timeoutsOrCrashes.any((timeout) => timeout);
  resultsPort.close();
  logsPort.close();

  // Write results.json and logs.json.
  Uri resultJsonUri = options.outputDirectory.resolve("results.json");
  Uri logsJsonUri = options.outputDirectory.resolve("logs.json");
  writeLinesToFile(resultJsonUri, results);
  writeLinesToFile(logsJsonUri, logs);
  print("Log files written to ${resultJsonUri.toFilePath()} and"
      " ${logsJsonUri.toFilePath()}");

  exitCode = timeoutOrCrash ? 1 : 0;
}
