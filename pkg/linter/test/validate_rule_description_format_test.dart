// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:test/test.dart';

import 'util/test_utils.dart';

void main() {
  group('rule doc format', () {
    setUpSharedTestEnvironment();
    var rules = Registry.ruleRegistry.rules;

    test('(setup)', () {
      expect(rules, isNotEmpty,
          reason:
              'Ensure `registerLintRules()` is called before running this suite.');
    });

    group('description - trailing periods', () {
      for (var rule in rules) {
        test('`${rule.name}` description', () {
          expect(rule.description.endsWith('.'), isTrue,
              reason:
                  "Rule description for ${rule.name} should end with a '.'");
        });
      }
    });
  });
}
