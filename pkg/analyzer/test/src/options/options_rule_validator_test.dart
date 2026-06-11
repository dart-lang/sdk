// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../dart/resolution/node_text_expectations.dart';
import '../diagnostics/analysis_options/analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsRuleValidatorIncludedFileTest);
    defineReflectiveTests(OptionsRuleValidatorTest);
    defineReflectiveTests(OptionsRuleValidatorValueTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

class DeprecatedLint extends TestLintRule {
  DeprecatedLint()
    : super(name: 'deprecated_lint', state: RuleState.deprecated());
}

class DeprecatedLintWithReplacement extends TestLintRule {
  DeprecatedLintWithReplacement()
    : super(
        name: 'deprecated_lint_with_replacement',
        state: RuleState.deprecated(replacedBy: 'replacing_lint'),
      );
}

class DeprecatedSince3Lint extends TestLintRule {
  DeprecatedSince3Lint()
    : super(
        name: 'deprecated_since_3_lint',
        state: RuleState.deprecated(since: dart3),
      );
}

@reflectiveTest
class OptionsRuleValidatorIncludedFileTest extends AbstractAnalysisOptionsTest
    with OptionsRuleValidatorTestMixin {
  static const otherLib = '/other/lib';

  @override
  get dependencies => {'other': otherLib};

  void test_compatible_multiple_include() {
    newFile('/included1.yaml', '''
linter:
  rules:
    rule_pos: true
''');
    newFile('/included2.yaml', '''
linter:
  rules:
    rule_pos: true
''');
    assertDiagnostics('''
include:
  - included1.yaml
  - included2.yaml
''');
  }

  Future<void> test_deprecated_rule_inInclude_ok() async {
    newFile('/included.yaml', '''
linter:
  rules:
    - deprecated_lint
''');

    assertDiagnostics('''
include: included.yaml
''');
  }

  Future<void> test_incompatible_multiple_include() async {
    await assertDiagnosticsInFiles({
      getFile('/included1.yaml'): '''
linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 2] The rule 'rule_neg' is enabled here.
''',
      getFile('/included2.yaml'): '''
linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
''',
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_pos' and 'rule_neg', which is included from 2 files.
''',
    });
  }

  Future<void> test_incompatible_multiple_include_disabled() async {
    newFile('/included1.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    newFile('/included2.yaml', '''
linter:
  rules:
    rule_pos: true
''');
    await assertDiagnosticsInCode('''
include:
  - included1.yaml
  - included2.yaml

linter:
  rules:
    rule_neg: false
''');
  }

  Future<void> test_incompatible_multiple_include_list() async {
    await assertDiagnosticsInFiles({
      getFile('/included1.yaml'): '''
linter:
  rules:
    - rule_neg
//    ^^^^^^^^
// [context 2] The rule 'rule_neg' is enabled here.
''',
      getFile('/included2.yaml'): '''
linter:
  rules:
    - rule_pos
//    ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
''',
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_pos' and 'rule_neg', which is included from 2 files.
''',
    });
  }

  Future<void> test_incompatible_multiple_include_noLintMainFile() async {
    assertRuleDiagnosticsInFiles({
      getFile('/included1.yaml'): '''
linter:
  rules:
    - rule_neg
//    ^^^^^^^^
// [context 2] The rule 'rule_neg' is enabled here.
''',
      getFile('/included2.yaml'): '''
linter:
  rules:
    - rule_pos
//    ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
''',
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_pos' and 'rule_neg', which is included from 2 files.

linter:
  rules:
''',
    });
  }

  Future<void>
  test_incompatible_multiple_include_noLintMainFile_mixedCase() async {
    assertRuleDiagnosticsInFiles({
      getFile('/included1.yaml'): '''
linter:
  rules:
    - ruLe_neg
//    ^^^^^^^^
// [context 2] The rule 'ruLe_neg' is enabled here.
''',
      getFile('/included2.yaml'): '''
linter:
  rules:
    - rule_poS
//    ^^^^^^^^
// [context 1] The rule 'rule_poS' is enabled here.
''',
      analysisOptionsFile: '''
include:
  - included1.yaml
  - included2.yaml
//  ^^^^^^^^^^^^^^
// [diag.incompatibleLintIncluded][context 1][context 2] The rule 'included2.yaml' is incompatible with 'rule_poS' and 'ruLe_neg', which is included from 2 files.

linter:
  rules:
''',
    });
  }

  void test_incompatible_noTrigger_invalidMap() {
    newFile('/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    assertDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_neg: true
    rule_pos:
''');
  }

  Future<void> test_incompatible_rule_map_include() async {
    await assertDiagnosticsInFiles({
      getFile('/included.yaml'): '''
linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 1] The rule 'rule_neg' is enabled here in the file '/included.yaml'.
''',
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'rule_pos' is incompatible with 'rule_neg'.
''',
    });
  }

  Future<void> test_incompatible_rule_map_include_disabled() async {
    newFile('/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    await assertDiagnosticsInCode('''
include: included.yaml

linter:
  rules:
    rule_pos: true
    rule_neg: false
''');
  }

  Future<void> test_incompatible_rule_map_include_mixedCase() async {
    await assertDiagnosticsInFiles({
      getFile('/included.yaml'): '''
linter:
  rules:
    rulE_neg: true
//  ^^^^^^^^
// [context 1] The rule 'rulE_neg' is enabled here in the file '/included.yaml'.
''',
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    Rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'Rule_pos' is incompatible with 'rulE_neg'.
''',
    });
  }

  void test_incompatible_trigger_invalidMap() {
    assertRuleDiagnosticsInFiles({
      getFile('/included.yaml'): '''
linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [context 1] The rule 'rule_neg' is enabled here in the file '/included.yaml'.
''',
      analysisOptionsFile: '''
include: included.yaml

linter:
  rules:
    rule_neg:
    rule_pos: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'rule_pos' is incompatible with 'rule_neg'.
''',
    });
  }

  void test_incompatible_unsuportedValue_invalidMap() {
    newFile('/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    assertDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: invalid_value
//            ^^^^^^^^^^^^^
// [diag.unsupportedValue] The value 'invalid_value' isn't supported by 'rule_pos'.
''');
  }

  void test_incompatible_unsuportedValue_invalidMap_mixedCase() {
    newFile('/included.yaml', '''
linter:
  rules:
    rUle_neg: true
''');
    assertDiagnostics('''
include: included.yaml

linter:
  rules:
    Rule_pos: invalid_value
//            ^^^^^^^^^^^^^
// [diag.unsupportedValue] The value 'invalid_value' isn't supported by 'Rule_pos'.
''');
  }

  void test_package_import() {
    testProjectPath = '/test';
    assertRuleDiagnosticsInFiles({
      getFile('$otherLib/analysis_options.yaml'): '''
linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here in the file '/other/lib/analysis_options.yaml'.
''',
      getFile('$testProjectPath/analysis_options.yaml'): '''
include:
  - package:other/analysis_options.yaml

linter:
  rules:
    rule_neg: true
//  ^^^^^^^^
// [diag.incompatibleLintFiles][context 1] The rule 'rule_neg' is incompatible with 'rule_pos'.
''',
    });
  }

  Future<void> test_removed_rule_inInclude_ok() async {
    newFile('/included.yaml', '''
linter:
  rules:
    - removed_in_2_12_lint
''');
    assertDiagnostics('''
include: included.yaml
''');
  }

  /// https://github.com/dart-lang/sdk/issues/59869
  test_removed_rule_previousSdk() {
    assertDiagnostics('''
linter:
  rules:
    - removed_in_2_12_lint
//    ^^^^^^^^^^^^^^^^^^^^
// [diag.removedLint] 'removed_in_2_12_lint' was removed in Dart '2.12.0'
''', sdk: dart3_3);
  }

  test_removed_rule_previousSdk_mixedCase() {
    assertDiagnostics('''
linter:
  rules:
    - remOved_in_2_12_lint
//    ^^^^^^^^^^^^^^^^^^^^
// [diag.removedLint] 'remOved_in_2_12_lint' was removed in Dart '2.12.0'
''', sdk: dart3_3);
  }
}

@reflectiveTest
class OptionsRuleValidatorTest extends AbstractAnalysisOptionsTest
    with OptionsRuleValidatorTestMixin {
  void test_deprecated_rule() {
    assertDiagnostics('''
linter:
  rules:
    - deprecated_lint
//    ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_lint' is deprecated and shouldn't be enabled.
''');
  }

  void test_deprecated_rule_map() {
    assertDiagnostics('''
linter:
  rules:
    deprecated_lint: false
//  ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_lint' is deprecated and shouldn't be enabled.
''');
  }

  void test_deprecated_rule_map_mixedCase() {
    assertDiagnostics('''
linter:
  rules:
    deprecated_lInt: false
//  ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_lInt' is deprecated and shouldn't be enabled.
''');
  }

  void test_deprecated_rule_mixedCase() {
    assertDiagnostics('''
linter:
  rules:
    - deprecAted_lint
//    ^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecAted_lint' is deprecated and shouldn't be enabled.
''');
  }

  void test_deprecated_rule_previousSDK() {
    assertDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_since_3_lint' is deprecated and shouldn't be enabled.
''', sdk: dart3_3);
  }

  void test_deprecated_rule_withReplacement() {
    assertDiagnostics('''
linter:
  rules:
    - deprecated_lint_with_replacement
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLintWithReplacement] The lint rule 'deprecated_lint_with_replacement' is deprecated and replaced by 'replacing_lint'.
''');
  }

  void test_deprecated_rule_withReplacement_mixedCase() {
    assertDiagnostics('''
linter:
  rules:
    - deprecated_lint_with_rePlacement
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLintWithReplacement] The lint rule 'deprecated_lint_with_rePlacement' is deprecated and replaced by 'replacing_lint'.
''');
  }

  void test_deprecated_rule_withSince_inCurrentSdk() {
    assertDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
//    ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.deprecatedLint] The lint rule 'deprecated_since_3_lint' is deprecated and shouldn't be enabled.
''', sdk: dart3);
  }

  void test_deprecated_rule_withSince_notInCurrentSdk() {
    assertDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
''', sdk: Version(2, 17, 0));
  }

  void test_deprecated_rule_withSince_unknownSdk() {
    assertDiagnostics('''
linter:
  rules:
    - deprecated_since_3_lint
''');
  }

  void test_duplicated_rule() {
    assertDiagnostics('''
linter:
  rules:
    - stable_lint
    - stable_lint
//    ^^^^^^^^^^^
// [diag.duplicateRule] The rule 'stable_lint' is already enabled and doesn't need to be enabled again.
''');
  }

  void test_duplicated_rule_mixedCase() {
    assertDiagnostics('''
linter:
  rules:
    - stable_lint
    - staBle_lint
//    ^^^^^^^^^^^
// [diag.duplicateRule] The rule 'staBle_lint' is already enabled and doesn't need to be enabled again.
''');
  }

  Future<void> test_incompatible_rule() async {
    await assertDiagnosticsInCode('''
linter:
  rules:
    - rule_pos
//    ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
    - rule_neg
//    ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rule_neg' is incompatible with ''rule_pos''.
''');
  }

  Future<void> test_incompatible_rule_map() async {
    await assertDiagnosticsInCode('''
linter:
  rules:
    rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'rule_pos' is enabled here.
    rule_neg: true
//  ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rule_neg' is incompatible with ''rule_pos''.
''');
  }

  void test_incompatible_rule_map_disabled() {
    assertDiagnostics('''
linter:
  rules:
    rule_pos: true
    rule_neg: false
''');
  }

  Future<void> test_incompatible_rule_map_mixedCase() async {
    await assertDiagnosticsInCode('''
linter:
  rules:
    Rule_pos: true
//  ^^^^^^^^
// [context 1] The rule 'Rule_pos' is enabled here.
    rUle_neg: true
//  ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rUle_neg' is incompatible with ''Rule_pos''.
''');
  }

  Future<void> test_incompatible_rule_mixedCase() async {
    await assertDiagnosticsInCode('''
linter:
  rules:
    - rule_Pos
//    ^^^^^^^^
// [context 1] The rule 'rule_Pos' is enabled here.
    - rule_neG
//    ^^^^^^^^
// [diag.incompatibleLint][context 1] The rule 'rule_neG' is incompatible with ''rule_Pos''.
''');
  }

  void test_no_duplicated_rule_include() {
    newFile('/included.yaml', '''
linter:
  rules:
    - stable_lint
''');
    assertDiagnostics('''
include: included.yaml

linter:
  rules:
    - stable_lint
''');
  }

  void test_removed_rule() {
    assertDiagnostics('''
linter:
  rules:
    - removed_in_2_12_lint
//    ^^^^^^^^^^^^^^^^^^^^
// [diag.removedLint] 'removed_in_2_12_lint' was removed in Dart '2.12.0'
''', sdk: dart2_12);
  }

  void test_removed_rule_notYet_ok() {
    assertDiagnostics('''
linter:
  rules:
    - removed_in_2_12_lint
''', sdk: Version(2, 11, 0));
  }

  void test_replaced_rule() {
    assertDiagnostics('''
linter:
  rules:
    - replaced_lint
//    ^^^^^^^^^^^^^
// [diag.replacedLint] 'replaced_lint' was replaced by 'replacing_lint' in Dart '3.0.0'.
''', sdk: dart3);
  }

  void test_replaced_rule_mixedCase() {
    assertDiagnostics('''
linter:
  rules:
    - replaCed_lint
//    ^^^^^^^^^^^^^
// [diag.replacedLint] 'replaCed_lint' was replaced by 'replacing_lint' in Dart '3.0.0'.
''', sdk: dart3);
  }

  void test_stable_rule() {
    assertDiagnostics('''
linter:
  rules:
    - stable_lint
''');
  }

  void test_stable_rule_map() {
    assertDiagnostics('''
linter:
  rules:
    stable_lint: true
''');
  }

  void test_stable_rule_map_mixedCase() {
    assertDiagnostics('''
linter:
  rules:
    sTable_lint: true
''');
  }

  void test_stable_rule_mixedCase() {
    assertDiagnostics('''
linter:
  rules:
    - Stable_lint
''');
  }

  void test_undefined_rule() {
    assertDiagnostics('''
linter:
  rules:
    - this_rule_does_not_exist
//    ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.undefinedLint] 'this_rule_does_not_exist' isn't a recognized lint rule.
''');
  }

  void test_undefined_rule_map() {
    assertDiagnostics('''
linter:
  rules:
    this_rule_does_not_exist: false
//  ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.undefinedLint] 'this_rule_does_not_exist' isn't a recognized lint rule.
''');
  }
}

mixin OptionsRuleValidatorTestMixin on AbstractAnalysisOptionsTest {
  String? testProjectPath;

  /// Assert that when the validator is used on the given [content] its
  /// diagnostics match the inline diagnostic markers in [content].
  void assertDiagnostics(String content, {VersionConstraint? sdk}) {
    var optionsFile = analysisOptionsFile;
    if (testProjectPath != null) {
      optionsFile = getFile('$testProjectPath/analysis_options.yaml');
    }
    assertRuleDiagnosticsInFiles({optionsFile: content}, sdk: sdk);
  }

  /// Assert that rule-validator diagnostics for a main options file match
  /// inline diagnostic markers across [codeByFile].
  void assertRuleDiagnosticsInFiles(
    Map<File, String> codeByFile, {
    VersionConstraint? sdk,
  }) {
    var cleanCodeByFile = writeFilesWithoutDiagnosticExpectations(codeByFile);

    var optionsFile = testProjectPath != null
        ? getFile('$testProjectPath/analysis_options.yaml')
        : analysisOptionsFile;
    var cleanContent = cleanCodeByFile[optionsFile]!;

    var listener = RecordingDiagnosticListener();
    var source = FileSource(optionsFile);
    var reporter = DiagnosticReporter(listener, source);
    var validator = LinterRuleOptionsValidator(
      optionsProvider: AnalysisOptionsProvider(sourceFactory),
      resourceProvider: resourceProvider,
      sourceFactory: sourceFactory,
      sdkVersionConstraint: sdk,
      analysisOptionsCache: {},
    );
    validator.validate(
      reporter,
      loadYamlNode(cleanContent, sourceUrl: source.uri) as YamlMap,
    );

    assertDiagnosticMarkersInFiles(
      codeByFile: codeByFile,
      diagnostics: listener.diagnostics,
    );
  }

  @override
  void setUp() {
    registerLintRules([
      DeprecatedLint(),
      DeprecatedSince3Lint(),
      DeprecatedLintWithReplacement(),
      StableLint(),
      RuleNeg(),
      RulePos(),
      RemovedAnalysisRule(
        name: 'removed_in_2_12_lint',
        since: dart2_12,
        description: '',
      ),
      RemovedAnalysisRule(
        name: 'replaced_lint',
        since: dart3,
        replacedBy: 'replacing_lint',
        description: '',
      ),
      ReplacingLint(),
    ]);
    super.setUp();
  }
}

@reflectiveTest
class OptionsRuleValidatorValueTest extends AbstractAnalysisOptionsTest
    with OptionsRuleValidatorTestMixin {
  void test_unsuportedValue_invalidValue() {
    assertDiagnostics('''
linter:
  rules:
    rule_pos: invalid_value
//            ^^^^^^^^^^^^^
// [diag.unsupportedValue] The value 'invalid_value' isn't supported by 'rule_pos'.
''');
  }

  void test_unsuportedValue_validError() {
    assertDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: error
''');
  }

  void test_unsuportedValue_validFalse() {
    assertDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: false
''');
  }

  void test_unsuportedValue_validIgnore() {
    assertDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: ignore
''');
  }

  void test_unsuportedValue_validInfo() {
    assertDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: info
''');
  }

  void test_unsuportedValue_validTrue() {
    assertDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: true
''');
  }

  void test_unsuportedValue_validWarning() {
    assertDiagnostics('''
include: included.yaml

linter:
  rules:
    rule_pos: warning
''');
  }
}

class ReplacingLint extends TestLintRule {
  ReplacingLint() : super(name: 'replacing_lint');
}

class RuleNeg extends TestLintRule {
  RuleNeg() : super(name: 'rule_neg');

  @override
  List<String> get incompatibleRules => ['rule_pos'];
}

class RulePos extends TestLintRule {
  RulePos() : super(name: 'rule_pos');

  @override
  List<String> get incompatibleRules => ['rule_neg'];
}

class StableLint extends TestLintRule {
  StableLint() : super(name: 'stable_lint', state: RuleState.stable());
}

abstract class TestLintRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'lint_code',
    'Lint code.',
    correctionMessage: 'Lint code.',
    uniqueName: 'LintCode.lint_code',
  );

  TestLintRule({required super.name, super.state}) : super(description: '');

  @override
  DiagnosticCode get diagnosticCode => code;
}
