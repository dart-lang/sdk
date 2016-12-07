// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/src/lint/config.dart';
import 'package:analyzer/src/lint/linter.dart';

/**
 * Registry of contributed lint rules.
 */
class Registry extends Object with IterableMixin<LintRule> {
  /**
   * The default registry to be used by clients.
   */
  static final Registry ruleRegistry = new Registry();

  Map<String, LintRule> _ruleMap = <String, LintRule>{};

  @override
  Iterator<LintRule> get iterator => _ruleMap.values.iterator;

  Iterable<LintRule> get rules => _ruleMap.values;

  LintRule operator [](String key) => _ruleMap[key];

  /// All lint rules explicitly enabled by the given [config].
  ///
  /// For example:
  ///     my_rule: true
  ///
  /// enables `my_rule`.
  ///
  /// Unspecified rules are treated as disabled by default.
  Iterable<LintRule> enabled(LintConfig config) => rules
      .where((rule) => config.ruleConfigs.any((rc) => rc.enables(rule.name)));

  void register(LintRule rule) {
    _ruleMap[rule.name] = rule;
  }
}
