// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:linter/src/cli.dart' as cli;
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('directives_ordering', () {
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

    test('dart_directives_go_first', () async {
      var packagesFilePath = File('.packages').absolute.path;
      await cli.run([
        '--packages',
        packagesFilePath,
        'test/_data/directives_ordering/dart_directives_go_first',
        '--rules=directives_ordering'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "Place 'dart:' imports before other imports.",
            "import 'dart:html';  // LINT",
            "Place 'dart:' imports before other imports.",
            "import 'dart:isolate';  // LINT",
            "Place 'dart:' exports before other exports.",
            "export 'dart:html';  // LINT",
            "Place 'dart:' exports before other exports.",
            "export 'dart:isolate';  // LINT",
            '2 files analyzed, 4 issues found, in'
          ]));
      expect(exitCode, 1);
    });

    test('package_directives_before_relative', () async {
      var packagesFilePath = File('.packages').absolute.path;
      await cli.run([
        '--packages',
        packagesFilePath,
        'test/_data/directives_ordering/package_directives_before_relative',
        '--rules=directives_ordering'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            "Place 'package:' imports before relative imports.",
            "import 'package:async/src/async_cache.dart'; // LINT",
            "Place 'package:' imports before relative imports.",
            "import 'package:yaml/yaml.dart'; // LINT",
            "Place 'package:' exports before relative exports.",
            "export 'package:async/src/async_cache.dart'; // LINT",
            "Place 'package:' exports before relative exports.",
            "export 'package:yaml/yaml.dart'; // LINT",
            '3 files analyzed, 4 issues found, in'
          ]));
      expect(exitCode, 1);
    });

    test('export_directives_after_import_directives', () async {
      var packagesFilePath = File('.packages').absolute.path;
      await cli.run([
        '--packages',
        packagesFilePath,
        'test/_data/directives_ordering/export_directives_after_import_directives',
        '--rules=directives_ordering'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            'Specify exports in a separate section after all imports.',
            "export 'dummy.dart';  // LINT",
            'Specify exports in a separate section after all imports.',
            "export 'dummy2.dart';  // LINT",
            '5 files analyzed, 2 issues found, in'
          ]));
      expect(exitCode, 1);
    });

    test('sort_directive_sections_alphabetically', () async {
      var packagesFilePath = File('.packages').absolute.path;
      await cli.run([
        '--packages',
        packagesFilePath,
        'test/_data/directives_ordering/sort_directive_sections_alphabetically',
        '--rules=directives_ordering'
      ]);
      expect(
          collectingOut.trim(),
          stringContainsInOrder([
            'Sort directive sections alphabetically.',
            "import 'dart:convert'; // LINT",
            'Sort directive sections alphabetically.',
            "import 'package:charcode/ascii.dart'; // LINT",
            'Sort directive sections alphabetically.',
            "import 'package:async/async.dart'; // LINT",
            'Sort directive sections alphabetically.',
            "import 'package:linter/src/formatter.dart'; // LINT",
            'Sort directive sections alphabetically.',
            "import 'dummy3.dart'; // LINT",
            'Sort directive sections alphabetically.',
            "import 'dummy2.dart'; // LINT",
            'Sort directive sections alphabetically.',
            "import 'dummy1.dart'; // LINT",
            'Sort directive sections alphabetically.',
            "export 'dart:convert'; // LINT",
            'Sort directive sections alphabetically.',
            "export 'package:charcode/ascii.dart'; // LINT",
            'Sort directive sections alphabetically.',
            "export 'package:async/async.dart'; // LINT",
            'Sort directive sections alphabetically.',
            "export 'package:linter/src/formatter.dart'; // LINT",
            'Sort directive sections alphabetically.',
            "export 'dummy1.dart'; // LINT",
            '5 files analyzed, 12 issues found, in'
          ]));
      expect(exitCode, 1);
    });

    test('lint_one_node_no_more_than_once', () async {
      var packagesFilePath = File('.packages').absolute.path;
      await cli.run([
        '--packages',
        packagesFilePath,
        'test/_data/directives_ordering/lint_one_node_no_more_than_once',
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
  });
}
