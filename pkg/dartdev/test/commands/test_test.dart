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

    var result = p.runSync('pub', ['get']);
    expect(result.exitCode, 0);

    result = p.runSync('test', ['--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains(' tests in this package'));
    expect(result.stderr, isEmpty);
  });

  test('dart help test', () {
    p = project();

    var result = p.runSync('pub', ['get']);
    expect(result.exitCode, 0);

    result = p.runSync('help', ['test']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains(' tests in this package'));
    expect(result.stderr, isEmpty);
  });

  test('no pubspec.yaml', () {
    p = project();
    var pubspec = File(path.join(p.dirPath, 'pubspec.yaml'));
    pubspec.deleteSync();

    var result = p.runSync('help', ['test']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('No pubspec.yaml file found'));
    expect(result.stderr, isEmpty);
  });

  test('no .dart_tool/package_config.json', () {
    p = project();

    var result = p.runSync('help', ['test']);

    expect(result.exitCode, 0);
    expect(result.stdout,
        contains('No .dart_tool/package_config.json file found'));
    expect(result.stderr, isEmpty);
  });

  test('no package:test dependency', () {
    p = project(mainSrc: 'int get foo => 1;\n');
    p.file('pubspec.yaml', 'name: ${p.name}\n');

    var result = p.runSync('pub', ['get']);
    expect(result.exitCode, 0);

    result = p.runSync('test', []);
    expect(result.exitCode, 65);
    expect(
      result.stdout,
      contains('In order to run tests, you need to add a dependency'),
    );
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

    var result = p.runSync('pub', ['get']);
    expect(result.exitCode, 0);

    result = p.runSync('test', ['--no-color', '--reporter', 'expanded']);
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

    var result = p.runSync('pub', ['get']);
    expect(result.exitCode, 0);

    result = p.runSync('--enable-experiment=non-nullable',
        ['test', '--no-color', '--reporter', 'expanded']);
    expect(result.exitCode, 1);
  });
}
