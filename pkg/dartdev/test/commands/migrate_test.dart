// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A set of integration tests for `dart migrate`.
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('migrate', defineMigrateTests, timeout: longTimeout);
}

void defineMigrateTests() {
  final runPubGet = contains('Run `dart pub get`');
  final setLowerSdkConstraint = contains('Set the lower SDK constraint');

  late TestProject p;

  tearDown(() async => await p.dispose());

  test('--help', () async {
    p = project();
    var result = await p.run(['migrate', '--help']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      result.stdout,
      contains('Perform null safety migration on a project.'),
    );
    expect(
      result.stdout,
      contains('Usage: dart migrate [arguments] [project or directory]'),
    );
  });

  test('--help --verbose', () async {
    p = project();
    var result = await p.run(['migrate', '--help', '--verbose']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      result.stdout,
      contains('Perform null safety migration on a project.'),
    );
    expect(
      result.stdout,
      contains(
        'Usage: dart [vm-options] migrate [arguments] [project or directory]',
      ),
    );
  });

  test('directory implicit', () async {
    p = project(mainSrc: dartVersionFilePrefix2_9 + 'int get foo => 1;\n');
    var result =
        await p.run(['migrate', '--no-web-preview'], workingDir: p.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Generating migration suggestions'));
  });

  test('directory explicit', () async {
    p = project(mainSrc: dartVersionFilePrefix2_9 + 'int get foo => 1;\n');
    var result = await p.run(['migrate', '--no-web-preview', p.dirPath]);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Generating migration suggestions'));
  });

  test('bad directory', () async {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = await p.run(['migrate', 'foo_bar_dir']);
    expect(result.exitCode, 1);
    expect(result.stderr, contains('foo_bar_dir does not exist'));
    expect(result.stdout, isEmpty);
  });

  test('pub get needs running', () async {
    p = project(mainSrc: 'import "package:foo/foo.dart";\n');
    var result = await p.run(['migrate', p.dirPath]);
    expect(result.exitCode, 1);
    expect(result.stderr, isEmpty);
    expect(result.stdout, runPubGet);
    expect(result.stdout, isNot(setLowerSdkConstraint));
  });

  test('non-pub-related error', () async {
    p = project(mainSrc: 'var missing = "semicolon"\n');
    var result = await p.run(['migrate', p.dirPath]);
    expect(result.exitCode, 1);
    expect(result.stderr, isEmpty);
    expect(result.stdout, runPubGet);
    expect(result.stdout, setLowerSdkConstraint);
  });
}
