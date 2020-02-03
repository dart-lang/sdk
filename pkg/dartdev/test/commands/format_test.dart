// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('format', format);
}

void format() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('implicit --help', () {
    p = project();
    var result = p.runSync('format');
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Idiomatically formats Dart source code.'));
    expect(result.stdout,
        contains('dartfmt [options...] [files or directories...]'));
    expect(result.stdout, contains('dartfmt -w .'));
  });

  test('--help', () {
    p = project();
    var result = p.runSync('format', ['--help']);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Idiomatically formats Dart source code.'));
    expect(result.stdout,
        contains('dartfmt [options...] [files or directories...]'));
    expect(result.stdout, contains('dartfmt -w .'));
  });
}
