// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';
import '../test_constants.dart';

void main() {
  group('public_member_api_docs', () {
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
    test('lint lib/ sources and non-lib/ sources', () async {
      await cli.run([
        '$integrationTestDir/public_member_api_docs',
        '--rules=public_member_api_docs'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            'a.dart 7:7 [lint]',
            'a.dart 8:16 [lint]',
            'a.dart 9:11 [lint]',
            'a.dart 10:9 [lint]',
            'a.dart 14:16 [lint]',
            'a.dart 22:11 [lint]',
            'a.dart 26:16 [lint]',
            'a.dart 29:3 [lint]',
            'a.dart 30:5 [lint]',
            'a.dart 32:8 [lint]',
            'a.dart 34:8 [lint]',
            'a.dart 42:3 [lint]',
            'a.dart 44:3 [lint]',
            'a.dart 52:9 [lint]',
            'a.dart 60:14 [lint]',
            'a.dart 66:6 [lint]',
            'a.dart 68:3 [lint]',
            'a.dart 87:1 [lint]',
            'a.dart 92:5 [lint]',
            'a.dart 96:6 [lint]',
            'a.dart 111:11 [lint]',
            'a.dart 112:11 [lint]',
            'a.dart 119:14 [lint]',
            'a.dart 132:9 [lint]',
            'a.dart 134:7 [lint]',
            'a.dart 135:9 [lint]',
          ]));
      expect(exitCode, 1);
    });
  });
}
