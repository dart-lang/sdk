// Copyright (c) 2025, rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';

/// A mixin for test classes that interact with the global lint
/// [Registry.ruleRegistry].
mixin LintRegistrationMixin {
  final _registeredRules = <LintRule>{};

  /// Register the given [rule] with the global lint [Registry.ruleRegistry],
  /// caching it so that it can be unregistered by a call to [unregisterLintRules].
  void registerLintRule(LintRule rule) {
    _registeredRules.add(rule);
    Registry.ruleRegistry.registerLintRule(rule);
  }

  /// Register the given [rules] with the global lint [Registry.ruleRegistry],
  /// caching each so that it can be unregistered by a call to [unregisterLintRules].
  void registerLintRules(List<LintRule> rules) {
    rules.forEach(registerLintRule);
  }

  /// Unregister all rules added by [registerLintRule].
  void unregisterLintRules() {
    _registeredRules.forEach(Registry.ruleRegistry.unregisterLintRule);
    _registeredRules.clear();
  }
}
