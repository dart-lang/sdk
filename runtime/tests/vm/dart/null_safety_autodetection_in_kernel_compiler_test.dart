// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests auto-detection of null safety mode in gen_kernel tool.

import 'dart:io' show File, Platform;

import 'package:path/path.dart' as path;
import 'snapshot_test_helper.dart';

compileAndRunTest(String comment, String expectedOutput) async {
  await withTempDir((String temp) async {
    final testScriptPath = path.join(temp, 'test.dart');
    File(testScriptPath).writeAsStringSync('''
      // $comment

      void main() {
        try {
          null as int;
          print('weak mode');
        } on TypeError {
          print('strong mode');
        }
      }
    ''');

    final testDillPath = path.join(temp, 'test.dill');
    await runGenKernelWithoutStandardOptions('BUILD DILL FILE', [
      "--platform",
      platformDill,
      '--enable-experiment=non-nullable',
      '--output=$testDillPath',
      testScriptPath,
    ]);

    final result = await runBinary(
        'RUN TEST FROM DILL', Platform.executable, [testDillPath]);
    expectOutput(expectedOutput, result);
  });
}

main() async {
  await compileAndRunTest('', 'strong mode');
  await compileAndRunTest('@dart=2.7', 'weak mode');
}
