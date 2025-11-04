// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';

export 'package:analyzer/src/error/codes.dart';
export 'package:analyzer_testing/analysis_rule/analysis_rule.dart' show error;
export 'package:linter/src/lint_names.dart';

mixin LanguageVersion219Mixin on PubPackageResolutionTest {
  @override
  String? get testPackageLanguageVersion => '2.19';
}

/// A base test class for all of the "built-in" lint rules.
abstract class LintRuleTest extends AnalysisRuleTest {
  static bool _lintRulesAreRegistered = false;

  @override
  String get analysisRule => lintRule;

  /// The lint rule being tested.
  String get lintRule;

  @mustCallSuper
  @override
  void setUp() {
    if (!_lintRulesAreRegistered) {
      registerLintRules();
      _lintRulesAreRegistered = true;
    }
    rule = Registry.ruleRegistry.rules.firstWhere(
      (r) => r.name == analysisRule,
    );
    super.setUp();
  }
}
