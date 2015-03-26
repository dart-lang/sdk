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
      setUp(() => outSink = collectingOut);
      tearDown(() {
        collectingOut.buffer.clear();
        outSink = currentOut;
      });
      group('config', () {
        test('excludes', () {
          dartlint
              .main(['test/_data/p2', '-c', 'test/_data/p2/lintconfig.yaml']);
          expect(collectingOut.trim(),
              endsWith('4 files analyzed, 1 issue found (2 filtered).'));
        });
        test('overrrides', () {
          dartlint
              .main(['test/_data/p2', '-c', 'test/_data/p2/lintconfig2.yaml']);
          expect(collectingOut.trim(),
              endsWith('4 files analyzed, 0 issues found.'));
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
        expect(
            collectingOut.trim(), endsWith('1 file analyzed, 0 issues found.'));
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
          when(processResult.stdout).thenReturn(
              JSON.encode({'packages': {'p4': libPath}, 'input_files': []}));
          return processResult;
        };
        dartlint.runLinter(['test/_data/p4'], options);
        expect(collectingOut.trim(),
            endsWith('3 files analyzed, 0 issues found.'));
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
        expect(ruleConfig.group, equals('style_guide'));
        expect(ruleConfig.name, equals('unnecessary_getters'));
        expect(ruleConfig.args, equals({'enabled': false}));
      });
    });
  });
}

class MockProcessResult extends Mock implements ProcessResult {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
