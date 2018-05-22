// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=100

// Verify that app-jit snapshot contains dependencies between classes and CHA
// optimized code.

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
  final processResult = await Process.run(binary, actualArguments);
  final result = new Result(
      '[$prefix] ${binary} ${actualArguments.join(' ')}', processResult);
  if (result.processResult.exitCode != 0) {
    reportError(result,
        '[$prefix] Process finished with non-zero exit code ${result.processResult.exitCode}');
  }
  return result;
}

const snapshotName = 'app.jit';

void main() async {
  final Directory temp = Directory.systemTemp.createTempSync();
  final snapshotPath = p.join(temp.path, 'app.jit');
  final testPath = Platform.script
      .toFilePath()
      .replaceAll(new RegExp(r'_test.dart$'), '_test_body.dart');

  await temp.create();
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
