// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.test.integration;

import 'dart:io';

import 'package:linter/src/config.dart';
import 'package:linter/src/io.dart';
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
