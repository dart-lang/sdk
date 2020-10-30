// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('public_member_api_docs', () {
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

    test('lint lib/ sources and non-lib/ sources', () async {
      var packagesFilePath = File('.packages').absolute.path;
      await cli.run([
        '--packages',
        packagesFilePath,
        'test/_data/public_member_api_docs',
        '--rules=public_member_api_docs'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            'a.dart 8:16 [lint] Document all public members.',
            'a.dart 9:11 [lint] Document all public members.',
            'a.dart 10:9 [lint] Document all public members.',
            'a.dart 14:16 [lint] Document all public members.',
            'a.dart 22:11 [lint] Document all public members.',
            'a.dart 26:16 [lint] Document all public members.',
            'a.dart 29:3 [lint] Document all public members.',
            'a.dart 30:5 [lint] Document all public members.',
            'a.dart 32:7 [lint] Document all public members.',
            'a.dart 34:7 [lint] Document all public members.',
            'a.dart 42:3 [lint] Document all public members.',
            'a.dart 44:3 [lint] Document all public members.',
            'a.dart 52:9 [lint] Document all public members.',
            'a.dart 60:14 [lint] Document all public members.',
            'a.dart 66:6 [lint] Document all public members.',
            'a.dart 68:3 [lint] Document all public members.',
            'a.dart 87:1 [lint] Document all public members.',
            'a.dart 92:5 [lint] Document all public members.',
            'a.dart 96:5 [lint] Document all public members.',
            'a.dart 111:1 [lint] Document all public members.',
            'a.dart 112:11 [lint] Document all public members.',
            'a.dart 119:14 [lint] Document all public members.',
            'a.dart 132:1 [lint] Document all public members.',
            '3 files analyzed, 24 issues found',
          ]));
      expect(exitCode, 1);
    });
  });
}
