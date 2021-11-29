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
            'pubspec.yaml 4:11 [lint] The url should only only use secure protocols.',
            'pubspec.yaml 14:12 [lint] The url should only only use secure protocols.',
            'pubspec.yaml 19:13 [lint] The url should only only use secure protocols.',
            'pubspec.yaml 27:12 [lint] The url should only only use secure protocols.',
            'pubspec.yaml 31:12 [lint] The url should only only use secure protocols.',
            '1 file analyzed, 5 issues found',
          ]));
      expect(exitCode, 1);
    });
  });
}
