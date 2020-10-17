// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('lines_longer_than_80_chars', () {
    final currentOut = outSink;
    final collectingOut = CollectingSink();
    setUp(() {
      exitCode = 0;
      outSink = collectingOut;
    });
    tearDown(() {
      collectingOut.buffer.clear();
      outSink = currentOut;
      exitCode = 0;
    });

    test('only throw errors', () async {
      await cli.run([
        'test/_data/lines_longer_than_80_chars',
        '--rules=lines_longer_than_80_chars'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            'a.dart 3:1 [lint] AVOID lines longer than 80 characters',
            'a.dart 7:1 [lint] AVOID lines longer than 80 characters',
            'a.dart 16:1 [lint] AVOID lines longer than 80 characters',
            'a.dart 21:1 [lint] AVOID lines longer than 80 characters',
            '1 file analyzed, 4 issues found, in'
          ]));
      expect(exitCode, 1);
    });
  });
}
