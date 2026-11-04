// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';

final dartAotExecutable = Uri.parse(Platform.resolvedExecutable)
    .resolve('dartaotruntime')
    .toFilePath();
final dart2wasmSnapshot = Uri.parse(Platform.resolvedExecutable)
    .resolve('snapshots/dart2wasm_product.snapshot')
    .toFilePath();
final platformDill = Uri.parse(Platform.resolvedExecutable)
    .resolve('../lib/_internal/dart2wasm_platform.dill')
    .toFilePath();

void main() async {
  final tempDir = Directory.systemTemp.createTempSync('dart2wasm_test');
  try {
    final testFile = File('${tempDir.path}/test.dart');
    testFile.writeAsStringSync('''
import 'package:does_not_exist/does_not_exist.dart';

void main() {}
''');

    final result = await Process.run(dartAotExecutable, [
      dart2wasmSnapshot,
      testFile.path,
      '--platform=$platformDill',
      '--dry-run',
      '${tempDir.path}/out.wasm',
    ]);

    Expect.notEquals(
      252,
      result.exitCode,
      'Expected dry-run not to crash on untranslatable URI:\n${result.stdout}',
    );
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
