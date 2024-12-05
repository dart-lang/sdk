// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
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

class DeprecatedLint extends LintRule {
  DeprecatedLint()
      : super(
          name: 'deprecated_lint',
          state: State.deprecated(),
          description: '',
        );
}

class DeprecatedLintWithReplacement extends LintRule {
  DeprecatedLintWithReplacement()
      : super(
          name: 'deprecated_lint_with_replacement',
          state: State.deprecated(replacedBy: 'replacing_lint'),
          description: '',
        );
}

class DeprecatedSince3Lint extends LintRule {
  DeprecatedSince3Lint()
      : super(
          name: 'deprecated_since_3_lint',
          state: State.deprecated(since: dart3),
          description: '',
        );
}

@reflectiveTest
class OptionsRuleValidatorIncludedFileTest extends AbstractAnalysisOptionsTest
    with OptionsRuleValidatorTestMixin {
  test_deprecated_rule_inInclude_ok() {
    newFile('/included.yaml', '''
linter:
  rules:
    - deprecated_lint
''');

    assertErrorsInCode(
      '''
include: included.yaml
''',
      [],
      provider: () => rules,
    );
  }

  test_removed_rule_inInclude_ok() {
    newFile('/included.yaml', '''
linter:
  rules:
    - removed_in_2_12_lint
''');

    assertErrorsInCode(
      '''
include: included.yaml
''',
      [],
      provider: () => rules,
    );
  }
}

@reflectiveTest
class OptionsRuleValidatorTest
    with OptionsRuleValidatorTestMixin, ResourceProviderMixin {
  test_deprecated_rule() {
    assertErrors('''
linter:
  rules:
    - deprecated_lint_with_replacement
      ''', [AnalysisOptionsHintCode.DEPRECATED_LINT_WITH_REPLACEMENT]);
  }

  test_deprecated_rule_map() {
    assertErrors('''
linter:
  rules:
    deprecated_lint: false
      ''', [AnalysisOptionsHintCode.DEPRECATED_LINT]);
  }

  test_deprecated_rule_withReplacement() {
    assertErrors('''
linter:
  rules:
    - deprecated_lint
      ''', [AnalysisOptionsHintCode.DEPRECATED_LINT]);
  }

  test_deprecated_rule_withSince_inCurrentSdk() {
    assertErrors(
      '''
linter:
  rules:
    - deprecated_since_3_lint
      ''',
      [AnalysisOptionsHintCode.DEPRECATED_LINT],
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
    assertErrors('''
linter:
  rules:
    - stable_lint
    - stable_lint
      ''', [AnalysisOptionsHintCode.DUPLICATE_RULE]);
  }

  test_incompatible_rule() {
    assertErrors('''
linter:
  rules:
    - rule_pos
    - rule_neg
      ''', [AnalysisOptionsWarningCode.INCOMPATIBLE_LINT]);
  }

  test_incompatible_rule_map() {
    assertErrors('''
linter:
  rules:
    rule_pos: true
    rule_neg: true
      ''', [AnalysisOptionsWarningCode.INCOMPATIBLE_LINT]);
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
    assertErrors('''
linter:
  rules:
    - this_rule_does_not_exist
      ''', [AnalysisOptionsWarningCode.UNDEFINED_LINT]);
  }

  test_undefined_rule_map() {
    assertErrors('''
linter:
  rules:
    this_rule_does_not_exist: false
      ''', [AnalysisOptionsWarningCode.UNDEFINED_LINT]);
  }
}

mixin OptionsRuleValidatorTestMixin {
  final rules = [
    DeprecatedLint(),
    DeprecatedSince3Lint(),
    DeprecatedLintWithReplacement(),
    StableLint(),
    RuleNeg(),
    RulePos(),
    RemovedIn2_12Lint(),
    ReplacedLint(),
    ReplacingLint(),
  ];

  /// Assert that when the validator is used on the given [content] the
  /// [expectedErrorCodes] are produced.
  void assertErrors(String content, List<ErrorCode> expectedErrorCodes,
      {VersionConstraint? sdk}) {
    GatheringErrorListener listener = GatheringErrorListener();
    ErrorReporter reporter = ErrorReporter(
      listener,
      StringSource(content, 'analysis_options.yaml'),
    );
    var validator = LinterRuleOptionsValidator(
        provider: () => rules, sdkVersionConstraint: sdk);
    validator.validate(reporter, loadYamlNode(content) as YamlMap);
    listener.assertErrorsWithCodes(expectedErrorCodes);
  }
}

class RemovedIn2_12Lint extends LintRule {
  RemovedIn2_12Lint()
      : super(
          name: 'removed_in_2_12_lint',
          state: State.removed(since: dart2_12),
          description: '',
        );
}

class ReplacedLint extends LintRule {
  ReplacedLint()
      : super(
          name: 'replaced_lint',
          state: State.removed(since: dart3, replacedBy: 'replacing_lint'),
          description: '',
        );
}

class ReplacingLint extends LintRule {
  ReplacingLint()
      : super(
          name: 'replacing_lint',
          description: '',
        );
}

class RuleNeg extends LintRule {
  RuleNeg()
      : super(
          name: 'rule_neg',
          description: '',
        );

  @override
  List<String> get incompatibleRules => ['rule_pos'];
}

class RulePos extends LintRule {
  RulePos()
      : super(
          name: 'rule_pos',
          description: '',
        );

  @override
  List<String> get incompatibleRules => ['rule_neg'];
}

class StableLint extends LintRule {
  StableLint()
      : super(
          name: 'stable_lint',
          state: State.stable(),
          description: '',
        );
}
