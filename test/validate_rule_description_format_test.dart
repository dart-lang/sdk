// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:test/test.dart';

import 'util/test_utils.dart';

void main() {
  const keywords = [
    'GOOD',
    'BAD',
    'NOTE',
    'DEPRECATED',
    'EXCEPTION',
    'EXCEPTIONS',
  ];

  group('rule doc format', () {
    setUp(setUpSharedTestEnvironment);

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

    group('details - no leading whitespace', () {
      for (var rule in rules) {
        test('`${rule.name}` details', () {
          expect(rule.details.startsWith(RegExp(r'\s+')), isFalse,
              reason:
                  'Rule details for ${rule.name} should not have leading whitespace.');
        });
      }
    });

    group('details - bad first', () {
      for (var rule in rules) {
        test('`${rule.name}` bad example first', () {
          var details = rule.details;
          var lines = details.split('\n');
          var hasGood = false;
          for (var line in lines) {
            if (line.startsWith('**BAD:**')) {
              if (hasGood) {
                fail(
                    'Rule details for ${rule.name} should have the BAD example before the GOOD one.');
              }
              break;
            } else if (line.startsWith('**GOOD:**')) {
              hasGood = true;
            }
          }
        });
      }
    });

    group('details - colon inside stars', () {
      for (var rule in rules) {
        test('`${rule.name}` colon inside stars', () {
          var details = rule.details;
          var lines = details.split('\n');

          for (var line in lines) {
            for (var keyword in keywords) {
              var withStars = '**$keyword**';
              if (line.contains(withStars)) {
                fail(
                    'Rule details for ${rule.name} should have **$keyword:**, put the colon inside the stars.');
              }
            }
          }
        });
      }
    });

    group('details - upper case keywords', () {
      for (var rule in rules) {
        test('`${rule.name}` upper case keywords', () {
          var details = rule.details;
          var lines = details.split('\n');

          for (var line in lines) {
            for (var keyword in keywords) {
              var withStars = '**$keyword:**';
              if (line.toLowerCase().contains(withStars.toLowerCase()) &&
                  !line.contains(withStars)) {
                fail(
                    'Rule details for ${rule.name} should have $withStars in upper case.');
              }
            }
          }
        });
      }
    });
  });
}
