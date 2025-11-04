// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Avoid returning null for Future.';

class AvoidReturningNullForFuture extends AnalysisRule {
  AvoidReturningNullForFuture()
    : super(
        name: LintNames.avoid_returning_null_for_future,
        description: _desc,
        state: RuleState.removed(since: dart3_3),
      );

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.removedLint;
}
