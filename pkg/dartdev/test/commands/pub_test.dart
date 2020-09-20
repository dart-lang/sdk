// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('pub', pub, timeout: longTimeout);
}

void pub() {
  TestProject p;

  tearDown(() => p?.dispose());

  void _assertPubHelpInvoked(ProcessResult result) {
    expect(result, isNotNull);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('Pub is a package manager for Dart'));
    expect(result.stdout, contains('Available commands:'));
    expect(result.stderr, isEmpty);
  }

  test('implicit --help', () {
    _assertPubHelpInvoked(project().runSync('pub', []));
  });

  test('--help', () {
    _assertPubHelpInvoked(project().runSync('pub', ['--help']));
  });

  test('-h', () {
    _assertPubHelpInvoked(project().runSync('pub', ['-h']));
  });

  test('help cache', () {
    p = project();
    var result = p.runSync('pub', ['help', 'cache']);
    var result2 = p.runSync('pub', ['cache', '--help']);

    expect(result.exitCode, 0);

    expect(result.stdout, contains('Work with the system cache.'));
    expect(result.stdout, result2.stdout);

    expect(result.stderr, isEmpty);
    expect(result.stderr, result2.stderr);
  });

  test('help publish', () {
    p = project();
    var result = p.runSync('pub', ['help', 'publish']);
    var result2 = p.runSync('pub', ['publish', '--help']);

    expect(result.exitCode, 0);

    expect(result.stdout,
        contains('Publish the current package to pub.dartlang.org.'));
    expect(result.stdout, result2.stdout);

    expect(result.stderr, isEmpty);
    expect(result.stderr, result2.stderr);
  });

  test('--enable-experiment pub run', () {
    p = project();
    p.file('bin/main.dart',
        "void main() { int a; a = null; print('a is \$a.'); }");

    // run 'pub get'
    p.runSync('pub', ['get']);

    var result = p.runSync(
        '--enable-experiment=non-nullable', ['pub', 'run', 'main.dart']);

    expect(result.exitCode, 254);
    expect(result.stdout, isEmpty);
    expect(
        result.stderr,
        contains("A value of type 'Null' can't be assigned to a variable of "
            "type 'int'"));
  });

  test('pub run --enable-experiment', () {
    p = project();
    p.file('bin/main.dart',
        "void main() { int a; a = null; print('a is \$a.'); }");

    // run 'pub get'
    p.runSync('pub', ['get']);

    var result = p.runSync(
        'pub', ['run', '--enable-experiment=non-nullable', 'main.dart']);

    expect(result.exitCode, 254);
    expect(result.stdout, isEmpty);
    expect(
        result.stderr,
        contains("A value of type 'Null' can't be assigned to a variable of "
            "type 'int'"));
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
