// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';
import '../diagnostics/analysis_options/analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsRuleValidatorTest);
    defineReflectiveTests(OptionsRuleValidatorIncludedFileTest);
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
  Future<void> test_deprecated_rule_inInclude_ok() async {
    newFile('/included.yaml', '''
linter:
  rules:
    - deprecated_lint
''');

    await assertErrorsInCode('''
include: included.yaml
''', []);
  }

  Future<void> test_removed_rule_inInclude_ok() async {
    newFile('/included.yaml', '''
linter:
  rules:
    - removed_in_2_12_lint
''');

    await assertErrorsInCode('''
include: included.yaml
''', []);
  }
}

@reflectiveTest
class OptionsRuleValidatorTest extends AbstractAnalysisOptionsTest
    with OptionsRuleValidatorTestMixin {
  test_deprecated_rule() {
    assertErrors(
      '''
linter:
  rules:
    - deprecated_lint_with_replacement
''',
      [AnalysisOptionsWarningCode.DEPRECATED_LINT_WITH_REPLACEMENT],
    );
  }

  test_deprecated_rule_map() {
    assertErrors(
      '''
linter:
  rules:
    deprecated_lint: false
''',
      [AnalysisOptionsWarningCode.DEPRECATED_LINT],
    );
  }

  test_deprecated_rule_withReplacement() {
    assertErrors(
      '''
linter:
  rules:
    - deprecated_lint
''',
      [AnalysisOptionsWarningCode.DEPRECATED_LINT],
    );
  }

  test_deprecated_rule_withSince_inCurrentSdk() {
    assertErrors(
      '''
linter:
  rules:
    - deprecated_since_3_lint
''',
      [AnalysisOptionsWarningCode.DEPRECATED_LINT],
      sdk: dart3,
    );
  }

  test_deprecated_rule_withSince_notInCurrentSdk() {
    assertErrors(
      '''
linter:
  rules:
    - deprecated_since_3_lint
''',
      [],
      sdk: Version(2, 17, 0),
    );
  }

  test_deprecated_rule_withSince_unknownSdk() {
    assertErrors(
      '''
linter:
  rules:
    - deprecated_since_3_lint
''',
      // No error
      [],
    );
  }

  test_duplicated_rule() {
    assertErrors(
      '''
linter:
  rules:
    - stable_lint
    - stable_lint
''',
      [AnalysisOptionsWarningCode.DUPLICATE_RULE],
    );
  }

  test_incompatible_rule() {
    assertErrors(
      '''
linter:
  rules:
    - rule_pos
    - rule_neg
''',
      [AnalysisOptionsWarningCode.INCOMPATIBLE_LINT],
    );
  }

  test_incompatible_rule_map() {
    assertErrors(
      '''
linter:
  rules:
    rule_pos: true
    rule_neg: true
''',
      [AnalysisOptionsWarningCode.INCOMPATIBLE_LINT],
    );
  }

  test_incompatible_rule_map_disabled() {
    assertErrors('''
linter:
  rules:
    rule_pos: true
    rule_neg: false
''', []);
  }

  test_removed_rule() {
    assertErrors(
      '''
linter:
  rules:
    - removed_in_2_12_lint
''',
      [AnalysisOptionsWarningCode.REMOVED_LINT],
      sdk: dart2_12,
    );
  }

  test_removed_rule_notYet_ok() {
    assertErrors(
      '''
linter:
  rules:
    - removed_in_2_12_lint
''',
      [],
      sdk: Version(2, 11, 0),
    );
  }

  test_replaced_rule() {
    assertErrors(
      '''
linter:
  rules:
    - replaced_lint
''',
      [AnalysisOptionsWarningCode.REPLACED_LINT],
      sdk: dart3,
    );
  }

  test_stable_rule() {
    assertErrors('''
linter:
  rules:
    - stable_lint
''', []);
  }

  test_stable_rule_map() {
    assertErrors('''
linter:
  rules:
    stable_lint: true
''', []);
  }

  test_undefined_rule() {
    assertErrors(
      '''
linter:
  rules:
    - this_rule_does_not_exist
''',
      [AnalysisOptionsWarningCode.UNDEFINED_LINT],
    );
  }

  test_undefined_rule_map() {
    assertErrors(
      '''
linter:
  rules:
    this_rule_does_not_exist: false
''',
      [AnalysisOptionsWarningCode.UNDEFINED_LINT],
    );
  }
}

mixin OptionsRuleValidatorTestMixin on AbstractAnalysisOptionsTest {
  /// Assert that when the validator is used on the given [content] the
  /// [expectedCodes] are produced.
  void assertErrors(
    String content,
    List<DiagnosticCode> expectedCodes, {
    VersionConstraint? sdk,
  }) {
    GatheringDiagnosticListener listener = GatheringDiagnosticListener();
    DiagnosticReporter reporter = DiagnosticReporter(
      listener,
      StringSource(content, 'analysis_options.yaml'),
    );
    var validator = LinterRuleOptionsValidator(sdkVersionConstraint: sdk);
    validator.validate(reporter, loadYamlNode(content) as YamlMap);
    listener.assertErrorsWithCodes(expectedCodes);
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
      RemovedIn2_12Lint(),
      ReplacedLint(),
      ReplacingLint(),
    ]);
    super.setUp();
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
