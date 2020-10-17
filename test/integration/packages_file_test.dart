// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('p5', () {
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
    group('.packages', () {
      test('basic', () async {
        // Requires .packages to analyze cleanly.
        await cli.runLinter(
            ['test/_data/p5', '--packages', 'test/_data/p5/_packages'],
            LinterOptions([]));
        // Should have 0 issues.
        expect(exitCode, 0);
      });
    });
  });
}
