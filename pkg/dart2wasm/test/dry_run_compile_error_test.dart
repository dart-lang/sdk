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

    Expect.equals(254, result.exitCode);
    Expect.isTrue(
      result.stderr.toString().contains(
        "Error: Couldn't resolve the package 'does_not_exist'",
      ),
      'Expected unresolved package error on stderr, got:\n${result.stderr}',
    );
    Expect.isTrue(
      result.stdout.toString().isEmpty,
      'Expected empty stdout without false-positive dry-run findings, got:\n'
      '${result.stdout}',
    );

    final pureCfeErrorFile = File('${tempDir.path}/pure_cfe_error.dart');
    pureCfeErrorFile.writeAsStringSync('''
void main() {
  final int x = 'not an int';
  print(x);
}
''');

    final pureCfeResult = await Process.run(dartAotExecutable, [
      dart2wasmSnapshot,
      pureCfeErrorFile.path,
      '--platform=$platformDill',
      '--dry-run',
      '${tempDir.path}/out_pure_cfe.wasm',
    ]);

    Expect.equals(254, pureCfeResult.exitCode);
    Expect.isTrue(
      pureCfeResult.stderr.toString().contains(
        "A value of type 'String' can't be assigned to a variable of type 'int'",
      ),
      'Expected CFE type error on stderr, got:\n${pureCfeResult.stderr}',
    );
    Expect.isTrue(
      pureCfeResult.stdout.toString().isEmpty,
      'Expected empty stdout for pure CFE error, got:\n${pureCfeResult.stdout}',
    );
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
