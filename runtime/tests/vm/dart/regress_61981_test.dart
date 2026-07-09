// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that Dart binary correctly handles situations when stdout and stderr
// handles are the same.
//
// This can happen in certain terminal emulators, e.g. one used by GitBash
// see https://github.com/dart-lang/sdk/issues/61981 for an example.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  if (args case ['child-process']) {
    print('OK');
    return;
  }

  if (!Platform.isWindows ||
      p.basenameWithoutExtension(Platform.executable) != 'dart') {
    return;
  }

  final createProcessHelper = p.join(
    p.dirname(Platform.executable),
    'create_process_test_helper.exe',
  );

  final result = Process.runSync(createProcessHelper, [
    Platform.executable,
    'run',
    Platform.script.toFilePath(),
    'child-process',
  ]);
  if (result.exitCode != 0) {
    print(result.stdout);
    print(result.stderr);
    Expect.fail('process exited with ${result.exitCode}');
  }
  Expect.equals('OK', (result.stdout as String).trim());
}
