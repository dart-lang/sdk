// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/options_rule_validator.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OptionsRuleValidatorTest);
  });
}

class DeprecatedLint extends LintRule {
  DeprecatedLint()
      : super(
            name: 'deprecated_lint',
            group: Group.style,
            maturity: Maturity.deprecated);
}

@reflectiveTest
class OptionsRuleValidatorTest extends Object with ResourceProviderMixin {
  LinterRuleOptionsValidator validator = new LinterRuleOptionsValidator(
      provider: () => [new DeprecatedLint(), new StableLint()]);

/**
 * Assert that when the validator is used on the given [content] the
 * [expectedErrorCodes] are produced.
 */
  void assertErrors(String content, List<ErrorCode> expectedErrorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter = new ErrorReporter(
        listener, new StringSource(content, 'analysis_options.yaml'));
    validator.validate(reporter, loadYamlNode(content));
    listener.assertErrorsWithCodes(expectedErrorCodes);
  }

  test_deprecated_rule() {
    assertErrors('''
linter:
  rules:
    - deprecated_lint
      ''', [DEPRECATED_LINT_HINT]);
  }

  test_duplicated_rule() {
    assertErrors('''
linter:
  rules:
    - stable_lint
    - stable_lint
      ''', [DUPLICATE_RULE_HINT]);
  }

  test_stable_rule() {
    assertErrors('''
linter:
  rules:
    - stable_lint
      ''', []);
  }

  test_undefined_rule() {
    assertErrors('''
linter:
  rules:
    - this_rule_does_not_exist
      ''', [UNDEFINED_LINT_WARNING]);
  }
}

class StableLint extends LintRule {
  StableLint()
      : super(
            name: 'stable_lint', group: Group.style, maturity: Maturity.stable);
}
