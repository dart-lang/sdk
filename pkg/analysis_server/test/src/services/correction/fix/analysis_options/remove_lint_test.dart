// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:linter/src/rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveLintTest);
  });
}

class DeprecatedRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'deprecated_rule',
    'Deprecated rule.',
    correctionMessage: 'Try deprecated rule.',
    uniqueName: 'LintCode.deprecated_rule',
  );

  DeprecatedRule()
    : super(
        name: 'deprecated_rule',
        description: '',
        state: RuleState.deprecated(since: dart2_12),
      );

  @override
  DiagnosticCode get diagnosticCode => code;
}

@reflectiveTest
class RemoveLintTest extends AnalysisOptionsFixTest with LintRegistrationMixin {
  // Keep track of these rules so they can be unregistered in `tearDown`.
  var deprecatedRule = DeprecatedRule();
  var removedRule = RemovedAnalysisRule(name: 'removed_rule', description: '');

  void setUp() {
    registerLintRules();
    registerLintRule(deprecatedRule);
    registerLintRule(removedRule);
  }

  void tearDown() {
    unregisterLintRules();
  }

  Future<void> test_deprecated() async {
    await assertHasFix(
      '''
linter:
  rules:
    - camel_case_types
    - deprecated_rule
''',
      '''
linter:
  rules:
    - camel_case_types
''',
    );
  }

  Future<void> test_deprecated_only() async {
    await assertHasFix(
      '''
linter:
  rules:
    - deprecated_rule
''',
      '''
''',
    );
  }

  Future<void> test_deprecated_withSectionAfter() async {
    await assertHasFix(
      '''
linter:
  rules:
    - camel_case_types
    - deprecated_rule
section:
  - foo
''',
      '''
linter:
  rules:
    - camel_case_types
section:
  - foo
''',
    );
  }

  Future<void> test_deprecated_withSectionBefore() async {
    await assertHasFix(
      '''
analyzer:
  exclude:
    - test/data/**

linter:
  rules:
    - camel_case_types
    - deprecated_rule
''',
      '''
analyzer:
  exclude:
    - test/data/**

linter:
  rules:
    - camel_case_types
''',
    );
  }

  Future<void> test_duplicated() async {
    await assertHasFix(
      '''
linter:
  rules:
    - camel_case_types
    - camel_case_types
''',
      '''
linter:
  rules:
    - camel_case_types
''',
    );
  }

  Future<void> test_removed() async {
    await assertHasFix(
      '''
linter:
  rules:
    - camel_case_types
    - removed_rule
''',
      '''
linter:
  rules:
    - camel_case_types
''',
    );
  }

  Future<void> test_undefined() async {
    await assertHasFix(
      '''
linter:
  rules:
    - camel_case_types
    - undefined_rule
''',
      '''
linter:
  rules:
    - camel_case_types
''',
    );
  }
}
