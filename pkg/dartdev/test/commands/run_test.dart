// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('run', run);
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

  test('no such file', () {
    p = project(mainSrc: "void main() { print('Hello World'); }");
    ProcessResult result =
        p.runSync('run', ['no/such/file/' + p.relativeFilePath]);

    expect(result.stderr, isNotEmpty);
    expect(result.exitCode, isNot(0));
  });
}
