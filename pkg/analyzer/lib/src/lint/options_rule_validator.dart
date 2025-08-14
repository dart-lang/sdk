// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/analysis_options/options_validator.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Validates `linter` rule configurations.
class LinterRuleOptionsValidator extends OptionsValidator {
  static const linter = 'linter';
  static const rulesKey = 'rules';

  final VersionConstraint? sdkVersionConstraint;
  final bool sourceIsOptionsForContextRoot;

  LinterRuleOptionsValidator({
    this.sdkVersionConstraint,
    this.sourceIsOptionsForContextRoot = true,
  });

  bool currentSdkAllows(Version? since) {
    if (since == null) return true;
    var sdk = sdkVersionConstraint;
    if (sdk == null) return false;
    return sdk.allows(since);
  }

  AbstractAnalysisRule? getRegisteredLint(Object value) => Registry
      .ruleRegistry
      .rules
      .firstWhereOrNull((rule) => rule.name == value);

  bool isDeprecatedInCurrentSdk(RuleState state) =>
      state.isDeprecated && currentSdkAllows(state.since);

  bool isRemovedInCurrentSdk(RuleState state) {
    return state.isRemoved && currentSdkAllows(state.since);
  }

  @override
  List<Diagnostic> validate(DiagnosticReporter reporter, YamlMap options) {
    var node = options.valueAt(linter);
    if (node is YamlMap) {
      var rules = node.valueAt(rulesKey);
      _validateRules(rules, reporter);
    }
    return const [];
  }

  void _validateRules(YamlNode? rules, DiagnosticReporter reporter) {
    var seenRules = <String>{};

    String? findIncompatibleRule(AbstractAnalysisRule rule) {
      for (var incompatibleRule in rule.incompatibleRules) {
        if (seenRules.contains(incompatibleRule)) {
          return incompatibleRule;
        }
      }
      return null;
    }

    void validateRule(YamlNode node, bool enabled) {
      var value = node.value;
      if (value == null) return;

      var rule = getRegisteredLint(value as Object);
      if (rule == null) {
        reporter.atSourceSpan(
          node.span,
          AnalysisOptionsWarningCode.undefinedLint,
          arguments: [value],
        );
        return;
      }

      if (enabled) {
        var incompatibleRule = findIncompatibleRule(rule);
        if (incompatibleRule != null) {
          reporter.atSourceSpan(
            node.span,
            AnalysisOptionsWarningCode.incompatibleLint,
            arguments: [value, incompatibleRule],
          );
        } else if (!seenRules.add(rule.name)) {
          reporter.atSourceSpan(
            node.span,
            AnalysisOptionsWarningCode.duplicateRule,
            arguments: [value],
          );
        }
      }
      // Report removed or deprecated lint warnings defined directly (and not in
      // includes).
      if (sourceIsOptionsForContextRoot) {
        var state = rule.state;
        if (state.isDeprecated && isDeprecatedInCurrentSdk(state)) {
          var replacedBy = state.replacedBy;
          if (replacedBy != null) {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.deprecatedLintWithReplacement,
              arguments: [value, replacedBy],
            );
          } else {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.deprecatedLint,
              arguments: [value],
            );
          }
        } else if (isRemovedInCurrentSdk(state)) {
          var since = state.since.toString();
          var replacedBy = state.replacedBy;
          if (replacedBy != null) {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.replacedLint,
              arguments: [value, since, replacedBy],
            );
          } else {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.removedLint,
              arguments: [value, since],
            );
          }
        }
      }
    }

    if (rules is YamlList) {
      for (var ruleNode in rules.nodes) {
        validateRule(ruleNode, true);
      }
    } else if (rules is YamlMap) {
      for (var ruleEntry in rules.nodeMap.entries) {
        validateRule(ruleEntry.key, ruleEntry.value.value as bool);
      }
    }
  }
}
