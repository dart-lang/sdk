// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Prefer using a boolean as the assert condition.';

class PreferBoolInAsserts extends LintRule {
  PreferBoolInAsserts()
      : super(
          name: LintNames.prefer_bool_in_asserts,
          description: _desc,
          state: State.removed(since: dart3),
        );

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
