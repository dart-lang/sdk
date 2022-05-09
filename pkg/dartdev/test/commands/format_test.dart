// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('format', format, timeout: longTimeout);
}

void format() {
  late TestProject p;

  tearDown(() async => await p.dispose());

  test('--help', () async {
    p = project();
    var result = await p.run(['format', '--help']);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Idiomatically format Dart source code.'));
    expect(result.stdout,
        contains('Usage: dart format [options...] <files or directories...>'));

    // Does not show verbose help.
    expect(result.stdout.contains('--stdin-name'), isFalse);
  });

  test('--help --verbose', () async {
    p = project();
    var result = await p.run(['format', '--help', '--verbose']);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Idiomatically format Dart source code.'));
    expect(result.stdout,
        contains('Usage: dart format [options...] <files or directories...>'));

    // Shows verbose help.
    expect(result.stdout, contains('--stdin-name'));
  });

  test('unchanged', () async {
    p = project(mainSrc: 'int get foo => 1;\n');
    ProcessResult result = await p.run(['format', p.relativeFilePath]);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, startsWith('Formatted 1 file (0 changed) in '));
  });

  test('formatted', () async {
    p = project(mainSrc: 'int get foo =>       1;\n');
    ProcessResult result = await p.run(['format', p.relativeFilePath]);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
        result.stdout,
        startsWith(
            'Formatted lib/main.dart\nFormatted 1 file (1 changed) in '));
  });

  test('formatted with exit code set', () async {
    p = project(mainSrc: 'int get foo =>       1;\n');
    ProcessResult result = await p.run([
      'format',
      '--set-exit-if-changed',
      p.relativeFilePath,
    ]);
    expect(result.exitCode, isNot(0));
    expect(result.stderr, isEmpty);
    expect(
        result.stdout,
        startsWith(
            'Formatted lib/main.dart\nFormatted 1 file (1 changed) in '));
  });

  test('not formatted with exit code set', () async {
    p = project(mainSrc: 'int get foo => 1;\n');
    ProcessResult result = await p.run([
      'format',
      '--set-exit-if-changed',
      p.relativeFilePath,
    ]);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, startsWith('Formatted 1 file (0 changed) in '));
  });

  test('unknown file', () async {
    p = project(mainSrc: 'int get foo => 1;\n');
    var unknownFilePath = '${p.relativeFilePath}-unknown-file.dart';
    ProcessResult result = await p.run(['format', unknownFilePath]);
    expect(result.exitCode, 0);
    expect(result.stderr,
        startsWith('No file or directory found at "$unknownFilePath".'));
    expect(result.stdout, startsWith('Formatted no files in '));
  });

  test('formats from stdin and exits', () async {
    p = project(mainSrc: 'int get foo => 1;\n');
    var process = await p.start(['format']);
    process.stdin.writeln('main(   ) { }');

    var result = process.stdout.reduce((a, b) => a + b);

    await process.stdin.close();
    expect(await process.exitCode, 0);
    expect(utf8.decode(await result), 'main() {}\n');
  });
}
