#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Smoke test runner for Dart AOT (dart2native, dartaotruntime).
// aot_smoke_tests.dart and dart_aot_test.dart together form the test that the
// AOT toolchain is compiled and included correctly in the SDK.
// This tests that the AOT tools can both successfully compile Dart -> AOT and
// run the resulting AOT blob with the AOT runtime.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

final String newline = Platform.isWindows ? '\r\n' : '\n';
final String scriptSuffix = Platform.isWindows ? ".bat" : "";
final String executableSuffix = Platform.isWindows ? ".exe" : "";
final String sdkBinDir = path.dirname(Platform.executable);
final String dartaotruntime =
    path.join(sdkBinDir, 'dartaotruntime${executableSuffix}');
final String dart2native = path.join(sdkBinDir, 'dart2native${scriptSuffix}');

Future<void> withTempDir(Future fun(String dir)) async {
  final Directory tempDir = Directory.systemTemp.createTempSync();
  try {
    await fun(tempDir.path);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void main(List<String> args) {
  test("dart2native: Can compile and run AOT", () async {
    await withTempDir((String tmp) async {
      final String testCode = path.join('tools', 'bots', 'dart_aot_test.dart');
      final String tmpAot = path.join(tmp, 'dart_aot_test.aot');

      {
        final ProcessResult result = await Process.run(dart2native,
            [testCode, '--output', tmpAot, '--output-kind', 'aot']);
        expect(result.stderr, '');
        expect(result.exitCode, 0);
      }

      {
        const String testStr = 'Dart AOT';
        final ProcessResult result =
            await Process.run(dartaotruntime, [tmpAot, testStr]);
        expect(result.stderr, '');
        expect(result.exitCode, 0);
        expect(result.stdout, 'Hello, ${testStr}.${newline}');
      }
    });
  });

  test("dart2native: Can compile and run exe", () async {
    await withTempDir((String tmp) async {
      final String testCode = path.join('tools', 'bots', 'dart_aot_test.dart');
      final String tmpExe = path.join(tmp, 'dart_aot_test.exe');

      {
        final ProcessResult result =
            await Process.run(dart2native, [testCode, '--output', tmpExe]);
        expect(result.stderr, '');
        expect(result.exitCode, 0);
      }

      {
        const String testStr = 'Dart AOT';
        final ProcessResult result = await Process.run(tmpExe, [testStr]);
        expect(result.stderr, '');
        expect(result.exitCode, 0);
        expect(result.stdout, 'Hello, ${testStr}.${newline}');
      }
    });
  });

  test("dart2native: Returns non-zero on missing file.", () async {
    await withTempDir((String tmp) async {
      final String testCode = path.join(tmp, 'does_not_exist.dart');
      final String tmpExe = path.join(tmp, 'dart_aot_test.exe');

      {
        final ProcessResult result =
            await Process.run(dart2native, [testCode, '--output', tmpExe]);
        expect(result.exitCode, isNonZero);
      }
    });
  });

  test("dart2native: Returns non-zero on non-file.", () async {
    await withTempDir((String tmp) async {
      final String testCode = tmp; // This is a directory, not a file.
      final String tmpExe = path.join(tmp, 'dart_aot_test.exe');

      {
        final ProcessResult result =
            await Process.run(dart2native, [testCode, '--output', tmpExe]);
        expect(result.exitCode, isNonZero);
      }
    });
  });
}
