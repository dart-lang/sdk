// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/state.dart';
import 'package:analyzer/src/plugin/options.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:collection/collection.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Rule provider.
typedef LintRuleProvider = Iterable<LintRule> Function();

/// Validates `linter` rule configurations.
class LinterRuleOptionsValidator extends OptionsValidator {
  static const linter = 'linter';
  static const rulesKey = 'rules';

  final LintRuleProvider ruleProvider;
  final VersionConstraint? sdkVersionConstraint;
  final bool sourceIsOptionsForContextRoot;

  LinterRuleOptionsValidator({
    LintRuleProvider? provider,
    this.sdkVersionConstraint,
    this.sourceIsOptionsForContextRoot = true,
  }) : ruleProvider = provider ?? (() => Registry.ruleRegistry.rules);

  bool currentSdkAllows(Version? since) {
    if (since == null) return true;
    var sdk = sdkVersionConstraint;
    if (sdk == null) return false;
    return sdk.allows(since);
  }

  LintRule? getRegisteredLint(Object value) =>
      ruleProvider().firstWhereOrNull((rule) => rule.name == value);

  bool isDeprecatedInCurrentSdk(DeprecatedState state) =>
      currentSdkAllows(state.since);

  bool isRemovedInCurrentSdk(State state) {
    if (state is! RemovedState) return false;
    return currentSdkAllows(state.since);
  }

  @override
  List<AnalysisError> validate(ErrorReporter reporter, YamlMap options) {
    List<AnalysisError> errors = <AnalysisError>[];
    var node = options.valueAt(linter);
    if (node is YamlMap) {
      var rules = node.valueAt(rulesKey);
      _validateRules(rules, reporter);
    }
    return errors;
  }

  void _validateRules(YamlNode? rules, ErrorReporter reporter) {
    var seenRules = <String>{};

    String? findIncompatibleRule(LintRule rule) {
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
          AnalysisOptionsWarningCode.UNDEFINED_LINT,
          arguments: [value],
        );
        return;
      }

      if (enabled) {
        var incompatibleRule = findIncompatibleRule(rule);
        if (incompatibleRule != null) {
          reporter.atSourceSpan(
            node.span,
            AnalysisOptionsWarningCode.INCOMPATIBLE_LINT,
            arguments: [value, incompatibleRule],
          );
        } else if (!seenRules.add(rule.name)) {
          reporter.atSourceSpan(
            node.span,
            AnalysisOptionsHintCode.DUPLICATE_RULE,
            arguments: [value],
          );
        }
      }
      // Report removed or deprecated lint warnings defined directly (and not in
      // includes).
      if (sourceIsOptionsForContextRoot) {
        var state = rule.state;
        if (state is DeprecatedState && isDeprecatedInCurrentSdk(state)) {
          var replacedBy = state.replacedBy;
          if (replacedBy != null) {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsHintCode.DEPRECATED_LINT_WITH_REPLACEMENT,
              arguments: [value, replacedBy],
            );
          } else {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsHintCode.DEPRECATED_LINT,
              arguments: [value],
            );
          }
        } else if (isRemovedInCurrentSdk(state)) {
          var since = state.since.toString();
          var replacedBy = (state as RemovedState).replacedBy;
          if (replacedBy != null) {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.REPLACED_LINT,
              arguments: [value, since, replacedBy],
            );
          } else {
            reporter.atSourceSpan(
              node.span,
              AnalysisOptionsWarningCode.REMOVED_LINT,
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
