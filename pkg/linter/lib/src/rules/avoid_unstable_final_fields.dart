// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Avoid overriding a final field to return '
    'different values if called multiple times.';

const _details = r'''
This rule has been removed.
''';

class AvoidUnstableFinalFields extends LintRule {
  static const LintCode code = LintCode(
      'avoid_unstable_final_fields',
      'Avoid overriding a final field to return '
          'different values if called multiple times.',
      hasPublishedDocs: true);

  AvoidUnstableFinalFields()
      : super(
            name: 'avoid_unstable_final_fields',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.errors},
            state: State.removed());

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {}
}
