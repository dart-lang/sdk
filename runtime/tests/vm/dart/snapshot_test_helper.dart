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

  String get output => processResult.stdout.trim();
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
  if (result.output != what) {
    reportError(result, 'Expected test to print \'${what}\' to stdout');
  }
}

final String scriptSuffix = Platform.isWindows ? ".bat" : "";
final String executableSuffix = Platform.isWindows ? ".exe" : "";
final String buildDir = p.dirname(Platform.executable);
final String platformDill = p.join(buildDir, "vm_platform_strong.dill");
final String genSnapshot = p.join(buildDir, "gen_snapshot${executableSuffix}");
final String dart = p.join(buildDir, "dart${executableSuffix}");
final String dartPrecompiledRuntime =
    p.join(buildDir, "dart_precompiled_runtime${executableSuffix}");
final String genKernel = p.join("pkg", "vm", "bin", "gen_kernel.dart");
final String checkedInDartVM =
    p.join("tools", "sdks", "dart-sdk", "bin", "dart${executableSuffix}");

Future<Result> runDart(String prefix, List<String> arguments) {
  final augmentedArguments = <String>[]
    ..addAll(Platform.executableArguments)
    ..addAll(arguments);
  return runBinary(prefix, Platform.executable, augmentedArguments);
}

Future<Result> runGenKernel(String prefix, List<String> arguments) {
  final augmentedArguments = <String>[
    "--platform",
    platformDill,
    ...Platform.executableArguments.where((arg) =>
        arg.startsWith('--enable-experiment=') ||
        arg == '--sound-null-safety' ||
        arg == '--no-sound-null-safety'),
    ...arguments,
  ];
  return runGenKernelWithoutStandardOptions(prefix, augmentedArguments);
}

Future<Result> runGenKernelWithoutStandardOptions(
    String prefix, List<String> arguments) {
  return runBinary(prefix, checkedInDartVM, [genKernel, ...arguments]);
}

Future<Result> runGenSnapshot(String prefix, List<String> arguments) {
  return runBinary(prefix, genSnapshot, arguments);
}

Future<Result> runBinary(String prefix, String binary, List<String> arguments,
    {Map<String, String>? environment, bool runInShell: false}) async {
  print("+ $binary " + arguments.join(" "));
  final processResult = await Process.run(binary, arguments,
      environment: environment, runInShell: runInShell);
  final result =
      new Result('[$prefix] ${binary} ${arguments.join(' ')}', processResult);

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

withTempDir(Future fun(String dir)) async {
  final Directory tempDir = Directory.systemTemp.createTempSync();
  try {
    await fun(tempDir.path);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

checkDeterministicSnapshot(String snapshotKind, String expectedStdout) async {
  await withTempDir((String temp) async {
    final snapshot1Path = p.join(temp, 'snapshot1');
    final snapshot2Path = p.join(temp, 'snapshot2');

    print("Version ${Platform.version}");

    final generate1Result = await runDart('GENERATE SNAPSHOT 1', [
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

    final generate2Result = await runDart('GENERATE SNAPSHOT 2', [
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
  });
}

runAppJitTest(Uri testScriptUri,
    {Future<Result> Function(String snapshotPath)? runSnapshot}) async {
  runSnapshot ??=
      (snapshotPath) => runDart('RUN FROM SNAPSHOT', [snapshotPath]);

  await withTempDir((String temp) async {
    final snapshotPath = p.join(temp, 'app.jit');
    final testPath = testScriptUri.toFilePath();

    final trainingResult = await runDart('TRAINING RUN', [
      '--snapshot=$snapshotPath',
      '--snapshot-kind=app-jit',
      testPath,
      '--train'
    ]);
    expectOutput("OK(Trained)", trainingResult);
    final runResult = await runSnapshot!(snapshotPath);
    expectOutput("OK(Run)", runResult);
  });
}
