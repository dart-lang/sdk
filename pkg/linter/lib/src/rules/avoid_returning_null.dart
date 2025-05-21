// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports

import '../analyzer.dart';

const _desc =
    r'Avoid returning null from members whose return type is bool, double, int,'
    r' or num.';

class AvoidReturningNull extends LintRule {
  AvoidReturningNull()
    : super(
        name: LintNames.avoid_returning_null,
        description: _desc,
        state: RuleState.removed(since: dart3_3),
      );

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.removed_lint;
}
