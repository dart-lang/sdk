// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/yaml/analysis_options_generator.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:linter/src/rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'yaml_generator_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisOptionsGeneratorTest);
  });
}

@reflectiveTest
class AnalysisOptionsGeneratorTest extends YamlGeneratorTest {
  // Keep track of any added rules so they can be unregistered at tearDown
  var addedRules = <LintRule>[];

  @override
  String get fileName => 'analysis_options.yaml';

  @override
  AnalysisOptionsGenerator get generator =>
      AnalysisOptionsGenerator(resourceProvider);

  void registerRule(LintRule rule) {
    addedRules.add(rule);
    Registry.ruleRegistry.register(rule);
  }

  void setUp() {
    registerLintRules();
  }

  void tearDown() {
    for (var rule in addedRules) {
      Registry.ruleRegistry.unregister(rule);
    }
  }

  void test_analyzer() {
    getCompletions('''
analyzer:
  ^
''');
    assertSuggestion('${AnalyzerOptions.enableExperiment}:');
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

  void test_analyzer_errors_nonDuplicate() {
    getCompletions('''
analyzer:
  errors:
    dead_code: info
    ^
''');
    assertNoSuggestion('dead_code');
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

  void test_codeStyle() {
    getCompletions('''
code-style:
  ^
''');
    assertSuggestion('${AnalyzerOptions.format}: ');
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
    assertSuggestion('${AnalyzerOptions.analyzer}: ');
    assertSuggestion('${AnalyzerOptions.codeStyle}: ');
    assertSuggestion('${AnalyzerOptions.include}: ');
    // TODO(brianwilkerson) Replace this with a constant.
    assertSuggestion('linter: ');
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
    assertSuggestion('annotate_overrides');
  }

  void test_linter_rules_internal() {
    registerRule(InternalLint());

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
    assertSuggestion('avoid_as');
    assertNoSuggestion('annotate_overrides');
  }

  void test_linter_rules_listItem_last() {
    getCompletions('''
linter:
  rules:
    - annotate_overrides
    - ^
''');
    assertSuggestion('avoid_as');
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
    assertSuggestion('avoid_as');
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
    assertSuggestion('${AnalyzerOptions.include}: ');
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

class InternalLint extends LintRule {
  InternalLint()
      : super(
          name: 'internal_lint',
          group: Group.style,
          state: State.internal(),
          description: '',
          details: '',
        );
}
