// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/yaml/analysis_options_generator.dart';
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
  @override
  String get fileName => 'analysis_options.yaml';

  @override
  AnalysisOptionsGenerator get generator =>
      AnalysisOptionsGenerator(resourceProvider);

  void test_analyzer() {
    getCompletions('''
analyzer:
  ^
''');
    assertSuggestion('${AnalyzerOptions.enableExperiment}: ');
  }

  void test_empty() {
    getCompletions('^');
    assertSuggestion('${AnalyzerOptions.analyzer}: ');
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
    registerLintRules();
    getCompletions('''
linter:
  rules:
    ^
''');
    assertSuggestion('annotate_overrides');
  }

  void test_linter_rules_listItem_first() {
    registerLintRules();
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
    registerLintRules();
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
    registerLintRules();
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
    registerLintRules();
    getCompletions('''
linter:
  rules:
    - annotate_overrides
    - ^
''');
    assertNoSuggestion('annotate_overrides');
  }

  void test_linter_rules_listItem_only() {
    registerLintRules();
    getCompletions('''
linter:
  rules:
    - ^
''');
    assertSuggestion('annotate_overrides');
  }

  void test_linter_rules_listItem_partial() {
    registerLintRules();
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
