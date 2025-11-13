// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Use `=` to separate a named parameter from its default value.';

class PreferEqualForDefaultValues extends AnalysisRule {
  PreferEqualForDefaultValues()
    : super(
        name: LintNames.prefer_equal_for_default_values,
        description: _desc,
        state: RuleState.removed(since: dart3),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.removedLint;
}
