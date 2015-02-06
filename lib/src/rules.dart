// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library rules;

import 'package:analyzer/src/services/lint.dart';
import 'package:dart_lint/src/linter.dart';
import 'package:dart_lint/src/rules/super_goes_last.dart';
import 'package:dart_lint/src/rules/unnecessary_brace_in_string_interp.dart';

/// Map of contributed lint rules.
final Map<String, Linter> ruleMap = {
  'super_goes_last': new SuperGoesLast(),
  'unnecessary_brace_in_string_interp': new UnnecessaryBraceInStringInterp()
};

class Rule {

  /// Whether this rule is enabled in the current rule set.
  bool enabled;
  /// A uniquely identifying name for this rule.
  final String ruleName;
  /// The associated linter.
  final Linter linter;

  Rule(this.ruleName, this.linter, {this.enabled: false});
}

class RuleRegistry {
  final Reporter reporter;
  final Map<String, Rule> _ruleMap = <String, Rule>{};

  RuleRegistry([this.reporter = const PrintingReporter()]) {
    // Register rules
    ruleMap.forEach((n, l) => registerLinter(n, l));
  }

  /// An empty registry for testing
  RuleRegistry.empty(this.reporter);

  Iterable<Linter> get enabledLints =>
      _ruleMap.values.where((Rule r) => r.enabled).map((Rule r) => r.linter);

  void disable(String ruleName) {
    if (_ruleMap[ruleName] == null) {
      reporter.warn("No rule registered to '$ruleName', cannot disable");
    } else {
      _ruleMap[ruleName].enabled = false;
    }
  }

  void enable(String ruleName) {
    if (_ruleMap[ruleName] == null) {
      reporter.warn("No rule registered to '$ruleName', cannot enable");
    } else {
      _ruleMap[ruleName].enabled = true;
    }
  }

  void registerLinter(String name, Linter linter) {
    if (_ruleMap[name] != null) {
      reporter.warn("Multiple linter rules registered to name '$name'");
    }
    _ruleMap[name] = new Rule(name, linter);
  }
}
