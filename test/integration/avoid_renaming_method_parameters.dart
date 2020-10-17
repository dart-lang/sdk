// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('avoid_renaming_method_parameters', () {
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
      await cli.run([
        '--packages',
        'test/_data/avoid_renaming_method_parameters/_packages',
        'test/_data/avoid_renaming_method_parameters',
        '--rules=avoid_renaming_method_parameters'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            'a.dart 29:6 [lint] Don\'t rename parameters of overridden methods.',
            'a.dart 31:12 [lint] Don\'t rename parameters of overridden methods.',
            'a.dart 32:9 [lint] Don\'t rename parameters of overridden methods.',
            'a.dart 34:7 [lint] Don\'t rename parameters of overridden methods.',
            'a.dart 35:6 [lint] Don\'t rename parameters of overridden methods.',
            'a.dart 36:6 [lint] Don\'t rename parameters of overridden methods.',
            '3 files analyzed, 6 issues found',
          ]));
      expect(exitCode, 1);
    });
  });
}
