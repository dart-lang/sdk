// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';
import "package:test_runner/src/command.dart";
import "package:test_runner/src/process_queue.dart";

void main(List<String> args) async {
  // test runner won't pass any args, but BatchRunnerProcess passes ['--batch'].
  args.isEmpty ? await test() : dummy();
}

late List<String> _testArguments;

Future<void> test() async {
  final batchRunner = BatchRunnerProcess.byIdentifier('dummy', 1);
  final command = DummyProcessCommand('dummy batch runner', Platform.executable,
      [Platform.script.toFilePath()]);
  final incompatibleCommand = DummyProcessCommand(
      'dummy batch runner',
      Platform.executable,
      [Platform.script.toFilePath()],
      {'ENV_VAR': 'VALUE'});
  try {
    print('run commands');
    Expect.isFalse(batchRunner.hasRunningProcess);
    Expect.isFalse(batchRunner.isCompatibleRunner(command));
    await runCommand(batchRunner, command, 'PASS', 0);
    Expect.isTrue(batchRunner.hasRunningProcess);
    Expect.isFalse(batchRunner.isCompatibleRunner(incompatibleCommand));
    await runCommand(batchRunner, incompatibleCommand, 'PASS', 0);
    Expect.isTrue(batchRunner.hasRunningProcess);
    Expect.isFalse(batchRunner.isCompatibleRunner(command));
    await runCommand(batchRunner, command, 'FAIL', 1);
    Expect.isTrue(batchRunner.hasRunningProcess);
    Expect.isTrue(batchRunner.isCompatibleRunner(command));
    await runCommand(batchRunner, command, 'TIMEOUT', 1);
    Expect.isTrue(batchRunner.hasRunningProcess);
    await runCommand(batchRunner, command, 'PARSE_FAIL', parseFailExitCode);
    Expect.isTrue(batchRunner.hasRunningProcess);
    await runCommand(batchRunner, command, 'BATCH_RUNNER_CRASH',
        unhandledCompilerExceptionExitCode);
    Expect.isFalse(batchRunner.hasRunningProcess);
    await runCommand(
        batchRunner, command, 'CRASH', unhandledCompilerExceptionExitCode);
    Expect.isTrue(batchRunner.hasRunningProcess);
  } finally {
    print('terminate');
    await BatchRunnerProcess.terminateAll();
    Expect.isFalse(batchRunner.hasRunningProcess);
  }
  print('exiting');
}

Future<void> runCommand(BatchRunnerProcess batchRunner, ProcessCommand command,
    String result, int expectedExitCode) async {
  _testArguments = [result];
  final output = await batchRunner.runCommand(command, 10);
  Expect.equals('stdout $result\n', utf8.decode(output.stdout),
      "$result: unexpected test stdout");
  if (result == 'BATCH_RUNNER_CRASH') {
    Expect.contains('Unhandled exception:\nException: Dummy crashed!\n',
        utf8.decode(output.stderr), "$result: unexpected test stderr");
  } else {
    Expect.equals('stderr $result\n', utf8.decode(output.stderr),
        "$result: unexpected test stderr");
  }
  Expect.equals(
      expectedExitCode, output.exitCode, "$result: unexpected exit code");
  Expect.equals(result == 'TIMEOUT', output.hasTimedOut);
}

void dummy() {
  String? testArguments;
  while ((testArguments = stdin.readLineSync()) != null) {
    stdout.writeln('stdout $testArguments');
    stdout.writeln('>>> BATCH ignored');
    if (testArguments == 'BATCH_RUNNER_CRASH') {
      throw Exception('Dummy crashed!');
    }
    stderr.writeln('stderr $testArguments');
    stderr.writeln('>>> EOF STDERR');
    stdout.writeln('>>> TEST $testArguments');
  }
}

class DummyProcessCommand extends ProcessCommand {
  DummyProcessCommand(super.displayName, super.executable, super.arguments,
      [super.environmentOverrides]);

  @override
  List<String> get arguments => _testArguments;

  @override
  List<String> get batchArguments => [Platform.script.toFilePath()];
}
