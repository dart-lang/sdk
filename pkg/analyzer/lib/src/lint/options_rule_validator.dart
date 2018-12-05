// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/plugin/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:yaml/yaml.dart';

/**
 * A hint code indicating reference to a deprecated lint.
 *
 * Parameters:
 * 0: the rule name
 */
const AnalysisOptionsHintCode DEPRECATED_LINT_HINT =
    const AnalysisOptionsHintCode('DEPRECATED_LINT_HINT',
        "'{0}' is a deprecated lint rule and should not be used");

/**
 * An error code indicating an undefined lint rule.
 *
 * Parameters:
 * 0: the rule name
 */
const AnalysisOptionsWarningCode UNDEFINED_LINT_WARNING =
    const AnalysisOptionsWarningCode(
        'UNDEFINED_LINT_WARNING', "'{0}' is not a recognized lint rule");

/**
 * Rule provider.
 */
typedef LintRuleProvider = Iterable<LintRule> Function();

/**
 * Validates `linter` rule configurations.
 */
class LinterRuleOptionsValidator extends OptionsValidator {
  static const linter = 'linter';
  static const rulesKey = 'rules';

  final LintRuleProvider ruleProvider;

  LinterRuleOptionsValidator({LintRuleProvider provider})
      : ruleProvider = provider ?? (() => Registry.ruleRegistry.rules);

  @override
  List<AnalysisError> validate(ErrorReporter reporter, YamlMap options) {
    List<AnalysisError> errors = <AnalysisError>[];
    var node = getValue(options, linter);
    if (node is YamlMap) {
      var rules = getValue(node, rulesKey);
      validateRules(rules, reporter);
    }
    return errors;
  }

  validateRules(YamlNode rules, ErrorReporter reporter) {
    if (rules is YamlList) {
      rules.nodes.forEach((YamlNode ruleNode) {
        Object value = ruleNode.value;
        if (value != null) {
          LintRule rule = getRegisteredLint(value);
          if (rule == null) {
            reporter.reportErrorForSpan(
                UNDEFINED_LINT_WARNING, ruleNode.span, [value]);
          } else if (rule.maturity == Maturity.deprecated) {
            reporter.reportErrorForSpan(
                DEPRECATED_LINT_HINT, ruleNode.span, [value]);
          }
        }
      });
    }
  }

  LintRule getRegisteredLint(Object value) => ruleProvider()
      .firstWhere((rule) => rule.name == value, orElse: () => null);
}
