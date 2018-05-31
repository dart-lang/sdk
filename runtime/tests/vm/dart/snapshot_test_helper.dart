// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

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
    final generate1Result = await runDartBinary('GENERATE SNAPSHOT 1', [
      '--deterministic',
      '--snapshot=$snapshot1Path',
      '--snapshot-kind=$snapshotKind',
      Platform.script.toFilePath(),
      '--child',
    ]);
    expectOutput(expectedStdout, generate1Result);

    final generate2Result = await runDartBinary('GENERATE SNAPSHOT 2', [
      '--deterministic',
      '--snapshot=$snapshot2Path',
      '--snapshot-kind=$snapshotKind',
      Platform.script.toFilePath(),
      '--child',
    ]);
    expectOutput(expectedStdout, generate2Result);

    var snapshot1Bytes = await new File(snapshot1Path).readAsBytes();
    var snapshot2Bytes = await new File(snapshot2Path).readAsBytes();

    Expect.equals(snapshot1Bytes.length, snapshot2Bytes.length);
    for (var i = 0; i < snapshot1Bytes.length; i++) {
      if (snapshot1Bytes[i] != snapshot2Bytes[i]) {
        Expect.fail("Snapshots are not bitwise equal!");
      }
    }
  } finally {
    await temp.delete(recursive: true);
  }
}
