// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc =
    r'Avoid overriding a final field to return '
    'different values if called multiple times.';

class AvoidUnstableFinalFields extends LintRule {
  AvoidUnstableFinalFields()
    : super(
        name: LintNames.avoid_unstable_final_fields,
        description: _desc,
        state: const RuleState.removed(),
      );

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.removedLint;
}
