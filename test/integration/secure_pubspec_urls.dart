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
            '4:11 [lint] The url should only use secure protocols.',
            '6:16 [lint] The url should only use secure protocols.',
            '5:13 [lint] The url should only use secure protocols.',
            '15:12 [lint] The url should only use secure protocols.',
            '20:13 [lint] The url should only use secure protocols.',
            '25:10 [lint] The url should only use secure protocols.',
            '28:12 [lint] The url should only use secure protocols.',
            '32:12 [lint] The url should only use secure protocols.',
            '1 file analyzed, 8 issues found',
          ]));
      expect(exitCode, 1);
    });
  });
}
