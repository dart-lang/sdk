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
  void assertPubHelpInvoked(ProcessResult result) {
    expect(result, isNotNull);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('Work with packages'));
    expect(result.stdout, contains('Available subcommands:'));
    expect(result.stderr, isEmpty);
  }

  test('implicit --help', () async {
    final result = await project().run(['pub']);
    expect(result, isNotNull);
    expect(result.exitCode, 64);
    expect(result.stderr, contains('Missing subcommand for "dart pub".'));
    expect(result.stderr, contains('Available subcommands:'));
    expect(result.stdout, isEmpty);
  });

  test('--help', () async {
    assertPubHelpInvoked(await project().run(['pub', '--help']));
  });

  test('-h', () async {
    assertPubHelpInvoked(await project().run(['pub', '-h']));
  });

  test('help cache', () async {
    final p = project();
    var result = await p.run(['help', 'pub', 'cache']);
    var result2 = await p.run(['pub', 'cache', '--help']);

    expect(result.exitCode, 0);

    expect(result.stdout, contains('Work with the system cache.'));
    expect(result.stdout, result2.stdout);

    expect(result.stderr, isEmpty);
    expect(result.stderr, result2.stderr);
  });

  test('help publish', () async {
    final p = project();
    var result = await p.run(['help', 'pub', 'publish']);
    var result2 = await p.run(['pub', 'publish', '--help']);

    expect(result.exitCode, 0);

    expect(result.stdout, contains('Publish the current package to pub.dev.'));
    expect(result.stdout, result2.stdout);

    expect(result.stderr, isEmpty);
    expect(result.stderr, result2.stderr);
  });

  test('solve failure', () async {
    final p = project(pubspecExtras: {
      'name': 'myapp',
      'environment': {'sdk': '^2.19.0'},
      'dependencies': {
        'foo': {'path': '../not_to_be_found'},
      },
    });
    final s = Platform.pathSeparator;
    var result = await p.run(['pub', 'deps']);
    expect(result.exitCode, 66);
    expect(result.stdout, isEmpty);
    expect(
      result.stderr,
      contains(
        '(could not find package foo at "..${s}not_to_be_found"), version solving failed.',
      ),
    );
  });

  test('failure unknown option', () async {
    final p = project(mainSrc: 'int get foo => 1;\n');
    var result = await p.run(['pub', 'deps', '--foo']);
    expect(result.exitCode, 64);
    expect(result.stdout, isEmpty);
    expect(
        result.stderr, startsWith('Could not find an option named "--foo".'));
  });
}
