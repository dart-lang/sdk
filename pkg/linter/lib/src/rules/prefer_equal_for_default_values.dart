// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports

import '../analyzer.dart';

const _desc = r'Use `=` to separate a named parameter from its default value.';

class PreferEqualForDefaultValues extends LintRule {
  PreferEqualForDefaultValues()
    : super(
        name: LintNames.prefer_equal_for_default_values,
        description: _desc,
        state: RuleState.removed(since: dart3),
      );

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.removed_lint;
}
