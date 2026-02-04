// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/lint/config.dart';

/// Registry of lint rules and warning rules.
class Registry extends RegistryBase
    with IterableMixin<AbstractAnalysisRule>, RegistryMixin {
  /// The default registry to be used by clients.
  static final Registry ruleRegistry = Registry();

  @override
  final Map<String, AbstractAnalysisRule> lintRules = {};

  @override
  final Map<String, AbstractAnalysisRule> warningRules = {};

  @override
  final Map<String, DiagnosticCode> codeMap = {};

  @override
  Iterator<AbstractAnalysisRule> get iterator => _rules.values.iterator;

  /// Returns a list of the rules that are defined.
  Iterable<AbstractAnalysisRule> get rules => _rules.values;

  // TODO(srawlins): This process can result in collisions. Guard against this
  // somehow.
  Map<String, AbstractAnalysisRule> get _rules => {
    ...lintRules,
    ...warningRules,
  };

  /// Returns the rule with the given [name].
  ///
  /// The name is matched disregarding case.
  AbstractAnalysisRule? operator [](String name) => _rules[name.toLowerCase()];

  /// Returns the lint code that has the given [uniqueName].
  ///
  /// The name is matched disregarding case.
  DiagnosticCode? codeForUniqueName(String uniqueName) =>
      codeMap[uniqueName.toLowerCase()];

  /// Returns the rule with the given [name].
  ///
  /// The name is matched disregarding case.
  AbstractAnalysisRule? getRule(String name) => _rules[name.toLowerCase()];

  /// Removes the given lint [rule] from this registry.
  void unregisterLintRule(AbstractAnalysisRule rule) {
    lintRules.remove(rule.name.toLowerCase());
    for (var code in rule.diagnosticCodes) {
      codeMap.remove(code.lowerCaseUniqueName);
    }
  }

  /// Removes the given warning [rule] from this registry.
  void unregisterWarningRule(AbstractAnalysisRule rule) {
    warningRules.remove(rule.name.toLowerCase());
    for (var code in rule.diagnosticCodes) {
      codeMap.remove(code.lowerCaseUniqueName);
    }
  }
}

abstract class RegistryBase {
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
  ///
  /// Every key in [ruleConfigs] should be all lower case.
  Iterable<AbstractAnalysisRule> enabled(Map<String, RuleConfig> ruleConfigs);

  /// Registers this [rule] with the analyzer's rule registry.
  ///
  /// Lint rules are disabled by default and can be enabled using
  /// the analysis options file.
  ///
  /// Use [registerWarningRule] for rules that are enabled by
  /// default.
  void registerLintRule(AbstractAnalysisRule rule);

  /// Registers this [rule] with the analyzer's rule registry.
  ///
  /// Warning rules are enabled by default and can be disabled using
  /// the analysis options file.
  ///
  /// Use [registerLintRule] for rules that are disabled by
  /// default.
  void registerWarningRule(AbstractAnalysisRule rule);
}

mixin RegistryMixin on RegistryBase {
  /// A table mapping lower case unique names to lint codes.
  Map<String, DiagnosticCode> get codeMap;

  /// A table mapping lower case lint rule names to rules.
  Map<String, AbstractAnalysisRule> get lintRules;

  /// A table mapping lower case warning rule names to rules.
  Map<String, AbstractAnalysisRule> get warningRules;

  @override
  Iterable<AbstractAnalysisRule> enabled(Map<String, RuleConfig> ruleConfigs) {
    assert(ruleConfigs.keys.every((key) => key == key.toLowerCase()));
    return [
      // All warning rules that haven't explicitly been disabled.
      ...warningRules.values.where(
        (rule) => ruleConfigs[rule.name.toLowerCase()]?.isEnabled ?? true,
      ),
      // All lint rules that have explicitly been enabled.
      ...lintRules.values.where(
        (rule) => ruleConfigs[rule.name.toLowerCase()]?.isEnabled ?? false,
      ),
    ];
  }

  @override
  void registerLintRule(AbstractAnalysisRule rule) {
    lintRules[rule.name.toLowerCase()] = rule;
    for (var code in rule.diagnosticCodes) {
      codeMap[code.lowerCaseUniqueName] = code;
    }
  }

  @override
  void registerWarningRule(AbstractAnalysisRule rule) {
    warningRules[rule.name.toLowerCase()] = rule;
    for (var code in rule.diagnosticCodes) {
      codeMap[code.lowerCaseUniqueName] = code;
    }
  }
}
