// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=macos_dual_mapping_smoke_script.dart

// Tests that dual mapping works on Mac OS. This is a smoke test for
// functionality enabled in development mode on iOS 26 devices.
//
// To test this code path we use --force_dual_mapping_of_code_pages which
// assumes that VM does not execute from a snapshot. Hence the need to run
// from Kernel directly.

import 'dart:io' show Platform, File;

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;
import 'snapshot_test_helper.dart';

compileAndRunMinimalDillTest(List<String> extraCompilationArgs) async {
  final testScriptUri = Platform.script.resolve(
    'macos_dual_mapping_smoke_script.dart',
  );
  final message = 'Round_trip_message';
  final expectedResponse = '42$message';

  await withTempDir((String temp) async {
    final minimalDillPath = path.join(temp, 'test.dill');
    await runGenKernel('BUILD DILL FILE', [
      '--no-link-platform',
      ...extraCompilationArgs,
      '--output=$minimalDillPath',
      testScriptUri.toFilePath(),
    ]);

    {
      final result = await runDart('RUN FROM DILL FILE', [
        minimalDillPath,
        message,
      ]);
      expectOutput(expectedResponse, result);
    }

    final String unsignedDartExecutable;
    final entitlementsInfo = (await runBinary(
      'CHECKING ENTITLEMENTS',
      'codesign',
      ['-d', '--entitlements', '-', '--xml', Platform.executable],
      allowNonZeroExitCode: true,
    )).processResult;
    Expect.isTrue(entitlementsInfo.stderr.startsWith('Executable='));
    if (entitlementsInfo.stdout.contains('<?xml') &&
        !entitlementsInfo.stdout.contains(
          'com.apple.security.cs.allow-unsigned-executable-memory',
        )) {
      // Non-empty entitlements without
      // com.apple.security.cs.allow-unsigned-executable-memory will make
      // this test fail so strip them.
      unsignedDartExecutable = path.join(temp, 'dart');
      File(Platform.executable).copySync(unsignedDartExecutable);
      await runBinary('REMOVING SIGNATURE', 'codesign', [
        '--remove-signature',
        unsignedDartExecutable,
      ]);
      await runBinary('RESIGNING', 'codesign', [
        '-s',
        '-',
        unsignedDartExecutable,
      ]);
    } else {
      unsignedDartExecutable = Platform.executable;
    }

    {
      final result = await runDart('RUN FROM DILL FILE', [
        '--force_dual_mapping_of_code_pages',
        minimalDillPath,
        message,
      ], dartExecutable: unsignedDartExecutable);
      expectOutput(expectedResponse, result);
    }
  });
}

void main() async {
  // Only supported on MacOS.
  if (!Platform.isMacOS || isAOTRuntime) {
    return;
  }
  await compileAndRunMinimalDillTest([]);
}
