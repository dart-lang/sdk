// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('avoid_private_typedef_functions', () {
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

    test('handles parts', () async {
      await cli.run([
        'test/_data/avoid_private_typedef_functions/lib.dart',
        'test/_data/avoid_private_typedef_functions/part.dart',
        '--rules=avoid_private_typedef_functions'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            'lib.dart 11:14 [lint] Avoid private typedef functions.',
            'part.dart 11:14 [lint] Avoid private typedef functions.',
            '2 files analyzed, 2 issues found',
          ]));
      expect(exitCode, 1);
    });
  });
}
