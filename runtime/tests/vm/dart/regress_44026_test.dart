// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=regress_44026_main.dart
// OtherResources=regress_44026_opt_out_lib.dart

// Tests that compile-time error is issued if NNBD opted-out library is used
// from opted-in entry point (with null safety auto-detection).
// Regression test for https://github.com/dart-lang/sdk/issues/44026.

import 'dart:io' show File, Platform, Process;

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;
import 'snapshot_test_helper.dart';

const int kCompilationErrorExitCode = 254;

main() async {
  await withTempDir((String temp) async {
    // Need to copy test scripts out of Dart SDK to avoid hardcoded
    // opted-in/opted-out status for Dart SDK tests.
    for (String script in [
      'regress_44026_main.dart',
      'regress_44026_opt_out_lib.dart'
    ]) {
      final scriptInTemp = path.join(temp, script);
      File.fromUri(Platform.script.resolve(script)).copySync(scriptInTemp);
    }

    // Do not add Platform.executableArguments into arguments to avoid passing
    // --sound-null-safety / --no-sound-null-safety arguments.
    final result = await Process.run(Platform.executable, [
      path.join(temp, 'regress_44026_main.dart'),
    ]);
    print('stdout: ${result.stdout}');
    print('stderr: ${result.stderr}');
    Expect.equals(kCompilationErrorExitCode, result.exitCode);
    Expect.stringContainsInOrder(result.stderr, [
      "Error: A library can't opt out of null safety by default, when using sound null safety."
    ]);
  });
}
