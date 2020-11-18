// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'utils.dart';

void main() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('Ensure parsing fails after encountering invalid file', () {
    // Regression test for https://github.com/dart-lang/sdk/issues/43991
    p = project();
    final noArgsResult = p.runSync('foo.dart', []);
    expect(noArgsResult.stderr, isNotEmpty);
    expect(noArgsResult.stdout, isEmpty);
    expect(noArgsResult.exitCode, 64);

    final argsResult = p.runSync('foo.dart', ['--bar']);
    expect(argsResult.stderr, noArgsResult.stderr);
    expect(argsResult.stdout, isEmpty);
    expect(argsResult.exitCode, 64);
  });
}
