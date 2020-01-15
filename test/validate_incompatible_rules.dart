// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';

void main() {
  group('check for incompatible rules:', () {
    registerLintRules();
    for (var rule in Analyzer.facade.registeredRules) {
      for (var incompatibleRule in rule.incompatibleRules) {
        test(rule.name, () async {
          var referencedRule = Analyzer.facade.registeredRules
              .firstWhere((r) => r.name == incompatibleRule);
          expect(referencedRule, isNotNull,
              reason:
                  'No rule found for id: $incompatibleRule (check for typo?)');
          expect(referencedRule.incompatibleRules, contains(rule.name),
              reason:
                  '$referencedRule should define ${rule.name} in `incompatibleRules` but does not.');
        });
      }
    }
  });
}
