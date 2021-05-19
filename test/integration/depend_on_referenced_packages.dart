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
  group('Depend on referenced packages', () {
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

    test('lints files under bin', () async {
      var packagesFilePath = File('.packages').absolute.path;
      await cli.run([
        '--packages',
        packagesFilePath,
        '$integrationTestDir/depend_on_referenced_packages/bin',
        '--rules=depend_on_referenced_packages'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "Depend on referenced packages.",
            "import 'package:test/test.dart'; // LINT",
            "Depend on referenced packages.",
            "import 'package:matcher/matcher.dart'; // LINT",
            "Depend on referenced packages.",
            "export 'package:test/test.dart'; // LINT",
            "Depend on referenced packages.",
            "export 'package:matcher/matcher.dart'; // LINT",
          ]));
      expect(exitCode, 1);
    });

    test('lints files under lib', () async {
      var packagesFilePath = File('.packages').absolute.path;
      await cli.run([
        '--packages',
        packagesFilePath,
        '$integrationTestDir/depend_on_referenced_packages/lib',
        '--rules=depend_on_referenced_packages'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "Depend on referenced packages.",
            "import 'package:test/test.dart'; // LINT",
            "Depend on referenced packages.",
            "import 'package:matcher/matcher.dart'; // LINT",
            "Depend on referenced packages.",
            "export 'package:test/test.dart'; // LINT",
            "Depend on referenced packages.",
            "export 'package:matcher/matcher.dart'; // LINT",
          ]));
      expect(exitCode, 1);
    });

    test('lints files under test', () async {
      var packagesFilePath = File('.packages').absolute.path;
      await cli.run([
        '--packages',
        packagesFilePath,
        '$integrationTestDir/depend_on_referenced_packages/test',
        '--rules=depend_on_referenced_packages'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "Depend on referenced packages.",
            "import 'package:matcher/matcher.dart'; // LINT",
            "Depend on referenced packages.",
            "export 'package:matcher/matcher.dart'; // LINT",
          ]));
      expect(exitCode, 1);
    });
  });
}
