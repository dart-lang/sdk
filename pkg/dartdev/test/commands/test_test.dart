// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('test', defineTest, timeout: longTimeout);
}

void defineTest() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('--help', () {
    p = project();

    var result = p.runSync('pub', ['get', '--offline']);
    expect(result.exitCode, 0);

    result = p.runSync('test', ['--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Runs tests in this package'));
    expect(result.stderr, isEmpty);
  }, skip: 'https://github.com/dart-lang/sdk/issues/40854');

  test('no dependency', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    p.file('pubspec.yaml', 'name: ${p.name}\n');

    var result = p.runSync('pub', ['get', '--offline']);
    expect(result.exitCode, 0);

    result = p.runSync('test', []);
    expect(result.exitCode, 65);
    expect(
      result.stdout,
      contains(
        'In order to run tests, you need to add a dependency on package:test',
      ),
    );
  }, skip: 'https://github.com/dart-lang/sdk/issues/40854');

  test('has dependency', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    p.file('test/foo_test.dart', '''
import 'package:test/test.dart';

void main() {
  test('', () {
    print('hello world');
  });
}
''');

    var result = p.runSync('pub', ['get', '--offline']);
    expect(result.exitCode, 0);

    result = p.runSync('test', ['--no-color', '--reporter', 'expanded']);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('All tests passed!'));
    expect(result.stderr, isEmpty);
  }, skip: 'https://github.com/dart-lang/sdk/issues/40854');

  test('--enable-experiment', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    p.file('test/foo_test.dart', '''
import 'package:test/test.dart';

void main() {
  test('', () {
    int a;
    a = null;
    print('a is \$a.');
  });
}
''');

    var result = p.runSync('pub', ['get', '--offline']);
    expect(result.exitCode, 0);

    result = p.runSync('--enable-experiment=non-nullable',
        ['test', '--no-color', '--reporter', 'expanded']);
    expect(result.exitCode, 1);
  }, skip: 'https://github.com/dart-lang/sdk/issues/40854');
}
