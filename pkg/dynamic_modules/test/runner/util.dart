// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities used by various parts of the test harness.
library;

import 'dart:convert';
import 'dart:io';

/// Locate the root of the SDK repository.
///
/// Note: we don't search for the directory "sdk" because this may not be
/// available when running this test in a shard.
Uri repoRoot = (() {
  Uri script = Platform.script;
  var segments = script.pathSegments;
  var index = segments.lastIndexOf('pkg');
  if (index == -1) {
    exitCode = 1;
    throw "error: cannot find the root of the Dart SDK";
  }
  return script.resolve("../" * (segments.length - index - 1));
})();

// Encodes test results in the format expected by Dart's CI infrastructure.
class TestResultOutcome {
  // This encoder must generate each output element on its own line.
  final _encoder = JsonEncoder();
  final String configuration;
  final String suiteName;
  final String testName;
  late Duration elapsedTime;
  final String expectedResult;
  late bool matchedExpectations;
  String testOutput;

  TestResultOutcome({
    required this.configuration,
    this.suiteName = 'dynamic_modules',
    required this.testName,
    this.expectedResult = 'Pass',
    this.testOutput = '',
  });

  String toRecordJson() => _encoder.convert({
        'name': '$suiteName/$testName',
        'configuration': configuration,
        'suite': suiteName,
        'test_name': testName,
        'time_ms': elapsedTime.inMilliseconds,
        'expected': expectedResult,
        'result': matchedExpectations ? 'Pass' : 'Fail',
        'matches': expectedResult == expectedResult,
      });

  String toLogJson() => _encoder.convert({
        'name': '$suiteName/$testName',
        'configuration': configuration,
        'result': matchedExpectations ? 'Pass' : 'Fail',
        'log': testOutput,
      });
}

/// Runs [command] with [arguments] in [workingDirectory], and if [verbose] is
/// `true` then it logs the full command.
Future<ProcessResult> runProcess(String command, List<String> arguments,
    String workingDirectory, Logger logger, String message) async {
  logger
      .info('command:\n$command ${arguments.join(' ')} from $workingDirectory');
  final result =
      await Process.run(command, arguments, workingDirectory: workingDirectory);
  logger.info('Exit code: ${result.exitCode}');
  if (result.exitCode != 0) {
    logger.warning('STDOUT: ${result.stdout}');
    logger.warning('STDERR: ${result.stderr}');
    throw 'Error on $message: $command ${arguments.join(' ')} from $workingDirectory\n\n'
        'stdout:\n${result.stdout}\n\n'
        'stderr:\n${result.stderr}';
  } else {
    logger.info('STDOUT: ${result.stdout}');
    logger.info('STDERR: ${result.stderr}');
  }
  return result;
}

/// API to easily control verbosity of the test harness.
class Logger {
  final bool verbose;
  Logger([this.verbose = false]);
  void info(String message) {
    if (verbose) print(message);
  }

  void warning(String message) => print(message);
  void error(String message) => print(message);
}
