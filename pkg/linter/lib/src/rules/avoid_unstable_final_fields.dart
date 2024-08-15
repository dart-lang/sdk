// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Avoid overriding a final field to return '
    'different values if called multiple times.';

const _details = r'''
This rule has been removed.
''';

class AvoidUnstableFinalFields extends LintRule {
  AvoidUnstableFinalFields()
      : super(
            name: 'avoid_unstable_final_fields',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.errors},
            state: State.removed());

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
