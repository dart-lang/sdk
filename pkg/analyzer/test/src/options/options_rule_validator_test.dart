// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';
import '../diagnostics/analysis_options/analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsRuleValidatorIncludedFileTest);
    defineReflectiveTests(OptionsRuleValidatorTest);
    defineReflectiveTests(OptionsRuleValidatorValueTest);
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
    assertNoErrors('''
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

    assertNoErrors('''
include: included.yaml
''');
  }

  Future<void> test_incompatible_multiple_include() async {
    var included1Code = TestCode.parse('''
linter:
  rules:
    [!rule_neg!]: true
''');
    var included1 = newFile('/included1.yaml', included1Code.code);
    var included2Code = TestCode.parse('''
linter:
  rules:
    [!rule_pos!]: true
''');
    var included2 = newFile('/included2.yaml', included2Code.code);
    var testCode = TestCode.parse('''
include:
  - included1.yaml
  - [!included2.yaml!]
''');
    await assertErrorsInCode(testCode.code, [
      ExpectedError(
        AnalysisOptionsWarningCode.incompatibleLintIncluded,
        testCode.range.sourceRange.offset,
        testCode.range.sourceRange.length,
        expectedContextMessages: [
          ExpectedContextMessage(
            included2,
            included2Code.range.sourceRange.offset,
            included2Code.range.sourceRange.length,
          ),
          ExpectedContextMessage(
            included1,
            included1Code.range.sourceRange.offset,
            included1Code.range.sourceRange.length,
          ),
        ],
      ),
    ]);
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
    await assertNoErrorsInCode('''
include:
  - included1.yaml
  - included2.yaml

linter:
  rules:
    rule_neg: false
''');
  }

  Future<void> test_incompatible_multiple_include_list() async {
    var included1Code = TestCode.parse('''
linter:
  rules:
    - [!rule_neg!]
''');
    var included1 = newFile('/included1.yaml', included1Code.code);
    var included2Code = TestCode.parse('''
linter:
  rules:
    - [!rule_pos!]
''');
    var included2 = newFile('/included2.yaml', included2Code.code);
    var testCode = TestCode.parse('''
include:
  - included1.yaml
  - [!included2.yaml!]
''');
    await assertErrorsInCode(testCode.code, [
      ExpectedError(
        AnalysisOptionsWarningCode.incompatibleLintIncluded,
        testCode.range.sourceRange.offset,
        testCode.range.sourceRange.length,
        expectedContextMessages: [
          ExpectedContextMessage(
            included2,
            included2Code.range.sourceRange.offset,
            included2Code.range.sourceRange.length,
          ),
          ExpectedContextMessage(
            included1,
            included1Code.range.sourceRange.offset,
            included1Code.range.sourceRange.length,
          ),
        ],
      ),
    ]);
  }

  Future<void> test_incompatible_multiple_include_noLintMainFile() async {
    newFile('/included1.yaml', '''
linter:
  rules:
    - rule_neg
''');
    newFile('/included2.yaml', '''
linter:
  rules:
    - rule_pos
''');
    assertErrors(
      '''
include:
  - included1.yaml
  - included2.yaml

linter:
  rules:
''',
      [AnalysisOptionsWarningCode.incompatibleLintIncluded],
    );
  }

  void test_incompatible_noTrigger_invalidMap() {
    newFile('/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    assertNoErrors('''
include: included.yaml

linter:
  rules:
    rule_neg: true
    rule_pos:
''');
  }

  Future<void> test_incompatible_rule_map_include() async {
    var includedCode = TestCode.parse('''
linter:
  rules:
    [!rule_neg!]: true
''');
    var included = newFile('/included.yaml', includedCode.code);
    var testCode = TestCode.parse('''
include: included.yaml

linter:
  rules:
    [!rule_pos!]: true
''');
    await assertErrorsInCode(testCode.code, [
      ExpectedError(
        AnalysisOptionsWarningCode.incompatibleLintFiles,
        testCode.range.sourceRange.offset,
        testCode.range.sourceRange.length,
        expectedContextMessages: [
          ExpectedContextMessage(
            included,
            includedCode.range.sourceRange.offset,
            includedCode.range.sourceRange.length,
          ),
        ],
      ),
    ]);
  }

  Future<void> test_incompatible_rule_map_include_disabled() async {
    newFile('/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    await assertNoErrorsInCode('''
include: included.yaml

linter:
  rules:
    rule_pos: true
    rule_neg: false
''');
  }

  void test_incompatible_trigger_invalidMap() {
    newFile('/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    assertErrors(
      '''
include: included.yaml

linter:
  rules:
    rule_neg:
    rule_pos: true
''',
      [AnalysisOptionsWarningCode.incompatibleLintFiles],
    );
  }

  void test_incompatible_unsuportedValue_invalidMap() {
    newFile('/included.yaml', '''
linter:
  rules:
    rule_neg: true
''');
    assertErrors(
      '''
include: included.yaml

linter:
  rules:
    rule_pos: invalid_value
''',
      [AnalysisOptionsWarningCode.unsupportedValue],
    );
  }

  void test_package_import() {
    newFile('$otherLib/analysis_options.yaml', '''
linter:
  rules:
    rule_pos: true
''');
    testProjectPath = '/test';
    assertErrors(
      '''
include:
  - package:other/analysis_options.yaml

linter:
  rules:
    rule_neg: true
''',
      [AnalysisOptionsWarningCode.incompatibleLintFiles],
    );
  }

  Future<void> test_removed_rule_inInclude_ok() async {
    newFile('/included.yaml', '''
linter:
  rules:
    - removed_in_2_12_lint
''');
    assertNoErrors('''
include: included.yaml
''');
  }
}

@reflectiveTest
class OptionsRuleValidatorTest extends AbstractAnalysisOptionsTest
    with OptionsRuleValidatorTestMixin {
  void test_deprecated_rule() {
    assertErrors(
      '''
linter:
  rules:
    - deprecated_lint_with_replacement
''',
      [AnalysisOptionsWarningCode.deprecatedLintWithReplacement],
    );
  }

  void test_deprecated_rule_map() {
    assertErrors(
      '''
linter:
  rules:
    deprecated_lint: false
''',
      [AnalysisOptionsWarningCode.deprecatedLint],
    );
  }

  void test_deprecated_rule_withReplacement() {
    assertErrors(
      '''
linter:
  rules:
    - deprecated_lint
''',
      [AnalysisOptionsWarningCode.deprecatedLint],
    );
  }

  void test_deprecated_rule_withSince_inCurrentSdk() {
    assertErrors(
      '''
linter:
  rules:
    - deprecated_since_3_lint
''',
      [AnalysisOptionsWarningCode.deprecatedLint],
      sdk: dart3,
    );
  }

  void test_deprecated_rule_withSince_notInCurrentSdk() {
    assertNoErrors('''
linter:
  rules:
    - deprecated_since_3_lint
''', sdk: Version(2, 17, 0));
  }

  void test_deprecated_rule_withSince_unknownSdk() {
    assertNoErrors('''
linter:
  rules:
    - deprecated_since_3_lint
''');
  }

  void test_duplicated_rule() {
    assertErrors(
      '''
linter:
  rules:
    - stable_lint
    - stable_lint
''',
      [AnalysisOptionsWarningCode.duplicateRule],
    );
  }

  Future<void> test_incompatible_rule() async {
    var testCode = TestCode.parse('''
linter:
  rules:
    - /*[0*/rule_pos/*0]*/
    - /*[1*/rule_neg/*1]*/
''');
    await assertErrorsInCode(testCode.code, [
      ExpectedError(
        AnalysisOptionsWarningCode.incompatibleLint,
        testCode.ranges.last.sourceRange.offset,
        testCode.ranges.last.sourceRange.length,
        expectedContextMessages: [
          ExpectedContextMessage(
            analysisOptionsFile,
            testCode.ranges.first.sourceRange.offset,
            testCode.ranges.first.sourceRange.length,
          ),
        ],
      ),
    ]);
  }

  Future<void> test_incompatible_rule_map() async {
    var testCode = TestCode.parse('''
linter:
  rules:
    /*[0*/rule_pos/*0]*/: true
    /*[1*/rule_neg/*1]*/: true
''');
    await assertErrorsInCode(testCode.code, [
      ExpectedError(
        AnalysisOptionsWarningCode.incompatibleLint,
        testCode.ranges.last.sourceRange.offset,
        testCode.ranges.last.sourceRange.length,
        expectedContextMessages: [
          ExpectedContextMessage(
            analysisOptionsFile,
            testCode.ranges.first.sourceRange.offset,
            testCode.ranges.first.sourceRange.length,
          ),
        ],
      ),
    ]);
  }

  void test_incompatible_rule_map_disabled() {
    assertNoErrors('''
linter:
  rules:
    rule_pos: true
    rule_neg: false
''');
  }

  void test_no_duplicated_rule_include() {
    newFile('/included.yaml', '''
linter:
  rules:
    - stable_lint
''');
    assertNoErrors('''
include: included.yaml

linter:
  rules:
    - stable_lint
''');
  }

  void test_removed_rule() {
    assertErrors(
      '''
linter:
  rules:
    - removed_in_2_12_lint
''',
      [AnalysisOptionsWarningCode.removedLint],
      sdk: dart2_12,
    );
  }

  void test_removed_rule_notYet_ok() {
    assertNoErrors('''
linter:
  rules:
    - removed_in_2_12_lint
''', sdk: Version(2, 11, 0));
  }

  void test_replaced_rule() {
    assertErrors(
      '''
linter:
  rules:
    - replaced_lint
''',
      [AnalysisOptionsWarningCode.replacedLint],
      sdk: dart3,
    );
  }

  void test_stable_rule() {
    assertNoErrors('''
linter:
  rules:
    - stable_lint
''');
  }

  void test_stable_rule_map() {
    assertNoErrors('''
linter:
  rules:
    stable_lint: true
''');
  }

  void test_undefined_rule() {
    assertErrors(
      '''
linter:
  rules:
    - this_rule_does_not_exist
''',
      [AnalysisOptionsWarningCode.undefinedLint],
    );
  }

  void test_undefined_rule_map() {
    assertErrors(
      '''
linter:
  rules:
    this_rule_does_not_exist: false
''',
      [AnalysisOptionsWarningCode.undefinedLint],
    );
  }
}

mixin OptionsRuleValidatorTestMixin on AbstractAnalysisOptionsTest {
  String? testProjectPath;

  /// Assert that when the validator is used on the given [content] the
  /// [expectedCodes] are produced.
  void assertErrors(
    String content,
    List<DiagnosticCode> expectedCodes, {
    VersionConstraint? sdk,
  }) {
    GatheringDiagnosticListener listener = GatheringDiagnosticListener();
    String filePath = 'analysis_options.yaml';
    if (testProjectPath != null) {
      filePath = resourceProvider.pathContext.join(testProjectPath!, filePath);
    }
    var source = StringSource(content, filePath);
    var reporter = DiagnosticReporter(listener, source);
    var validator = LinterRuleOptionsValidator(
      optionsProvider: AnalysisOptionsProvider(sourceFactory),
      resourceProvider: resourceProvider,
      sourceFactory: sourceFactory,
      sdkVersionConstraint: sdk,
    );
    validator.validate(
      reporter,
      loadYamlNode(content, sourceUrl: source.uri) as YamlMap,
    );
    listener.assertErrorsWithCodes(expectedCodes);
  }

  /// Assert that when the validator is used on the given [content] no errors
  /// are produced.
  void assertNoErrors(String content, {VersionConstraint? sdk}) =>
      assertErrors(content, const [], sdk: sdk);

  @override
  void setUp() {
    registerLintRules([
      DeprecatedLint(),
      DeprecatedSince3Lint(),
      DeprecatedLintWithReplacement(),
      StableLint(),
      RuleNeg(),
      RulePos(),
      RemovedIn2_12Lint(),
      ReplacedLint(),
      ReplacingLint(),
    ]);
    super.setUp();
  }
}

@reflectiveTest
class OptionsRuleValidatorValueTest extends AbstractAnalysisOptionsTest
    with OptionsRuleValidatorTestMixin {
  void test_unsuportedValue_invalidValue() {
    assertErrors(
      '''
linter:
  rules:
    rule_pos: invalid_value
''',
      [AnalysisOptionsWarningCode.unsupportedValue],
    );
  }

  void test_unsuportedValue_validError() {
    assertNoErrors('''
include: included.yaml

linter:
  rules:
    rule_pos: error
''');
  }

  void test_unsuportedValue_validFalse() {
    assertNoErrors('''
include: included.yaml

linter:
  rules:
    rule_pos: false
''');
  }

  void test_unsuportedValue_validIgnore() {
    assertNoErrors('''
include: included.yaml

linter:
  rules:
    rule_pos: ignore
''');
  }

  void test_unsuportedValue_validInfo() {
    assertNoErrors('''
include: included.yaml

linter:
  rules:
    rule_pos: info
''');
  }

  void test_unsuportedValue_validTrue() {
    assertNoErrors('''
include: included.yaml

linter:
  rules:
    rule_pos: true
''');
  }

  void test_unsuportedValue_validWarning() {
    assertNoErrors('''
include: included.yaml

linter:
  rules:
    rule_pos: warning
''');
  }
}

class RemovedIn2_12Lint extends TestLintRule {
  RemovedIn2_12Lint()
    : super(
        name: 'removed_in_2_12_lint',
        state: RuleState.removed(since: dart2_12),
      );
}

class ReplacedLint extends TestLintRule {
  ReplacedLint()
    : super(
        name: 'replaced_lint',
        state: RuleState.removed(since: dart3, replacedBy: 'replacing_lint'),
      );
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

abstract class TestLintRule extends LintRule {
  static const LintCode code = LintCode(
    'lint_code',
    'Lint code.',
    correctionMessage: 'Lint code.',
  );

  TestLintRule({required super.name, super.state}) : super(description: '');

  @override
  DiagnosticCode get diagnosticCode => code;
}
