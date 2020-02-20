// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('pub', pub);
}

void pub() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('implicit --help', () {
    p = project();
    var result = p.runSync('pub');
    expect(result.exitCode, 64);
    expect(result.stdout, isEmpty);
    expect(result.stderr, contains('Usage: dart pub <subcommand> [arguments]'));
    expect(result.stderr,
        contains('Print debugging information when an error occurs.'));
  });

  test('--help', () {
    p = project();
    var result = p.runSync('pub', ['--help']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Work with packages'));
    expect(result.stdout, contains('Usage: dart pub <subcommand> [arguments]'));
    expect(result.stdout,
        contains('Print debugging information when an error occurs.'));
  });

  test('success', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = p.runSync('pub', ['deps']);
    expect(result.exitCode, 1);
    expect(
        result.stderr,
        startsWith(
            '''No pubspec.lock file found, please run "pub get" first.'''));
    expect(result.stdout, isEmpty);
  });

  test('failure', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = p.runSync('pub', ['deps', '--foo']);
    expect(result.exitCode, 64);
    expect(result.stderr, startsWith('Could not find an option named "foo".'));
    expect(result.stdout, isEmpty);
  });
}
