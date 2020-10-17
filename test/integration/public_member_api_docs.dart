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
            'a.dart 6:16 [lint] Document all public members.',
            'a.dart 7:11 [lint] Document all public members.',
            'a.dart 8:9 [lint] Document all public members.',
            'a.dart 12:16 [lint] Document all public members.',
            'a.dart 20:11 [lint] Document all public members.',
            'a.dart 24:16 [lint] Document all public members.',
            'a.dart 27:3 [lint] Document all public members.',
            'a.dart 28:5 [lint] Document all public members.',
            'a.dart 30:7 [lint] Document all public members.',
            'a.dart 32:7 [lint] Document all public members.',
            'a.dart 40:3 [lint] Document all public members.',
            'a.dart 42:3 [lint] Document all public members.',
            'a.dart 50:9 [lint] Document all public members.',
            'a.dart 58:14 [lint] Document all public members.',
            'a.dart 64:6 [lint] Document all public members.',
            'a.dart 66:3 [lint] Document all public members.',
            'a.dart 85:1 [lint] Document all public members.',
            'a.dart 90:5 [lint] Document all public members.',
            'a.dart 94:5 [lint] Document all public members.',
            'a.dart 109:1 [lint] Document all public members.',
            'a.dart 110:11 [lint] Document all public members.',
            'a.dart 117:14 [lint] Document all public members.',
            'a.dart 130:1 [lint] Document all public members.',
            '3 files analyzed, 24 issues found',
          ]));
      expect(exitCode, 1);
    });
  });
}
