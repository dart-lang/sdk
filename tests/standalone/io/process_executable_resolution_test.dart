// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verifies how the executable path is resolved on Linux and Mac when spawning
// a process: relative paths containing '/' are resolved against the working
// directory, while bare file names are looked up using PATH. On Linux PATH
// comes from the environment of the child process, on Mac from the
// environment of the parent process.
//
// Regression test for https://github.com/dart-lang/sdk/issues/64956.

import 'dart:io';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

const uniqueToolName = 'dart_issue_64956_tool';

void writeScript(String path, String output) {
  final file = File(path)..writeAsStringSync('#!/bin/sh\necho $output\n');
  final result = Process.runSync('chmod', ['+x', file.path]);
  Expect.equals(0, result.exitCode, result.stderr);
}

Future<void> expectOutput(
  String expected,
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  Map<String, String>? environment,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );
  Expect.equals(0, result.exitCode, '$executable: ${result.stderr}');
  Expect.equals(expected, (result.stdout as String).trim(), executable);

  final syncResult = Process.runSync(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );
  Expect.equals(0, syncResult.exitCode, '$executable: ${syncResult.stderr}');
  Expect.equals(expected, (syncResult.stdout as String).trim(), executable);
}

Future<void> expectNotFound(
  String executable, {
  required String workingDirectory,
  Map<String, String>? environment,
}) async {
  await asyncExpectThrows<ProcessException>(
    Process.run(
      executable,
      [],
      workingDirectory: workingDirectory,
      environment: environment,
    ),
  );
  Expect.throws<ProcessException>(
    () => Process.runSync(
      executable,
      [],
      workingDirectory: workingDirectory,
      environment: environment,
    ),
  );
}

Future<void> main() async {
  if (!Platform.isLinux && !Platform.isMacOS) return;

  asyncStart();
  final tempDir = Directory.systemTemp.createTempSync('dart_process_resolve');
  try {
    final root = tempDir.resolveSymbolicLinksSync();
    final binDir = Directory('$root/bin')..createSync();
    writeScript('${binDir.path}/$uniqueToolName', 'tool');
    writeScript('${binDir.path}/sh', 'fake-sh');

    // Relative paths containing '/' are resolved against workingDirectory.
    // None of these paths resolve against the working directory of the
    // test itself.
    await expectOutput(
      'tool',
      'bin/$uniqueToolName',
      [],
      workingDirectory: root,
    );
    await expectOutput(
      'tool',
      './bin/$uniqueToolName',
      [],
      workingDirectory: root,
    );
    await expectOutput(
      'tool',
      './$uniqueToolName',
      [],
      workingDirectory: binDir.path,
    );
    await expectOutput(
      'tool',
      '../bin/$uniqueToolName',
      [],
      workingDirectory: binDir.path,
    );

    // Bare file names are not looked up in workingDirectory.
    await expectNotFound(uniqueToolName, workingDirectory: binDir.path);

    // Bare file names are looked up using PATH from the environment of
    // the child process on Linux and of the parent process on Mac.
    final environment = {'PATH': binDir.path};
    if (Platform.isLinux) {
      await expectOutput(
        'tool',
        uniqueToolName,
        [],
        workingDirectory: root,
        environment: environment,
      );
      await expectOutput(
        'fake-sh',
        'sh',
        [],
        workingDirectory: root,
        environment: environment,
      );
    } else {
      await expectNotFound(
        uniqueToolName,
        workingDirectory: root,
        environment: environment,
      );
      await expectOutput(
        'real-sh',
        'sh',
        ['-c', 'echo real-sh'],
        workingDirectory: root,
        environment: environment,
      );
    }
  } finally {
    tempDir.deleteSync(recursive: true);
  }
  asyncEnd();
}
