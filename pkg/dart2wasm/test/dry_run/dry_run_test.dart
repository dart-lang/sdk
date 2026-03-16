// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:expect/expect.dart';

final dartAotExecutable = Uri.parse(Platform.resolvedExecutable)
    .resolve('dartaotruntime')
    .toFilePath();
final dart2wasmSnapshot = Uri.parse(Platform.resolvedExecutable)
    .resolve('snapshots/dart2wasm_product.snapshot')
    .toFilePath();
final platformDill = Uri.parse(Platform.resolvedExecutable)
    .resolve('../lib/_internal/dart2wasm_platform.dill')
    .toFilePath();

class TestExpectation {
  final int expectedErrorCode;
  final String? expectedErrorSubstring;
  final int lineNumber;

  TestExpectation(
      this.expectedErrorCode, this.expectedErrorSubstring, this.lineNumber);

  factory TestExpectation.fromLine(String line, int lineNumber) {
    final errorText = line.replaceAll('// DRY_RUN:', '').trim().split(',');
    final expectedErrorCode = int.parse(errorText[0].trim());
    final expectedErrorSubstring =
        errorText.length > 1 ? errorText.sublist(1).join(',').trim() : null;
    return TestExpectation(
        expectedErrorCode, expectedErrorSubstring, lineNumber);
  }
}

class TestFinding {
  final String rawString;
  final int errorCode;
  final String problemMessage;
  final Uri? errorSourceUri;
  final int? errorLine;
  final int? errorColumn;

  TestFinding(this.rawString, this.errorCode, this.problemMessage,
      this.errorSourceUri, this.errorLine, this.errorColumn);

  factory TestFinding.fromLine(String line) {
    final parts = line.split(' - ');
    final locationInfo = parts[0].split(' ');
    final uri = locationInfo[0].trim();
    final lineCol = locationInfo[1].split(':');
    final lineNumber = int.parse(lineCol[0].trim());
    final columnNumber = int.parse(lineCol[1].trim());
    final problemMessage = parts[1];
    final errorCodeStart = problemMessage.lastIndexOf('(');
    final errorCodeEnd = problemMessage.lastIndexOf(')');
    final errorCode =
        int.parse(problemMessage.substring(errorCodeStart + 1, errorCodeEnd));
    return TestFinding(
        line,
        errorCode,
        problemMessage.substring(0, errorCodeStart).trim(),
        Uri.parse(uri),
        lineNumber,
        columnNumber);
  }
}

enum Status { pass, fail, crash }

class TestResults {
  final String name;
  final Status status;
  final Duration time;
  final String details;

  TestResults(this.name, this.status, this.time, this.details);

  String toRecordJson(String configuration) {
    final outcome = switch (status) {
      Status.pass => 'Pass',
      Status.crash => 'Crash',
      Status.fail => 'RuntimeError',
    };
    return jsonEncode({
      'name': 'dry_run/$name',
      'configuration': configuration,
      'suite': 'dry_run',
      'test_name': name,
      'time_ms': time.inMilliseconds,
      'expected': 'Pass',
      'result': outcome,
      'matches': status == Status.pass,
    });
  }

  String toLogJson(String configuration) {
    final outcome = switch (status) {
      Status.pass => 'Pass',
      Status.crash => 'Crash',
      Status.fail => 'RuntimeError',
    };
    return jsonEncode({
      'name': 'dry_run/$name',
      'configuration': configuration,
      'result': outcome,
      'log': details,
    });
  }
}

class TestCase {
  final Uri path;
  final List<String> compilerFlags;
  final List<TestExpectation> expectations;

  TestCase(this.path, this.compilerFlags, this.expectations);

  String get name => path.pathSegments.last.replaceAll('.dart', '');
}

Future<TestResults> runTest(TestCase testCase) async {
  print('Executing test: ${testCase.name}');
  final timer = Stopwatch();
  timer.start();
  ProcessResult result;
  try {
    result = await Process.run(dartAotExecutable, [
      dart2wasmSnapshot,
      testCase.path.toFilePath(),
      '--platform=$platformDill',
      '--dry-run',
      ...testCase.compilerFlags,
      'out.wasm',
    ]);
  } catch (e, s) {
    timer.stop();
    return TestResults(testCase.name, Status.crash, timer.elapsed, '$e\n$s');
  }
  timer.stop();
  try {
    final exitCode = result.exitCode;
    if (testCase.expectations.isEmpty) {
      Expect.equals(0, exitCode, 'Unexpected findings:\n${result.stdout}');
    } else {
      Expect.equals(254, exitCode, 'Expected findings but found none.');
    }
    final findings = _parseTestFindings(result.stdout);
    _checkFindings(findings, testCase.expectations);
  } catch (e, s) {
    return TestResults(testCase.name, Status.fail, timer.elapsed, '$e\n$s');
  }
  return TestResults(testCase.name, Status.pass, timer.elapsed, '');
}

