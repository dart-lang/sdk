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
  group('avoid_renaming_method_parameters', () {
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
        '--packages',
        '$integrationTestDir/avoid_renaming_method_parameters/_packages',
        '$integrationTestDir/avoid_renaming_method_parameters',
        '--rules=avoid_renaming_method_parameters'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "a.dart 31:6 [lint] The parameter 'aa' should have the name 'a' to match the name used in the overridden method.",
            "a.dart 33:12 [lint] The parameter 'aa' should have the name 'a' to match the name used in the overridden method.",
            "a.dart 34:9 [lint] The parameter 'bb' should have the name 'b' to match the name used in the overridden method.",
            "a.dart 36:7 [lint] The parameter 'aa' should have the name 'a' to match the name used in the overridden method.",
            "a.dart 37:6 [lint] The parameter 'aa' should have the name 'a' to match the name used in the overridden method.",
            "a.dart 38:6 [lint] The parameter 'aa' should have the name 'a' to match the name used in the overridden method.",
            '3 files analyzed, 6 issues found',
          ]));
      expect(exitCode, 1);
    });
  });
}
