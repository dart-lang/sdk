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
  group('prefer_const_constructors_in_immutables', () {
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
        'test/_data/prefer_const_constructors_in_immutables',
        '--rules=prefer_const_constructors_in_immutables',
        '--packages',
        'test/rules/.mock_packages',
      ], LinterOptions());
      expect(
          collectingOut.trim(),
          stringContainsInOrder(
              ['D.c2(a)', '1 file analyzed, 1 issue found, in']));
      expect(exitCode, 1);
    });
  });
}
