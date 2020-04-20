// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:nnbd_migration/src/utilities/subprocess_launcher.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubprocessLauncherTest);
  });
}

@reflectiveTest
class SubprocessLauncherTest {
  Function(String) outputCallback;
  List<String> output;
  Directory tempDir;

  void setUp() async {
    output = [];
    outputCallback = output.add;
    tempDir = await Directory.systemTemp.createTemp();
  }

  void tearDown() async {
    await tempDir.delete(recursive: true);
  }

  Future<void> test_subprocessWorksViaParallelSubprocessLimit() async {
    SubprocessLauncher launcher =
        SubprocessLauncher('test_subprocessWorksViaParallelSubprocessLimit');

    await launcher.runStreamed(Platform.resolvedExecutable, ['--version'],
        perLine: outputCallback);
    expect(output, anyElement(contains('Dart')));
  }

  Future<void> test_subprocessRunsValidExecutable() async {
    SubprocessLauncher launcher =
        SubprocessLauncher('test_subprocessRunsValidExecutable');

    await launcher.runStreamedImmediate(
        Platform.resolvedExecutable, ['--version'],
        perLine: outputCallback);
    expect(output, anyElement(contains('Dart')));
  }

  Future<void> test_subprocessPassesArgs() async {
    SubprocessLauncher launcher =
        SubprocessLauncher('test_subprocessPassesArgs');
    File testScript =
        File(path.join(tempDir.path, 'subprocess_test_script.dart'));
    await testScript.writeAsString(r'''
      import 'dart:io';

      main(List<String> args) {
        print('args: $args');
      }''');

    await launcher.runStreamedImmediate(
        Platform.resolvedExecutable, [testScript.path, 'testArgument'],
        perLine: outputCallback);
    expect(output, anyElement(contains('args: [testArgument]')));
  }

  Future<void> test_subprocessPassesEnvironment() async {
    SubprocessLauncher launcher =
        SubprocessLauncher('test_subprocessPassesEnvironment');
    File testScript =
        File(path.join(tempDir.path, 'subprocess_test_script.dart'));
    await testScript.writeAsString(r'''
      import 'dart:io';

      main(List<String> args) {
        print('environment: ${Platform.environment}');
      }''');

    await launcher.runStreamedImmediate(
        Platform.resolvedExecutable, [testScript.path],
        environment: {'__SUBPROCESS_PASSES_ENVIRONMENT_TEST': 'yes'},
        perLine: outputCallback);
    expect(
        output,
        anyElement(contains(RegExp(
            '^environment: .*__SUBPROCESS_PASSES_ENVIRONMENT_TEST: yes'))));
  }

  Future<void> test_subprocessSetsWorkingDirectory() async {
    SubprocessLauncher launcher =
        SubprocessLauncher('test_subprocessSetsWorkingDirectory');
    File testScript =
        File(path.join(tempDir.path, 'subprocess_test_script.dart'));
    await testScript.writeAsString(r'''
      import 'dart:io';

      main() {
        print('working directory: ${Directory.current.path}');
      }''');

    await launcher.runStreamedImmediate(
        Platform.resolvedExecutable, [testScript.path],
        workingDirectory: tempDir.path, perLine: outputCallback);
    expect(
        output,
        anyElement(contains(
            'working directory: ${tempDir.resolveSymbolicLinksSync()}')));
  }

  Future<void> test_subprocessThrowsOnNonzeroExitCode() async {
    SubprocessLauncher launcher =
        SubprocessLauncher('test_subprocessThrowsOnNonzeroExitCode');
    File testScript =
        File(path.join(tempDir.path, 'subprocess_test_script.dart'));
    await testScript.writeAsString(r'''
      import 'dart:io';

      main() {
        exit(1);
      }''');
    await expectLater(
        () async => await launcher.runStreamedImmediate(
            Platform.resolvedExecutable, [testScript.path],
            perLine: outputCallback),
        throwsA(TypeMatcher<ProcessException>()));
  }
}
