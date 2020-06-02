// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart2native/dart2native.dart';
import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';

import 'snapshot_test_helper.dart';

Future<void> main(List<String> args) async {
  if (args.length == 1 && args[0] == '--child') {
    print('Hello, Appended AOT');
    return;
  }

  final String sourcePath = path.join('runtime', 'tests', 'vm', 'dart_2',
      'run_appended_aot_snapshot_test.dart');

  await withTempDir((String tmp) async {
    final String exeName = 'test.exe';
    final String dillPath = path.join(tmp, 'test.dill');
    final String aotPath = path.join(tmp, 'test.aot');
    final String exePath = path.join(tmp, exeName);

    {
      final result = await generateAotKernel(checkedInDartVM, genKernel,
          platformDill, sourcePath, dillPath, null, []);
      Expect.equals(result.stderr, '');
      Expect.equals(result.exitCode, 0);
      Expect.equals(result.stdout, '');
    }

    {
      final result = await generateAotSnapshot(
          genSnapshot, dillPath, aotPath, null, false, []);
      Expect.equals(result.stderr, '');
      Expect.equals(result.exitCode, 0);
      Expect.equals(result.stdout, '');
    }

    await writeAppendedExecutable(dartPrecompiledRuntime, aotPath, exePath);

    if (Platform.isLinux || Platform.isMacOS) {
      final result = await markExecutable(exePath);
      Expect.equals(result.stderr, '');
      Expect.equals(result.exitCode, 0);
      Expect.equals(result.stdout, '');
    }

    {
      final runResult =
          await runBinary('run appended aot snapshot', exePath, ['--child']);
      expectOutput('Hello, Appended AOT', runResult);
    }

    {
      // Test that it runs when invoked via PATH as well.
      Map<String, String> environment = {'PATH': tmp};
      final runResult = await runBinary(
          'run appended aot snapshot from PATH', exeName, ['--child'],
          environment: environment, runInShell: true);
      expectOutput('Hello, Appended AOT', runResult);
    }

    // Windows allows leaving out .exe. Make sure we can load that as well.
    if (Platform.isWindows) {
      final String exeNameWithoutExt =
          exeName.replaceFirst(new RegExp(r'.exe$'), '');
      Map<String, String> environment = {'PATH': tmp};
      final runResult = await runBinary(
          'run appended aot snapshot without extension',
          exeNameWithoutExt,
          ['--child'],
          environment: environment,
          runInShell: true);
      expectOutput('Hello, Appended AOT', runResult);
    }
  });
}
