// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc =
    r'Place the `super` call last in a constructor initialization list.';

class SuperGoesLast extends LintRule {
  SuperGoesLast()
      : super(
          name: LintNames.super_goes_last,
          description: _desc,
          state: State.removed(since: dart3),
        );

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
