// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/util/lint_cache.dart';
import 'package:test/test.dart';

void main() {
  final lintCache = LintCache();

  group('check for incompatible rules:', () {
    registerLintRules();
    for (var rule in Analyzer.facade.registeredRules) {
      test(rule.name, () async {
        await lintCache.init();
        var lintDetail = lintCache.findDetailsById(rule.name);
        for (var incompatibleRule in lintDetail.incompatibleRules) {
          final ruleDetail = lintCache.findDetailsById(incompatibleRule);
          expect(ruleDetail, isNotNull,
              reason:
                  'No rule found for id: $incompatibleRule (check for typo?)');
          expect(ruleDetail.incompatibleRules, contains(lintDetail.id),
              reason:
                  '${ruleDetail.id} should declare ${lintDetail.id} as `@IncompatibleWith` but does not.');
        }
      });
    }
  });
}
