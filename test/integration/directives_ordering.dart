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
  group('directives_ordering', () {
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

    test('dart_directives_go_first', () async {
      await cli.run([
        '$integrationTestDir/directives_ordering/dart_directives_go_first',
        '--rules=directives_ordering'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "import 'dart:html';  // LINT",
            "import 'dart:isolate';  // LINT",
            "export 'dart:html';  // LINT",
            "export 'dart:isolate';  // LINT",
            '2 files analyzed, 4 issues found, in'
          ]));
      expect(exitCode, 1);
    });

    test('package_directives_before_relative', () async {
      await cli.run([
        '$integrationTestDir/directives_ordering/package_directives_before_relative',
        '--rules=directives_ordering'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "import 'package:async/src/async_cache.dart'; // LINT",
            "import 'package:yaml/yaml.dart'; // LINT",
            "export 'package:async/src/async_cache.dart'; // LINT",
            "export 'package:yaml/yaml.dart'; // LINT",
            '3 files analyzed, 4 issues found, in'
          ]));
      expect(exitCode, 1);
    });

    test('export_directives_after_import_directives', () async {
      await cli.run([
        '$integrationTestDir/directives_ordering/export_directives_after_import_directives',
        '--rules=directives_ordering'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "export 'dummy.dart';  // LINT",
            "export 'dummy2.dart';  // LINT",
            '5 files analyzed, 2 issues found, in'
          ]));
      expect(exitCode, 1);
    });

    test('sort_directive_sections_alphabetically', () async {
      await cli.run([
        '$integrationTestDir/directives_ordering/sort_directive_sections_alphabetically',
        '--rules=directives_ordering'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "import 'dart:convert'; // LINT",
            "import 'package:collection/collection.dart'; // LINT",
            "import 'package:async/async.dart'; // LINT",
            "import 'package:linter/src/formatter.dart'; // LINT",
            "import 'dummy3.dart'; // LINT",
            "import 'dummy2.dart'; // LINT",
            "import 'dummy1.dart'; // LINT",
            "export 'dart:convert'; // LINT",
            "export 'package:collection/collection.dart'; // LINT",
            "export 'package:async/async.dart'; // LINT",
            "export 'package:linter/src/formatter.dart'; // LINT",
            "export 'dummy1.dart'; // LINT",
            '5 files analyzed, 12 issues found, in'
          ]));
      expect(exitCode, 1);
    });

    test('lint_one_node_no_more_than_once', () async {
      await cli.run([
        '$integrationTestDir/directives_ordering/lint_one_node_no_more_than_once',
        '--rules=directives_ordering'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "Place 'package:' imports before relative imports.",
            "import 'package:async/async.dart';  // LINT",
            '2 files analyzed, 1 issue found, in'
          ]));
      expect(exitCode, 1);
    });

    test('match_analyzer_organize_directives', () async {
      await cli.run([
        '$integrationTestDir/directives_ordering/match_analyzer_organize_directives',
        '--rules=directives_ordering'
      ]);
      // There are errors in the file due to missing imports, but no lints
      // should fire.
      expect(collectingOut.trim(), isNot(contains('[lint]')));
    });
  });
}
