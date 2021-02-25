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

  TestProject p;

  tearDown(() => p?.dispose());

  test('--help', () {
    p = project();
    var result = p.runSync(['migrate', '--help']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout,
        contains('Perform a null safety migration on a project or package.'));
    expect(result.stdout,
        contains('Usage: dart migrate [arguments] [project or directory]'));
  });

  test('directory implicit', () {
    p = project(mainSrc: dartVersionFilePrefix2_9 + 'int get foo => 1;\n');
    var result =
        p.runSync(['migrate', '--no-web-preview'], workingDir: p.dirPath);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Generating migration suggestions'));
  });

  test('directory explicit', () {
    p = project(mainSrc: dartVersionFilePrefix2_9 + 'int get foo => 1;\n');
    var result = p.runSync(['migrate', '--no-web-preview', p.dirPath]);
    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Generating migration suggestions'));
  });

  test('bad directory', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = p.runSync(['migrate', 'foo_bar_dir']);
    expect(result.exitCode, 1);
    expect(result.stderr, contains('foo_bar_dir does not exist'));
    expect(result.stdout, isEmpty);
  });

  test('pub get needs running', () {
    p = project(mainSrc: 'import "package:foo/foo.dart";\n');
    var result = p.runSync(['migrate', p.dirPath]);
    expect(result.exitCode, 1);
    expect(result.stderr, isEmpty);
    expect(result.stdout, runPubGet);
    expect(result.stdout, isNot(setLowerSdkConstraint));
  });

  test('non-pub-related error', () {
    p = project(mainSrc: 'var missing = "semicolon"\n');
    var result = p.runSync(['migrate', p.dirPath]);
    expect(result.exitCode, 1);
    expect(result.stderr, isEmpty);
    expect(result.stdout, runPubGet);
    expect(result.stdout, setLowerSdkConstraint);
  });
}
