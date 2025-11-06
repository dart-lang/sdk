// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/lint/config.dart';

/// Registry of lint rules and warning rules.
class Registry with IterableMixin<AbstractAnalysisRule> {
  /// The default registry to be used by clients.
  static final Registry ruleRegistry = Registry();

  /// A table mapping lint rule names to rules.
  final Map<String, AbstractAnalysisRule> _lintRules = {};

  /// A table mapping warning rule names to rules.
  final Map<String, AbstractAnalysisRule> _warningRules = {};

  /// A table mapping unique names to lint codes.
  final Map<String, LintCode> _codeMap = {};

  @override
  Iterator<AbstractAnalysisRule> get iterator => _rules.values.iterator;

  /// Returns a list of the rules that are defined.
  Iterable<AbstractAnalysisRule> get rules => _rules.values;

  // TODO(srawlins): This process can result in collisions. Guard against this
  // somehow.
  Map<String, AbstractAnalysisRule> get _rules => {
    ..._lintRules,
    ..._warningRules,
  };

  /// Returns the rule with the given [name].
  AbstractAnalysisRule? operator [](String name) => _rules[name];

  /// Returns the lint code that has the given [uniqueName].
  LintCode? codeForUniqueName(String uniqueName) => _codeMap[uniqueName];

  /// Returns a list of the enabled rules.
  ///
  /// This includes any warning rules, which are enabled by default and are not
  /// disabled by the given [ruleConfigs], and any lint rules which are
  /// explicitly enabled by the given [ruleConfigs].
  ///
  /// For example:
  ///     my_rule: true
  ///
  /// enables `my_rule`.
  Iterable<AbstractAnalysisRule> enabled(Map<String, RuleConfig> ruleConfigs) =>
      [
        // All warning rules that haven't explicitly been disabled.
        ..._warningRules.values.where(
          (rule) => ruleConfigs[rule.name]?.isEnabled ?? true,
        ),
        // All lint rules that have explicitly been enabled.
        ..._lintRules.values.where(
          (rule) => ruleConfigs[rule.name]?.isEnabled ?? false,
        ),
      ];

  /// Returns the rule with the given [name].
  AbstractAnalysisRule? getRule(String name) => _rules[name];

  /// Adds the given lint [rule] to this registry.
  void registerLintRule(AbstractAnalysisRule rule) {
    _lintRules[rule.name] = rule;
    for (var code in rule.diagnosticCodes) {
      _codeMap[code.uniqueName] = code as LintCode;
    }
  }

  /// Adds the given warning [rule] to this registry.
  void registerWarningRule(AbstractAnalysisRule rule) {
    _warningRules[rule.name] = rule;
    for (var code in rule.diagnosticCodes) {
      _codeMap[code.uniqueName] = code as LintCode;
    }
  }

  /// Removes the given lint [rule] from this registry.
  void unregisterLintRule(AbstractAnalysisRule rule) {
    _lintRules.remove(rule.name);
    for (var code in rule.diagnosticCodes) {
      _codeMap.remove(code.uniqueName);
    }
  }

  /// Removes the given warning [rule] from this registry.
  void unregisterWarningRule(AbstractAnalysisRule rule) {
    _warningRules.remove(rule.name);
    for (var code in rule.diagnosticCodes) {
      _codeMap.remove(code.uniqueName);
    }
  }
}
