// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/plugin/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:yaml/yaml.dart';

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
 * Validates `linter` rule configurations.
 */
class LinterRuleOptionsValidator extends OptionsValidator {
  static const linter = 'linter';
  static const rulesKey = 'rules';

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
      List<String> registeredLints =
          Registry.ruleRegistry.map((r) => r.name).toList();
      rules.nodes.forEach((YamlNode ruleNode) {
        Object value = ruleNode.value;
        if (value != null && !registeredLints.contains(value)) {
          reporter.reportErrorForSpan(
              UNDEFINED_LINT_WARNING, ruleNode.span, [value]);
        }
      });
    }
  }
}
