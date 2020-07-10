// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('run', run, timeout: longTimeout);
}

void run() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('--help', () {
    p = project();
    var result = p.runSync('run', ['--help']);

    expect(result.stdout, isEmpty);
    expect(result.stderr, contains('Executes the Dart script'));
    expect(result.stderr, contains('Common VM flags:'));
    expect(result.exitCode, 0);
  });

  test("'Hello World'", () {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    ProcessResult result = p.runSync('run', [p.relativeFilePath]);

    expect(result.stdout, contains('Hello World'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('--enable-experiment', () {
    p = project();
    p.file('main.dart', "void main() { int a; a = null; print('a is \$a.'); }");
    var result =
        p.runSync('--enable-experiment=non-nullable', ['run', 'main.dart']);

    expect(result.exitCode, 254);
    expect(result.stdout, isEmpty);
    expect(
        result.stderr,
        contains("A value of type 'Null' can't be assigned to a variable of "
            "type 'int'"));
  });

  test('no such file', () {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    ProcessResult result =
        p.runSync('run', ['no/such/file/${p.relativeFilePath}']);

    expect(result.stderr, isNotEmpty);
    expect(result.exitCode, isNot(0));
  });

  test('implicit packageName.dart', () {
    // TODO(jwren) circle back to reimplement this test if possible, the file
    // name (package name) will be the name of the temporary directory on disk
    p = project(mainSrc: "void main() { print('Hello World'); }");
    p.file('bin/main.dart', "void main() { print('Hello main.dart'); }");
    ProcessResult result = p.runSync('run', []);

    expect(result.stdout, contains('Hello main.dart'));
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  }, skip: true);

  // Could not find the implicit file to run: bin
  test('missing implicit packageName.dart', () {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    p.file('bin/foo.dart', "void main() { print('Hello main.dart'); }");
    ProcessResult result = p.runSync('run', []);

    expect(result.stdout, isEmpty);
    expect(result.stderr,
        contains('Could not find the implicit file to run: bin'));
    expect(result.exitCode, 255);
  });
}
