// Copyright (c) 2025, rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/src/lint/registry.dart';

/// A mixin for test classes that interact with the global lint
/// [Registry.ruleRegistry].
mixin LintRegistrationMixin {
  final _registeredRules = <AbstractAnalysisRule>{};

  /// Register the given [rule] with the global lint [Registry.ruleRegistry],
  /// caching it so that it can be unregistered by a call to [unregisterLintRules].
  void registerLintRule(AbstractAnalysisRule rule) {
    _registeredRules.add(rule);
    Registry.ruleRegistry.registerLintRule(rule);
  }

  /// Register the given [rules] with the global lint [Registry.ruleRegistry],
  /// caching each so that it can be unregistered by a call to [unregisterLintRules].
  void registerLintRules(List<AbstractAnalysisRule> rules) {
    rules.forEach(registerLintRule);
  }

  /// Unregister all rules added by [registerLintRule].
  void unregisterLintRules() {
    _registeredRules.forEach(Registry.ruleRegistry.unregisterLintRule);
    _registeredRules.clear();
  }
}
