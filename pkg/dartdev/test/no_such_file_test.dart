// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late TestProject p;

  tearDown(() async => await p.dispose());

  test('Ensure parsing fails after encountering invalid file', () async {
    // Regression test for https://github.com/dart-lang/sdk/issues/43991
    p = project();
    final noArgsResult = await p.run(['foo.dart']);
    expect(noArgsResult.stderr, isNotEmpty);
    expect(noArgsResult.stdout, isEmpty);
    expect(noArgsResult.exitCode, 64);

    final argsResult = await p.run(['foo.dart', '--bar']);
    expect(argsResult.stderr, noArgsResult.stderr);
    expect(argsResult.stdout, isEmpty);
    expect(argsResult.exitCode, 64);
  });

  test('Providing --snapshot VM option with invalid script fails gracefully',
      () async {
    // Regression test for https://github.com/dart-lang/sdk/issues/43785
    p = project();
    final result = await p.run(['--snapshot=abc', 'foo.dart']);
    expect(result.stderr, isNotEmpty);
    expect(result.stderr, contains("Error when reading 'foo.dart':"));
    expect(result.stdout, isNotEmpty);
    expect(result.stdout, contains('Info: Compiling with sound null safety\n'));
    expect(result.exitCode, 254);
  });
}
