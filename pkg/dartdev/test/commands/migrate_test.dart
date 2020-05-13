// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A set of integration tests for `dart migrate`.
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('migrate', defineMigrateTests, timeout: longTimeout);
}

bool _nnbdIsEnabled = true;

void defineMigrateTests() {
  final didYouForgetToRunPubGet = contains('Did you forget to run "pub get"?');

  TestProject p;

  tearDown(() => p?.dispose());

  test('--help', () {
    p = project();
    var result = p.runSync('migrate', ['--help']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(result.stdout,
        contains('Perform a null safety migration on a project or package.'));
    expect(result.stdout,
        contains('Usage: dart migrate [arguments] [project or directory]'));
  });

  test('directory implicit', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = p.runSync(
        'migrate',
        [
          '--no-web-preview',
          '--server-path=${p.absolutePathToAnalysisServerFile}'
        ],
        workingDir: p.dirPath);
    expect(result.exitCode, _nnbdIsEnabled ? 0 : 2);
    expect(result.stderr, _nnbdIsEnabled ? isEmpty : isNotEmpty);
    expect(result.stdout, contains('Generating migration suggestions'));
  });

  test('directory explicit', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = p.runSync('migrate', [
      '--no-web-preview',
      '--server-path=${p.absolutePathToAnalysisServerFile}',
      p.dirPath
    ]);
    expect(result.exitCode, _nnbdIsEnabled ? 0 : 2);
    expect(result.stderr, _nnbdIsEnabled ? isEmpty : isNotEmpty);
    expect(result.stdout, contains('Generating migration suggestions'));
  });

  test('bad directory', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    var result = p.runSync('migrate',
        ['--server-path=${p.absolutePathToAnalysisServerFile}', 'foo_bar_dir']);
    expect(result.exitCode, 64);
    expect(result.stderr,
        contains('not found; please provide a path to a package or directory'));
    expect(result.stdout, isEmpty);
  });

  test('pub get needs running', () {
    p = project(mainSrc: 'import "package:foo/foo.dart";\n');
    var result = p.runSync('migrate',
        ['--server-path=${p.absolutePathToAnalysisServerFile}', p.dirPath]);
    expect(result.exitCode, 1);
    expect(result.stderr, isEmpty);
    expect(result.stdout, didYouForgetToRunPubGet);
  });

  test('non-pub-related error', () {
    p = project(mainSrc: 'var missing = "semicolon"\n');
    var result = p.runSync('migrate',
        ['--server-path=${p.absolutePathToAnalysisServerFile}', p.dirPath]);
    expect(result.exitCode, 1);
    expect(result.stderr, isEmpty);
    expect(result.stdout, isNot(didYouForgetToRunPubGet));
  });
}
