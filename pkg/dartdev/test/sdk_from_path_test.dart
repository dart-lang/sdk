// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

// Regression test for https://github.com/dart-lang/sdk/issues/56080

void main() {
  late final Process? process;

  tearDown(() {
    process?.kill();
  });

  test('sdk_test.dart passes when run with dart from PATH', () async {
    final script = path.join(
      path.dirname(Platform.script.toString()),
      'sdk_test.dart',
    );
    process = await Process.start(
      'dart',
      [script],
      environment: {'PATH': path.dirname(Platform.resolvedExecutable)},
    );

    // All tests in sdk_test.dart should pass when `dart` is invoked from PATH.
    final exitCode = await process!.exitCode;
    if (exitCode != 0) {
      print('EXIT CODE: $exitCode');
      print('STDOUT:');
      print(await process!.stdout.transform(utf8.decoder).join());
      print('');
      print('STDERR:');
      print(await process!.stderr.transform(utf8.decoder).join());
      print('sdk_test.dart failed when run with dart from PATH!');
    }
  });
}
