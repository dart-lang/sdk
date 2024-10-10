// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc =
    r'Avoid returning null from members whose return type is bool, double, int,'
    r' or num.';

class AvoidReturningNull extends LintRule {
  AvoidReturningNull()
      : super(
          name: LintNames.avoid_returning_null,
          description: _desc,
          state: State.removed(since: dart3_3),
        );

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
