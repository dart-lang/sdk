// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';
import '../test_constants.dart';

void main() {
  group('secure_pubspec_urls', () {
    var currentOut = outSink;
    var collectingOut = CollectingSink();

    setUp(() {
      exitCode = 0;
      outSink = collectingOut;
    });

    tearDown(() {
      collectingOut.buffer.clear();
      outSink = currentOut;
      exitCode = 0;
    });

    test('finds http urls', () async {
      await cli.run([
        '$integrationTestDir/secure_pubspec_urls',
        '--rules=secure_pubspec_urls',
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            '4:11 [lint]',
            '6:16 [lint]',
            '5:13 [lint]',
            '15:12 [lint]',
            '20:13 [lint]',
            '25:10 [lint]',
            '28:12 [lint]',
            '32:12 [lint]',
            '1 file analyzed, 8 issues found',
          ]));
      expect(exitCode, 1);
    });
  });
}
