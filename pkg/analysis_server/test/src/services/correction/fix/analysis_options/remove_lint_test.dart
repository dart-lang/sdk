// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:linter/src/rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveLintTest);
  });
}

class DeprecatedRule extends LintRule {
  DeprecatedRule()
      : super(
          name: 'deprecated_rule',
          description: '',
          details: '...',
          group: Group.errors,
          state: State.deprecated(since: dart2_12),
        );
}

@reflectiveTest
class RemoveLintTest extends AnalysisOptionsFixTest {
  // Keep track of this rule so it can be unregistered in `tearDown`.
  var deprecatedRule = DeprecatedRule();

  void setUp() {
    registerLintRules();
    Registry.ruleRegistry.register(deprecatedRule);
  }

  void tearDown() {
    Registry.ruleRegistry.unregister(deprecatedRule);
  }

  Future<void> test_deprecated() async {
    await assertHasFix('''
linter:
  rules:
    - camel_case_types
    - deprecated_rule
''', '''
linter:
  rules:
    - camel_case_types
''');
  }

  Future<void> test_deprecated_only() async {
    await assertHasFix('''
linter:
  rules:
    - deprecated_rule
''', '''
''');
  }

  Future<void> test_deprecated_withSectionAfter() async {
    await assertHasFix('''
linter:
  rules:
    - camel_case_types
    - deprecated_rule
section:
  - foo
''', '''
linter:
  rules:
    - camel_case_types
section:
  - foo
''');
  }

  Future<void> test_deprecated_withSectionBefore() async {
    await assertHasFix('''
analyzer:
  exclude:
    - test/data/**

linter:
  rules:
    - camel_case_types
    - deprecated_rule
''', '''
analyzer:
  exclude:
    - test/data/**

linter:
  rules:
    - camel_case_types
''');
  }

  Future<void> test_duplicated() async {
    await assertHasFix('''
linter:
  rules:
    - camel_case_types
    - camel_case_types
''', '''
linter:
  rules:
    - camel_case_types
''');
  }
}
