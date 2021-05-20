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
      await cli.run([
        '--packages',
        '$integrationTestDir/depend_on_referenced_packages/_packages',
        '$integrationTestDir/depend_on_referenced_packages/bin',
        '--rules=depend_on_referenced_packages'
      ]);
      var output = collectingOut.trim();
      expect(
          output,
          stringContainsInOrder([
            "Depend on referenced packages.",
            "import 'package:private_dep/private_dep.dart'; // LINT",
            "Depend on referenced packages.",
            "import 'package:transitive_dep/transitive_dep.dart'; // LINT",
            "Depend on referenced packages.",
            "export 'package:private_dep/private_dep.dart'; // LINT",
            "Depend on referenced packages.",
            "export 'package:transitive_dep/transitive_dep.dart'; // LINT",
          ]));
      expect(output, isNot(contains('// OK')));
      expect(exitCode, 1);
    });

    test('lints files under lib', () async {
      await cli.run([
        '--packages',
        '$integrationTestDir/depend_on_referenced_packages/_packages',
        '$integrationTestDir/depend_on_referenced_packages/lib',
        '--rules=depend_on_referenced_packages'
      ]);
      var output = collectingOut.trim();
      expect(
          output,
          stringContainsInOrder([
            "Depend on referenced packages.",
            "import 'package:private_dep/private_dep.dart'; // LINT",
            "Depend on referenced packages.",
            "import 'package:transitive_dep/transitive_dep.dart'; // LINT",
            "Depend on referenced packages.",
            "export 'package:private_dep/private_dep.dart'; // LINT",
            "Depend on referenced packages.",
            "export 'package:transitive_dep/transitive_dep.dart'; // LINT",
          ]));
      expect(output, isNot(contains('// OK')));
      expect(exitCode, 1);
    });

    test('lints files under test', () async {
      await cli.run([
        '--packages',
        '$integrationTestDir/depend_on_referenced_packages/_packages',
        '$integrationTestDir/depend_on_referenced_packages/test',
        '--rules=depend_on_referenced_packages'
      ]);
      var output = collectingOut.trim();
      expect(
          output,
          stringContainsInOrder([
            "Depend on referenced packages.",
            "import 'package:transitive_dep/transitive_dep.dart'; // LINT",
            "Depend on referenced packages.",
            "export 'package:transitive_dep/transitive_dep.dart'; // LINT",
          ]));
      expect(output, isNot(contains('// OK')));
      expect(exitCode, 1);
    });
  });
}
