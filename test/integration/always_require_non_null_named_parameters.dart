// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';
import '../test_constants.dart';

void main() {
  group('always_require_non_null_named_parameters', () {
    var currentOut = outSink;
    var collectingOut = CollectingSink();
    setUp(() {
      noSoundNullSafety = false;
      exitCode = 0;
      outSink = collectingOut;
    });
    tearDown(() {
      noSoundNullSafety = true;
      collectingOut.buffer.clear();
      outSink = currentOut;
      exitCode = 0;
    });

    test('only throw errors', () async {
      await cli.runLinter([
        '$integrationTestDir/always_require_non_null_named_parameters',
        '--rules=always_require_non_null_named_parameters',
      ], LinterOptions());
      expect(
          collectingOut.trim(),
          stringContainsInOrder(
              ['b, // LINT', '1 file analyzed, 1 issue found, in']));
      expect(exitCode, 1);
    });
  });
}
