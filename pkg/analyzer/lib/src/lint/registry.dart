// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/linter.dart';

/// Registry of lint rules and warning rules.
class Registry with IterableMixin<AnalysisRule> {
  /// The default registry to be used by clients.
  static final Registry ruleRegistry = Registry();

  /// A table mapping rule names to rules.
  final Map<String, AnalysisRule> _lintRules = {};

  final Map<String, AnalysisRule> _warningRules = {};

  /// A table mapping unique names to lint codes.
  final Map<String, LintCode> _codeMap = {};

  @override
  Iterator<AnalysisRule> get iterator => _rules.values.iterator;

  /// Returns a list of the rules that are defined.
  Iterable<AnalysisRule> get rules => _rules.values;

  // TODO(srawlins): This process can result in collisions. Guard against this
  // somehow.
  Map<String, AnalysisRule> get _rules => {..._lintRules, ..._warningRules};

  /// Returns the rule with the given [name].
  AnalysisRule? operator [](String name) => _rules[name];

  /// Returns the lint code that has the given [uniqueName].
  LintCode? codeForUniqueName(String uniqueName) => _codeMap[uniqueName];

  /// Returns a list of the enabled rules.
  ///
  /// This includes any warning rules, which are enabled by default, and any
  /// lint rules explicitly enabled by the given [ruleConfigs].
  ///
  /// For example:
  ///     my_rule: true
  ///
  /// enables `my_rule`.
  Iterable<AnalysisRule> enabled(List<RuleConfig> ruleConfigs) => [
        ..._warningRules.values,
        ..._lintRules.values
            .where((rule) => ruleConfigs.any((rc) => rc.enables(rule.name))),
      ];

  /// Returns the rule with the given [name].
  AnalysisRule? getRule(String name) => _rules[name];

  /// Adds the given lint [rule] to this registry.
  void registerLintRule(AnalysisRule rule) {
    _lintRules[rule.name] = rule;
    for (var lintCode in rule.lintCodes) {
      _codeMap[lintCode.uniqueName] = lintCode;
    }
  }

  /// Adds the given warning [rule] to this registry.
  void registerWarningRule(AnalysisRule rule) {
    _warningRules[rule.name] = rule;
    for (var lintCode in rule.lintCodes) {
      _codeMap[lintCode.uniqueName] = lintCode;
    }
  }

  /// Removes the given lint [rule] from this registry.
  void unregisterLintRule(AnalysisRule rule) {
    _lintRules.remove(rule.name);
    for (var lintCode in rule.lintCodes) {
      _codeMap.remove(lintCode.uniqueName);
    }
  }

  /// Removes the given warning [rule] from this registry.
  void unregisterWarningRule(AnalysisRule rule) {
    _warningRules.remove(rule.name);
    for (var lintCode in rule.lintCodes) {
      _codeMap.remove(lintCode.uniqueName);
    }
  }
}
