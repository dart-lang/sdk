// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('prefer_asserts_in_initializer_lists', () {
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
      await cli.runLinter([
        'test/_data/prefer_asserts_in_initializer_lists',
        '--rules=prefer_asserts_in_initializer_lists'
      ], LinterOptions());
      expect(
          collectingOut.trim(),
          stringContainsInOrder(
              ['lib.dart 6:5', '1 file analyzed, 1 issue found, in']));
      expect(exitCode, 1);
    });
  });
}
