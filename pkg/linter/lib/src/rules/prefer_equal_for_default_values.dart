// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Use `=` to separate a named parameter from its default value.';

class PreferEqualForDefaultValues extends LintRule {
  PreferEqualForDefaultValues()
      : super(
          name: LintNames.prefer_equal_for_default_values,
          description: _desc,
          state: State.removed(since: dart3),
        );

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
