// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('pub', pub, timeout: longTimeout);
}

void pub() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('implicit --help', () {
    p = project();
    var result = p.runSync('pub', []);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('Pub is a package manager for Dart'));
    expect(result.stdout, contains('Available commands:'));
    expect(result.stderr, isEmpty);
  });

  test('--help', () {
    p = project();
    var result = p.runSync('pub', ['--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Pub is a package manager for Dart'));
    expect(result.stdout, contains('Available commands:'));
    expect(result.stderr, isEmpty);
  });

  test('failure', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = p.runSync('pub', ['deps']);
    expect(result.exitCode, 65);
    expect(result.stdout, isEmpty);
    expect(result.stderr, contains('No pubspec.lock file found'));
  });

  test('failure unknown option', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = p.runSync('pub', ['deps', '--foo']);
    expect(result.exitCode, 64);
    expect(result.stdout, isEmpty);
    expect(result.stderr, startsWith('Could not find an option named "foo".'));
  });
}
