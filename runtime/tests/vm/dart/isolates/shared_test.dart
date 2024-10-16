// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=shared_test_body.dart
//
// This launches shared_test test if the test runs on the appropriate channel.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:expect/config.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import '../use_flag_test_helper.dart';

void main(List<String> args) async {
  if (Platform.isAndroid) {
    return; // No vm_platform_strong.dill easily available.
  }

  asyncStart();
  final testerScriptPath = Platform.script.toFilePath();
  final testeeScriptPath =
      Platform.script.resolve('shared_test_body.dart').toFilePath();

  final Directory tempDir = Directory.systemTemp.createTempSync();
  try {
    if (isVmAotConfiguration) {
      final scriptDill = path.join(tempDir.path, 'shared_test_body.dart.dill');
      await run(
          path.joinAll([
            'pkg',
            'vm',
            'tool',
            'gen_kernel${Platform.isWindows ? ".bat" : ""}'
          ]),
          <String>[
            '--aot',
            '--platform=$platformDill',
            '-o',
            scriptDill,
            testeeScriptPath
          ]);

      final elfFile = path.join(tempDir.path, 'shared_test_body.dart.dill.elf');
      final stderr = (await runError(genSnapshot, <String>[
        '--snapshot-kind=app-aot-elf',
        '--elf=$elfFile',
        scriptDill,
      ]))
          .join('\n');
      print('stderr: $stderr');
      Expect.contains(
          'Encountered dart:concurrent when functionality is disabled. '
          'Pass --experimental-shared-data',
          stderr);
    } else {
      final result = await Process.run(Platform.executable, <String>[
        ...Platform.executableArguments,
        '--experimental_shared_data',
        testeeScriptPath
      ]);
      if (Platform.version.contains('(main)') ||
          Platform.version.contains('(dev)')) {
        if (result.exitCode != 0) {
          print('stdout: ${result.stdout}');
          print('stderr: ${result.stderr}');
        }
        Expect.equals(0, result.exitCode);
      } else {
        Expect.notEquals(0, result.exitCode);
        Expect.contains(
            'Shared memory multithreading in only available for '
            'experimentation in dev or main',
            result.stderr);
      }
    }
  } finally {
    tempDir.deleteSync(recursive: true);
  }
  asyncEnd();
}
