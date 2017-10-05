// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../bin/linter.dart' as dartlint;
import 'mocks.dart';

main() {
  defineTests();
}

defineTests() {
  group('integration', () {
    group('p2', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });
      group('config', () {
        test('excludes', () async {
          await dartlint
              .main(['test/_data/p2', '-c', 'test/_data/p2/lintconfig.yaml']);
          expect(exitCode, 1);
          expect(
              collectingOut.trim(),
              stringContainsInOrder(
                  ['4 files analyzed, 1 issue found (2 filtered), in']));
        });
        test('overrrides', () async {
          await dartlint
              .main(['test/_data/p2', '-c', 'test/_data/p2/lintconfig2.yaml']);
          expect(exitCode, 0);
          expect(collectingOut.trim(),
              stringContainsInOrder(['4 files analyzed, 0 issues found, in']));
        });
        test('default', () async {
          await dartlint.main(['test/_data/p2']);
          expect(exitCode, 1);
          expect(collectingOut.trim(),
              stringContainsInOrder(['4 files analyzed, 3 issues found, in']));
        });
      });
    });
    group('p3', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() => outSink = collectingOut);
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
      });
      test('bad pubspec', () async {
        await dartlint.main(['test/_data/p3', 'test/_data/p3/_pubpspec.yaml']);
        expect(collectingOut.trim(),
            startsWith('1 file analyzed, 0 issues found, in'));
      });
    });
    group('p4', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() => outSink = collectingOut);
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
      });
      test('no warnings due to bad canonicalization', () async {
        var packagesFilePath =
            new File('test/_data/p4/_packages').absolute.path;
        await dartlint.runLinter(
            ['--packages', packagesFilePath, 'test/_data/p4'],
            new LinterOptions([]));
        expect(collectingOut.trim(),
            startsWith('3 files analyzed, 0 issues found, in'));
      });
    });

    group('p5', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
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
          await dartlint
              .main(['test/_data/p5', '--packages', 'test/_data/p5/_packages']);
          // Should have 0 issues.
          expect(exitCode, 0);
        });
      });
    });

    group('overridden_fields', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      // https://github.com/dart-lang/linter/issues/246
      test('overrides across libraries', () async {
        await dartlint.main(
            ['test/_data/overridden_fields', '--rules', 'overridden_fields']);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder(
                ['int public;', '2 files analyzed, 1 issue found, in']));
      });
    });

    group('close_sinks', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('close sinks', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await dartlint.main([
          '--packages',
          packagesFilePath,
          'test/_data/close_sinks',
          '--rules=close_sinks'
        ]);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'IOSink _sinkA; // LINT',
              'IOSink _sinkSomeFunction; // LINT',
              '1 file analyzed, 2 issues found, in'
            ]));
      });
    });

    group('cancel_subscriptions', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
      setUp(() {
        exitCode = 0;
        outSink = collectingOut;
      });
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
        exitCode = 0;
      });

      test('cancel subscriptions', () async {
        await dartlint.main([
          'test/_data/cancel_subscriptions',
          '--rules=cancel_subscriptions'
        ]);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'StreamSubscription _subscriptionA; // LINT',
              'StreamSubscription _subscriptionF; // LINT',
              '1 file analyzed, 3 issues found, in'
            ]));
      });
    });

    group('directives_ordering', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
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
        var packagesFilePath = new File('.packages').absolute.path;
        await dartlint.main([
          '--packages',
          packagesFilePath,
          'test/_data/directives_ordering/dart_directives_go_first',
          '--rules=directives_ordering'
        ]);
        expect(exitCode, 1);
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
      });

      test('package_directives_before_relative', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await dartlint.main([
          '--packages',
          packagesFilePath,
          'test/_data/directives_ordering/package_directives_before_relative',
          '--rules=directives_ordering'
        ]);
        expect(exitCode, 1);
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
      });

      test('third_party_package_directives_before_own', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await dartlint.main([
          '--packages',
          packagesFilePath,
          'test/_data/directives_ordering/third_party_package_directives_before_own',
          '--rules=directives_ordering'
        ]);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              "Place 'third-party' 'package:' imports before other imports.",
              "import 'package:async/async.dart';  // LINT",
              "Place 'third-party' 'package:' imports before other imports.",
              "import 'package:yaml/yaml.dart';  // LINT",
              "Place 'third-party' 'package:' exports before other exports.",
              "export 'package:async/async.dart';  // LINT",
              "Place 'third-party' 'package:' exports before other exports.",
              "export 'package:yaml/yaml.dart';  // LINT",
              '1 file analyzed, 4 issues found, in'
            ]));
      });

      test('export_directives_after_import_directives', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await dartlint.main([
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
        var packagesFilePath = new File('.packages').absolute.path;
        await dartlint.main([
          '--packages',
          packagesFilePath,
          'test/_data/directives_ordering/sort_directive_sections_alphabetically',
          '--rules=directives_ordering'
        ]);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'Sort directive sections alphabetically.',
              "import 'dart:convert'; // LINT",
              'Sort directive sections alphabetically.',
              "import 'package:charcode/ascii.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "import 'package:ansicolor/ansicolor.dart'; // LINT",
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
              "export 'package:ansicolor/ansicolor.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "export 'package:linter/src/formatter.dart'; // LINT",
              'Sort directive sections alphabetically.',
              "export 'dummy1.dart'; // LINT",
              '5 files analyzed, 12 issues found, in'
            ]));
      });

      test('lint_one_node_no_more_than_once', () async {
        var packagesFilePath = new File('.packages').absolute.path;
        await dartlint.main([
          '--packages',
          packagesFilePath,
          'test/_data/directives_ordering/lint_one_node_no_more_than_once',
          '--rules=directives_ordering'
        ]);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              "Place 'package:' imports before relative imports.",
              "import 'package:async/async.dart';  // LINT",
              '2 files analyzed, 1 issue found, in'
            ]));
      });
    });

    group('only_throw_errors', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
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
        await dartlint.main(
            ['test/_data/only_throw_errors', '--rules=only_throw_errors']);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              "throw 'hello world!'; // LINT",
              'throw null; // LINT',
              'throw 7; // LINT',
              'throw new Object(); // LINT',
              'throw returnString(); // LINT',
              '1 file analyzed, 5 issues found, in'
            ]));
      });
    });

    group('always_require_non_null_named_parameters', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
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
        await dartlint.runLinter([
          'test/_data/always_require_non_null_named_parameters',
          '--rules=always_require_non_null_named_parameters'
        ], new LinterOptions()..enableAssertInitializer = true);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder(
                ['b, // LINT', '1 file analyzed, 1 issue found, in']));
      });
    });

    group('prefer_asserts_in_initializer_lists', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
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
        await dartlint.runLinter([
          'test/_data/prefer_asserts_in_initializer_lists',
          '--rules=prefer_asserts_in_initializer_lists'
        ], new LinterOptions()..enableAssertInitializer = true);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder(
                ['lib.dart 6:5', '1 file analyzed, 1 issue found, in']));
      });
    });

    group('prefer_const_constructors_in_immutables', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();
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
        await dartlint.runLinter([
          'test/_data/prefer_const_constructors_in_immutables',
          '--rules=prefer_const_constructors_in_immutables'
        ], new LinterOptions()..enableAssertInitializer = true);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder(
                ['D.c2(a)', '1 file analyzed, 1 issue found, in']));
      });
    });

    group('public_member_api_docs', () {
      IOSink currentOut = outSink;
      CollectingSink collectingOut = new CollectingSink();

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
        var packagesFilePath = new File('.packages').absolute.path;
        await dartlint.main([
          '--packages',
          packagesFilePath,
          'test/_data/public_member_api_docs',
          '--rules=public_member_api_docs'
        ]);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder([
              'lib/a.dart 7:16 [lint] Document all public members',
              'lib/a.dart 15:11 [lint] Document all public members',
              'lib/a.dart 19:16 [lint] Document all public members',
              'lib/a.dart 22:3 [lint] Document all public members',
              'lib/a.dart 23:5 [lint] Document all public members',
              'lib/a.dart 25:7 [lint] Document all public members',
              'lib/a.dart 27:7 [lint] Document all public members',
              'lib/a.dart 35:3 [lint] Document all public members',
              'lib/a.dart 37:3 [lint] Document all public members',
              'lib/a.dart 45:9 [lint] Document all public members',
              'lib/a.dart 53:14 [lint] Document all public members',
              'lib/a.dart 59:6 [lint] Document all public members',
              'lib/a.dart 61:3 [lint] Document all public members',
              'lib/a.dart 80:1 [lint] Document all public members',
              'lib/a.dart 85:5 [lint] Document all public members',
              'lib/a.dart 89:5 [lint] Document all public members',
              '3 files analyzed, 16 issues found'
            ]));
      });
    });

    group('examples', () {
      test('all.yaml', () {
        String src = readFile('example/all.yaml');

        Map<String, YamlNode> options = _getOptionsFromString(src);
        var configuredLints =
            ((options['linter'] as YamlMap)['rules'] as YamlList);

        registerLintRules();
        expect(
            configuredLints,
            unorderedEquals(
                Analyzer.facade.registeredRules.map((r) => r.name)));
      });
    });
  });
}

/// Provide the options found in [optionsSource].
Map<String, YamlNode> _getOptionsFromString(String optionsSource) {
  Map<String, YamlNode> options = <String, YamlNode>{};
  if (optionsSource == null) {
    return options;
  }

  YamlNode doc = loadYamlNode(optionsSource);

  // Empty options.
  if (doc is YamlScalar && doc.value == null) {
    return options;
  }
  if ((doc != null) && (doc is! YamlMap)) {
    throw new Exception(
        'Bad options file format (expected map, got ${doc.runtimeType})');
  }
  if (doc is YamlMap) {
    doc.nodes.forEach((k, YamlNode v) {
      var key;
      if (k is YamlScalar) {
        key = k.value;
      }
      if (key is! String) {
        throw new Exception(
            'Bad options file format (expected String scope key, '
            'got ${k.runtimeType})');
      }
      if (v != null && v is! YamlNode) {
        throw new Exception('Bad options file format (expected Node value, '
            'got ${v.runtimeType}: `${v.toString()}`)');
      }
      options[key] = v;
    });
  }
  return options;
}

class MockProcessResult extends Mock implements ProcessResult {}
