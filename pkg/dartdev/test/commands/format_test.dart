// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('format', format);
}

void format() {
  TestProject p;

  tearDown(() => p?.dispose());

  test('--help', () {
    p = project();
    var result = p.runSync('format', ['--help']);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('Format one or more Dart files.'));
    expect(result.stdout, contains('Usage: dartdev format [arguments]'));
    expect(
        result.stdout, contains('Run "dartdev help" to see global options.'));
  });
}
