// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Do use sound null safety.';

class EnableNullSafety extends LintRule {
  EnableNullSafety()
    : super(
        name: LintNames.enable_null_safety,
        description: _desc,
        state: RuleState.removed(since: dart3),
      );

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.removed_lint;
}
