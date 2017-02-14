// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/linter.dart';

/**
 * Registry of lint rules.
 */
class Registry extends Object with IterableMixin<LintRule> {
  /**
   * The default registry to be used by clients.
   */
  static final Registry ruleRegistry = new Registry();

  /**
   * A table mapping rule names to rules.
   */
  Map<String, LintRule> _ruleMap = <String, LintRule>{};

  /**
   * A list of the default lint rules.
   */
  List<LintRule> _defaultRules = <LintRule>[];

  /**
   * Return a list of the default lint rules.
   */
  List<LintRule> get defaultRules => _defaultRules;

  @override
  Iterator<LintRule> get iterator => _ruleMap.values.iterator;

  /**
   * Return a list of the rules that are defined.
   */
  Iterable<LintRule> get rules => _ruleMap.values;

  /**
   * Return the lint rule with the given [name].
   */
  LintRule operator [](String name) => _ruleMap[name];

  /**
   * Return a list of the lint rules explicitly enabled by the given [config].
   *
   * For example:
   *     my_rule: true
   *
   * enables `my_rule`.
   *
   * Unspecified rules are treated as disabled by default.
   */
  Iterable<LintRule> enabled(LintConfig config) => rules
      .where((rule) => config.ruleConfigs.any((rc) => rc.enables(rule.name)));

  /**
   * Add the given lint [rule] to this registry.
   */
  void register(LintRule rule) {
    _ruleMap[rule.name] = rule;
  }

  /**
   * Add the given lint [rule] to this registry and mark it as being a default
   * lint (one that will be run if lints are requested but no rules are enabled.
   */
  void registerDefault(LintRule rule) {
    register(rule);
    _defaultRules.add(rule);
  }
}
