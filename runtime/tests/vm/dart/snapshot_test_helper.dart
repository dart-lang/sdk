// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;

class Result {
  final String cmdline;
  final ProcessResult processResult;

  Result(this.cmdline, this.processResult);
}

void reportError(Result result, String msg) {
  print('running ${result.cmdline}:');
  if (result.processResult.stdout.isNotEmpty) {
    print('''

Command stdout:
${result.processResult.stdout}''');
  }

  if (result.processResult.stderr.isNotEmpty) {
    print('''

Command stderr:
${result.processResult.stderr}''');
  }

  Expect.fail(msg);
}

void expectOutput(String what, Result result) {
  if (result.processResult.stdout.trim() != what) {
    reportError(result, 'Expected test to print \'${what}\' to stdout');
  }
}

Future<Result> runDartBinary(String prefix, List<String> arguments) async {
  final binary = Platform.executable;
  final actualArguments = <String>[]
    ..addAll(Platform.executableArguments)
    ..addAll(arguments);
  print("+ $binary " + actualArguments.join(" "));
  final processResult = await Process.run(binary, actualArguments);
  final result = new Result(
      '[$prefix] ${binary} ${actualArguments.join(' ')}', processResult);

  if (processResult.stdout.isNotEmpty) {
    print('''

Command stdout:
${processResult.stdout}''');
  }

  if (processResult.stderr.isNotEmpty) {
    print('''

Command stderr:
${processResult.stderr}''');
  }

  if (result.processResult.exitCode != 0) {
    reportError(result,
        '[$prefix] Process finished with non-zero exit code ${result.processResult.exitCode}');
  }
  return result;
}

Future<Null> checkDeterministicSnapshot(
    String snapshotKind, String expectedStdout) async {
  final Directory temp = Directory.systemTemp.createTempSync();
  final snapshot1Path = p.join(temp.path, 'snapshot1');
  final snapshot2Path = p.join(temp.path, 'snapshot2');

  try {
    print("Version ${Platform.version}");

    final generate1Result = await runDartBinary('GENERATE SNAPSHOT 1', [
      '--deterministic',
      '--trace_class_finalization',
      '--trace_type_finalization',
      '--trace_compiler',
      '--verbose_gc',
      '--snapshot=$snapshot1Path',
      '--snapshot-kind=$snapshotKind',
      Platform.script.toFilePath(),
      '--child',
    ]);
    expectOutput(expectedStdout, generate1Result);

    final generate2Result = await runDartBinary('GENERATE SNAPSHOT 2', [
      '--deterministic',
      '--trace_class_finalization',
      '--trace_type_finalization',
      '--trace_compiler',
      '--verbose_gc',
      '--snapshot=$snapshot2Path',
      '--snapshot-kind=$snapshotKind',
      Platform.script.toFilePath(),
      '--child',
    ]);
    expectOutput(expectedStdout, generate2Result);

    var snapshot1Bytes = await new File(snapshot1Path).readAsBytes();
    var snapshot2Bytes = await new File(snapshot2Path).readAsBytes();

    var minLength = min(snapshot1Bytes.length, snapshot2Bytes.length);
    for (var i = 0; i < minLength; i++) {
      if (snapshot1Bytes[i] != snapshot2Bytes[i]) {
        Expect.fail("Snapshots differ at byte $i");
      }
    }
    Expect.equals(snapshot1Bytes.length, snapshot2Bytes.length);
  } finally {
    await temp.delete(recursive: true);
  }
}

Future<void> runAppJitTest() async {
  final Directory temp = Directory.systemTemp.createTempSync();
  final snapshotPath = p.join(temp.path, 'app.jit');
  final testPath = Platform.script
      .toFilePath()
      .replaceAll(new RegExp(r'_test.dart$'), '_test_body.dart');

  try {
    final trainingResult = await runDartBinary('TRAINING RUN', [
      '--snapshot=$snapshotPath',
      '--snapshot-kind=app-jit',
      testPath,
      '--train'
    ]);
    expectOutput("OK(Trained)", trainingResult);
    final runResult = await runDartBinary('RUN FROM SNAPSHOT', [snapshotPath]);
    expectOutput("OK(Run)", runResult);
  } finally {
    await temp.delete(recursive: true);
  }
}

Future<void> runAppJitBytecodeTest() async {
  final Directory temp = Directory.systemTemp.createTempSync();
  final snapshotPath = p.join(temp.path, 'app.jit');
  final testPath = Platform.script
      .toFilePath()
      .replaceAll(new RegExp(r'_test.dart$'), '_test_body.dart');

  try {
    final trainingResult = await runDartBinary('TRAINING RUN', [
      '--enable_interpreter',
      '--snapshot=$snapshotPath',
      '--snapshot-kind=app-jit',
      testPath,
      '--train'
    ]);
    expectOutput("OK(Trained)", trainingResult);
    final runResult = await runDartBinary(
        'RUN FROM SNAPSHOT', ['--enable_interpreter', snapshotPath]);
    expectOutput("OK(Run)", runResult);
  } finally {
    await temp.delete(recursive: true);
  }
}
