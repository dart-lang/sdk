// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc =
    r'Conditions should not unconditionally evaluate to `true` or to `false`.';

class InvariantBooleans extends LintRule {
  InvariantBooleans()
      : super(
          name: LintNames.invariant_booleans,
          description: _desc,
          state: State.removed(since: dart3),
        );

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
