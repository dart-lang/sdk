// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'utils.dart';

// Regression test for https://github.com/dart-lang/sdk/issues/56080

void main() {
  test(
    'sdk_test.dart passes when run with dart from PATH',
    timeout: longTimeout,
    () async {
      final sdkTestUri = resolveDartDevUri('test/sdk_test.dart');

      final process = await Process.start(
        'dart',
        [sdkTestUri.toFilePath()],
        environment: {'PATH': path.dirname(Platform.resolvedExecutable)},
        runInShell: true,
      );
      addTearDown(process.kill);

      // All tests in sdk_test.dart should pass when `dart` is invoked from PATH.
      final (out, err, exitCode) = await (
        process.stdout.transform(utf8.decoder).join(),
        process.stderr.transform(utf8.decoder).join(),
        process.exitCode,
      ).wait;
      if (exitCode != 0) {
        print('''
EXIT CODE: $exitCode
STDOUT:
$out

STDERR:
$err''');
        fail('sdk_test.dart failed when run with dart from PATH!');
      }
    },
  );
}
