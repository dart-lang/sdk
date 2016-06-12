// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.integration;

import 'dart:convert';
import 'dart:io';

import 'package:linter/src/config.dart';
import 'package:linter/src/io.dart';
import 'package:linter/src/linter.dart';
import 'package:mockito/mockito.dart';
import 'package:unittest/unittest.dart';

import '../bin/linter.dart' as dartlint;
import 'mocks.dart';

main() {
  groupSep = ' | ';

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
        test('excludes', () {
          dartlint
              .main(['test/_data/p2', '-c', 'test/_data/p2/lintconfig.yaml']);
          expect(exitCode, 1);
          expect(
              collectingOut.trim(),
              stringContainsInOrder(
                  ['4 files analyzed, 1 issue found (2 filtered), in']));
        });
        test('overrrides', () {
          dartlint
              .main(['test/_data/p2', '-c', 'test/_data/p2/lintconfig2.yaml']);
          expect(exitCode, 0);
          expect(collectingOut.trim(),
              stringContainsInOrder(['4 files analyzed, 0 issues found, in']));
        });
        test('default', () {
          dartlint.main(['test/_data/p2']);
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
      test('bad pubspec', () {
        dartlint.main(['test/_data/p3', 'test/_data/p3/_pubpspec.yaml']);
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
      test('no warnings due to bad canonicalization', () {
        var libPath = new Directory('test/_data/p4/lib').absolute.path;
        var options = new LinterOptions([]);
        options.runPubList = (_) {
          var processResult = new MockProcessResult();
          when(processResult.exitCode).thenReturn(0);
          when(processResult.stderr).thenReturn('');
          when(processResult.stdout).thenReturn(JSON.encode({
            'packages': {'p4': libPath},
            'input_files': []
          }));
          return processResult;
        };
        dartlint.runLinter(['test/_data/p4'], options);
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
        test('basic', () {
          // Requires .packages to analyze cleanly.
          dartlint
              .main(['test/_data/p5', '--packages', 'test/_data/p5/_packages']);
          // Should have 0 issues.
          expect(exitCode, 0);
        });
      });
    });

    group('p8', () {
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
        test('filtered', () {
          dartlint
              .main(['test/_data/p8', '-c', 'test/_data/p8/lintconfig.yaml']);
          expect(exitCode, 0);
          expect(
              collectingOut.trim(),
              stringContainsInOrder(
                  ['2 files analyzed, 0 issues found (1 filtered), in']));
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
      test('overrides across libraries', () {
        dartlint.main([
          'test/_data/overridden_fields',
          '-c',
          'test/_data/overridden_fields/lintconfig.yaml'
        ]);
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

      test('close sinks', () {
        dartlint.main([
          'test/_data/close_sinks',
          '--rules=close_sinks'
        ]);
        expect(exitCode, 1);
        expect(
            collectingOut.trim(),
            stringContainsInOrder(
                [
                  'IOSink _sinkA; // LINT',
                  'IOSink _sinkF; // LINT',
                  '1 file analyzed, 2 issues found, in'
                ]));
      });
    });

    group('examples', () {
      test('lintconfig.yaml', () {
        var src = readFile('example/lintconfig.yaml');
        var config = new LintConfig.parse(src);
        expect(config.fileIncludes, unorderedEquals(['foo/**']));
        expect(
            config.fileExcludes, unorderedEquals(['**/_data.dart', 'test/**']));
        expect(config.ruleConfigs, hasLength(1));
        var ruleConfig = config.ruleConfigs[0];
        expect(ruleConfig.group, 'style_guide');
        expect(ruleConfig.name, 'unnecessary_getters');
        expect(ruleConfig.args, {'enabled': false});
      });
    });
  });
}

class MockProcessResult extends Mock implements ProcessResult {}
