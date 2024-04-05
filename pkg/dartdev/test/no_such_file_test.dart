// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late TestProject p;

  setUp(() async => p = project());

  test('Ensure parsing fails after encountering invalid file', () async {
    // Regression test for https://github.com/dart-lang/sdk/issues/43991
    final noArgsResult = await p.run(['foo.dart']);
    expect(noArgsResult.stderr, isNotEmpty);
    expect(noArgsResult.stdout, isEmpty);
    expect(noArgsResult.exitCode, 254);

    final argsResult = await p.run(['foo.dart', '--bar']);
    expect(argsResult.stderr, noArgsResult.stderr);
    expect(argsResult.stdout, isEmpty);
    expect(argsResult.exitCode, 254);
  });

  test('Providing --snapshot VM option with invalid script fails gracefully',
      () async {
    // Regression test for https://github.com/dart-lang/sdk/issues/43785
    final result = await p.run(['--snapshot=abc', 'foo.dart']);
    expect(result.stderr, isNotEmpty);
    expect(result.stderr, contains("Error when reading 'foo.dart':"));
    expect(result.stdout, isEmpty);
    expect(result.exitCode, 254);
  });

  test('Will not try to run file named the same as command', () async {
    p.file('pub', 'main() => print("All your base are belong to us")');
    // Regression test for https://github.com/dart-lang/sdk/issues/43785
    final result = await p.run(['pub']);
    expect(result.stderr, isNotEmpty);
    expect(result.stderr, contains('Missing subcommand'));
    expect(result.stdout, isEmpty);
    expect(result.exitCode, 64);
  });
}
