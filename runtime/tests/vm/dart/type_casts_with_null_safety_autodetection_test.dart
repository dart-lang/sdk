// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=type_casts_with_null_safety_autodetection_strong_script.dart
// OtherResources=type_casts_with_null_safety_autodetection_weak_script.dart

// This test verifies that casts with type testing stubs work as expected
// if null safety mode (weak/strong) is auto-detected.

import 'dart:io' show File, Platform;

import 'package:path/path.dart' as path;
import 'snapshot_test_helper.dart';

runTest(String script, String output, String temp) async {
  // Need to copy test scripts out of Dart SDK to avoid hardcoded
  // opted-in/opted-out status for Dart SDK tests.
  final scriptInTemp = path.join(temp, script);
  File.fromUri(Platform.script.resolve(script)).copySync(scriptInTemp);

  // Do not add Platform.executableArguments into arguments to avoid passing
  // --sound-null-safety / --no-sound-null-safety arguments.
  final result = await runBinary("RUN $script", Platform.executable, [
    '--enable-experiment=non-nullable',
    '--deterministic',
    '--optimization-counter-threshold=10',
    '--packages=${Platform.packageConfig}',
    scriptInTemp,
  ]);
  expectOutput(output, result);
}

main() async {
  await withTempDir((String temp) async {
    await runTest(
        'type_casts_with_null_safety_autodetection_strong_script.dart',
        'OK(strong)',
        temp);
    await runTest('type_casts_with_null_safety_autodetection_weak_script.dart',
        'OK(weak)', temp);
  });
}
