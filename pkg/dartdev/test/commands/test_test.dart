// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
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

    final result = p.runSync(['test', '--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains(' tests in this package'));
    expect(result.stderr, isEmpty);
  });

  test('dart help test', () {
    p = project();

    final result = p.runSync(['help', 'test']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains(' tests in this package'));
    expect(result.stderr, isEmpty);
  });

  test('no pubspec.yaml', () {
    p = project();
    var pubspec = File(path.join(p.dirPath, 'pubspec.yaml'));
    pubspec.deleteSync();

    var result = p.runSync(['test']);

    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('No pubspec.yaml file found'));
    expect(result.exitCode, 65);
  });

  test('runs test', () {
    p = project();
    p.file('test/foo_test.dart', '''
import 'package:test/test.dart';

void main() {
  test('', () {
    expect(1,1);
  });
}
''');

    // An implicit `pub get` will happen.
    final result = p.runSync(['test', '--no-color', '--reporter', 'expanded']);
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('All tests passed!'));
    expect(result.exitCode, 0);
  });

  test('no package:test dependency', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    p.file('pubspec.yaml', '''
name: ${p.name}
environment:
  sdk: '>=2.10.0 <3.0.0'
''');
    p.file('test/foo_test.dart', '''
import 'package:test/test.dart';

void main() {
  test('', () {
    expect(1,1);
  });
}
''');

    final result = p.runSync(['test']);
    expect(result.exitCode, 65);
    expect(
      result.stdout,
      contains('You need to add a dependency on package:test'),
    );
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 65);

    final resultPubAdd = p.runSync(['pub', 'add', 'test']);

    expect(resultPubAdd.exitCode, 0);
    final result2 = p.runSync(['test', '--no-color', '--reporter', 'expanded']);
    expect(result2.stderr, isEmpty);
    expect(result2.stdout, contains('All tests passed!'));
    expect(result2.exitCode, 0);
  });

  test('has package:test dependency', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    p.file('test/foo_test.dart', '''
$dartVersionFilePrefix2_9

import 'package:test/test.dart';

void main() {
  test('', () {
    print('hello world');
  });
}
''');

    final result = p.runSync(['test', '--no-color', '--reporter', 'expanded']);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('All tests passed!'));
    expect(result.stderr, isEmpty);
  });

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

    final result = p.runSync(
      [
        '--enable-experiment=non-nullable',
        'test',
        '--no-color',
        '--reporter',
        'expanded',
      ],
    );
    expect(result.exitCode, 1);
  });
}