/// Generates a report of the test results in the JSON format
/// that is expected by our testing infrastructure.
int reportResults(
  List<TestResults> results, {
  String? configuration,
  String? logDir,
}) {
  bool fail = false;
  print('Test results:');
  for (var result in results) {
    print('  ${result.name}: ${result.status}');
    if (result.status != Status.pass) fail = true;
  }
  if (fail) print('Error: some tests failed');

  if (logDir == null) {
    print('Error: no output directory provided, logs won\'t be emitted.');
    return 1;
  }
  if (configuration == null) {
    print('Error: no configuration name provided, logs won\'t be emitted.');
    return 1;
  }

  // Ensure the directory URI ends with a path separator.
  var dirUri = Directory(logDir).uri;
  File.fromUri(dirUri.resolve('results.json')).writeAsStringSync(
    results.map((r) => '${r.toRecordJson(configuration)}\n').join(),
    flush: true,
  );
  File.fromUri(dirUri.resolve('logs.json')).writeAsStringSync(
    results
        .where((r) => r.status != Status.pass)
        .map((r) => '${r.toLogJson(configuration)}\n')
        .join(),
    flush: true,
  );

  print('Success: log files emitted under $dirUri');
  return 0;
}

Future<List<TestCase>> _loadTestCases() async {
  final testCaseDir = Directory.fromUri(Platform.script.resolve('testcases'));
  final testCases = <TestCase>[];
  for (final file in testCaseDir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      testCases.add(await _parseTestCase(file.uri));
    }
  }
  return testCases;
}

Future<TestCase> _parseTestCase(Uri path) async {
  final fileContents = await File.fromUri(path).readAsString();
  final lines = fileContents.split('\n');
  // Bespoke flags syntax over the SDK test syntax of `// dart2wasmOptions=`
  // as the value of the latter can't be passed directly to dart2wasm.
  const compilerFlagsComment = '// compilerFlags=';
  final compilerFlags = <String>[];
  final expectations = <TestExpectation>[];
  int lineIndex = 0;
  for (final line in lines) {
    if (line.contains('// DRY_RUN:')) {
      final nextNonCommentLine =
          lines.indexWhere((l) => !l.trim().startsWith('//'), lineIndex + 1) +
              1;
      expectations.add(TestExpectation.fromLine(line, nextNonCommentLine));
    } else if (line.contains(compilerFlagsComment)) {
      compilerFlags.addAll(line
          .substring(
              line.indexOf(compilerFlagsComment) + compilerFlagsComment.length)
          .split(' '));
    }
    lineIndex++;
  }
  return TestCase(path, compilerFlags, expectations);
}

List<TestFinding> _parseTestFindings(String result) {
  final lines = result.split('\n');
  final findings = <TestFinding>[];
  // Skip header and newline.
  for (final line in lines.skip(2)) {
    if (line.isEmpty) continue;
    findings.add(TestFinding.fromLine(line));
  }
  return findings;
}

void _checkFindings(
    List<TestFinding> findings, List<TestExpectation> expectations) {
  Expect.equals(
      findings.length,
      expectations.length,
      'Incorrect number of findings. '
      'Expected: ${expectations.length}, Actual: ${findings.length}\n'
      'Findings:\n${findings.map((e) => e.rawString).join('\n')}}');
  for (final expectation in expectations) {
    final lineNumber = expectation.lineNumber;
    final lineFindings =
        findings.where((finding) => finding.errorLine == lineNumber);

    final matchingFinding = lineFindings.firstWhereOrNull(
        (finding) => finding.errorCode == expectation.expectedErrorCode);

    Expect.isNotNull(
      matchingFinding,
      'No finding found for expectation on line $lineNumber',
    );
    Expect.equals(
        expectation.expectedErrorCode,
        matchingFinding!.errorCode,
        'Unexpected error code for expectation on line $lineNumber. '
        'Expected: ${expectation.expectedErrorCode}, Actual: ${matchingFinding.errorCode}');
    if (expectation.expectedErrorSubstring != null) {
      Expect.contains(
          expectation.expectedErrorSubstring!, matchingFinding.problemMessage);
    }
  }
}

Future<int> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'configuration',
      help: 'Configuration to use for reporting test results',
      abbr: 'n',
    )
    ..addOption(
      'output-directory',
      help: 'Location to emit the json-l result and log files',
    )
    ..addFlag(
      'verbose',
      help: 'Show more information',
      negatable: false,
      abbr: 'v',
    );
  final parsedArgs = parser.parse(args);
  final configuration = parsedArgs.option('configuration');
  final outputDirectory = parsedArgs.option('output-directory');
  final verbose = parsedArgs.flag('verbose');

  final testCases = await _loadTestCases();

  final results = <TestResults>[];
  for (final testCase in testCases) {
    final testResult = await runTest(testCase);
    results.add(testResult);
    if (verbose && testResult.status != Status.pass) {
      print(testResult.details);
    }
  }

  return reportResults(results,
      configuration: configuration, logDir: outputDirectory);
}
