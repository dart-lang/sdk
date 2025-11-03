// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Specify `@required` on named parameters without defaults.';

class AlwaysRequireNonNullNamedParameters extends AnalysisRule {
  AlwaysRequireNonNullNamedParameters()
    : super(
        name: LintNames.always_require_non_null_named_parameters,
        description: _desc,
        state: RuleState.removed(since: dart3_3),
      );

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.removedLint;
}
