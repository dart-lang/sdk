// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Avoid using `as`.';

class AvoidAs extends LintRule {
  AvoidAs()
      : super(
          name: LintNames.avoid_as,
          description: _desc,
          state: State.removed(since: dart2_12),
        );

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
