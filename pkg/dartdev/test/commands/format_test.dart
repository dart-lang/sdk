// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('format', format, timeout: longTimeout);
}

void format() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('--help', () {
    p = project();
    var result = p.runSync(['format', '--help']);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Idiomatically format Dart source code.'));
    expect(result.stdout,
        contains('Usage: dart format [options...] <files or directories...>'));

    // Does not show verbose help.
    expect(result.stdout.contains('--stdin-name'), isFalse);
  });

  test('--help --verbose', () {
    p = project();
    var result = p.runSync(['format', '--help', '--verbose']);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Idiomatically format Dart source code.'));
    expect(result.stdout,
        contains('Usage: dart format [options...] <files or directories...>'));

    // Shows verbose help.
    expect(result.stdout, contains('--stdin-name'));
  });

  test('unchanged', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    ProcessResult result = p.runSync(['format', p.relativeFilePath]);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, startsWith('Formatted 1 file (0 changed) in '));
  });

  test('formatted', () {
    p = project(mainSrc: 'int get foo =>       1;\n');
    ProcessResult result = p.runSync(['format', p.relativeFilePath]);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
        result.stdout,
        startsWith(
            'Formatted lib/main.dart\nFormatted 1 file (1 changed) in '));
  });

  test('unknown file', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    var unknownFilePath = '${p.relativeFilePath}-unknown-file.dart';
    ProcessResult result = p.runSync(['format', unknownFilePath]);
    expect(result.exitCode, 0);
    expect(result.stderr,
        startsWith('No file or directory found at "$unknownFilePath".'));
    expect(result.stdout, startsWith('Formatted no files in '));
  });
}
