// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/yaml/analysis_options_generator.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/analysis_options/analysis_options_file.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:collection/collection.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'yaml_generator_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsGeneratorTest);
  });
}

@reflectiveTest
class AnalysisOptionsGeneratorTest extends YamlGeneratorTest
    with LintRegistrationMixin {
  @override
  String get fileName => 'analysis_options.yaml';

  @override
  AnalysisOptionsGenerator get generator =>
      AnalysisOptionsGenerator(resourceProvider);

  void setUp() {
    registerLintRules();
  }

  void tearDown() {
    unregisterLintRules();
  }

  void test_analyzer() {
    getCompletions('''
analyzer:
  ^
''');
    assertSuggestion('${AnalysisOptionsFile.enableExperiment}:');
  }

  void test_analyzer_enableExperiment() {
    getCompletions('''
analyzer:
  enable-experiment:
    ^
''');
    assertSuggestion('macros');
    assertNoSuggestion('super-parameters');
  }

  void test_analyzer_enableExperiment_nonDuplicate() {
    getCompletions('''
analyzer:
  enable-experiment:
    - macros
    ^
''');
    assertNoSuggestion('macros');
  }

  void test_analyzer_errors() {
    getCompletions('''
analyzer:
  errors:
    ^
''');
    assertSuggestion('dead_code: ');
    assertSuggestion('invalid_assignment: ');
    assertSuggestion('annotate_overrides: ');
  }

  void test_analyzer_errors_excludesExisting() {
    getCompletions('''
analyzer:
  errors:
    dead_code: info
    ^
''');
    assertNoSuggestion('dead_code');
  }

  void test_analyzer_errors_noDuplicates() {
    getCompletions('''
analyzer:
  errors:
    ^
''');
    var duplicateCompletions = groupBy(
      results.map((result) => result.completion),
      (result) => result,
    ).entries.where((entry) => entry.value.length > 1).keys;
    expect(duplicateCompletions, isEmpty);
  }

  void test_analyzer_errors_severity() {
    getCompletions('''
analyzer:
  errors:
    dead_code: ^
''');
    assertSuggestion('ignore');
    assertSuggestion('info');
    assertSuggestion('warning');
    assertSuggestion('error');
  }

  void test_analyzer_language_strictCasts() {
    getCompletions('''
analyzer:
  language:
    strict-casts: ^
''');
    assertSuggestion('false');
    assertSuggestion('true');
  }

  void test_analyzer_language_strictInference() {
    getCompletions('''
analyzer:
  language:
    strict-inference: ^
''');
    assertSuggestion('false');
    assertSuggestion('true');
  }

  void test_analyzer_language_strictRawTypes() {
    getCompletions('''
analyzer:
  language:
    strict-raw-types: ^
''');
    assertSuggestion('false');
    assertSuggestion('true');
  }

  void test_codeStyle() {
    getCompletions('''
code-style:
  ^
''');
    assertSuggestion('${AnalysisOptionsFile.format}: ');
  }

  void test_codeStyle_format() {
    getCompletions('''
code-style:
  format: ^
''');
    assertSuggestion('false');
    assertSuggestion('true');
  }

  void test_empty() {
    getCompletions('^');
    assertSuggestion('${AnalysisOptionsFile.analyzer}: ');
    assertSuggestion('${AnalysisOptionsFile.codeStyle}: ');
    assertSuggestion('${AnalysisOptionsFile.formatter}: ');
    assertSuggestion('${AnalysisOptionsFile.include}: ');
    // TODO(brianwilkerson): Replace this with a constant.
    assertSuggestion('linter: ');
  }

  void test_formatter() {
    getCompletions('''
formatter:
  ^
''');
    assertSuggestion('${AnalysisOptionsFile.pageWidth}: ');
    assertSuggestion('${AnalysisOptionsFile.trailingCommas}: ');
  }

  void test_formatter_trailingCommas() {
    getCompletions('''
formatter:
  trailing_commas: ^
''');
    assertSuggestion('automate');
    assertSuggestion('preserve');
  }

  void test_linter() {
    getCompletions('''
linter:
  ^
''');
    assertSuggestion('rules:');
  }

  void test_linter_rules() {
    getCompletions('''
linter:
  rules:
    ^
''');
    var completion = assertSuggestion('annotate_overrides');
    expect(completion.docComplete, contains('Annotate overridden members.'));
  }

  void test_linter_rules_internal() {
    registerLintRule(InternalRule());

    getCompletions('''
linter:
  rules:
    ^
''');

    assertNoSuggestion('internal_lint');
  }

  void test_linter_rules_listItem_first() {
    getCompletions('''
linter:
  rules:
    - ^
    - annotate_overrides
''');
    assertSuggestion('always_declare_return_types');
    assertNoSuggestion('annotate_overrides');
  }

  void test_linter_rules_listItem_last() {
    getCompletions('''
linter:
  rules:
    - annotate_overrides
    - ^
''');
    assertSuggestion('always_declare_return_types');
    assertNoSuggestion('annotate_overrides');
  }

  void test_linter_rules_listItem_middle() {
    getCompletions('''
linter:
  rules:
    - annotate_overrides
    - ^
    - avoid_empty_else
''');
    assertSuggestion('always_declare_return_types');
    assertNoSuggestion('annotate_overrides');
    assertNoSuggestion('avoid_empty_else');
  }

  void test_linter_rules_listItem_nonDuplicate() {
    getCompletions('''
linter:
  rules:
    - annotate_overrides
    - ^
''');
    assertNoSuggestion('annotate_overrides');
  }

  void test_linter_rules_listItem_only() {
    getCompletions('''
linter:
  rules:
    - ^
''');
    assertSuggestion('annotate_overrides');
  }

  void test_linter_rules_listItem_partial() {
    getCompletions('''
linter:
  rules:
    - ann^
''');
    assertSuggestion('annotate_overrides');
  }

  void test_linter_rules_removed() {
    registerLintRule(
      RemovedAnalysisRule(name: 'removed_lint', description: ''),
    );

    getCompletions('''
linter:
  rules:
    ^
''');

    assertNoSuggestion('removed_lint');
  }

  @failingTest
  void test_topLevel_afterOtherKeys() {
    // This test fails because the cursor is considered to be inside the exclude
    // list, and we don't suggest values there.
    getCompletions('''
analyzer:
  exclude:
    - '*.g.dart'
^
''');
    assertSuggestion('${AnalysisOptionsFile.include}: ');
  }

  @failingTest
  void test_topLevel_afterOtherKeys_partial() {
    // This test fails because the YAML parser can't recover from this kind of
    // invalid input.
    getCompletions('''
analyzer:
  exclude:
    - '*.g.dart'
li^
''');
    assertSuggestion('linter');
  }
}

class InternalRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'internal_rule',
    'Internal rule.',
    correctionMessage: 'Try internal rule.',
    uniqueName: 'LintCode.internal_rule',
  );

  InternalRule()
    : super(
        name: 'internal_lint',
        state: RuleState.internal(),
        description: '',
      );

  @override
  DiagnosticCode get diagnosticCode => code;
}
