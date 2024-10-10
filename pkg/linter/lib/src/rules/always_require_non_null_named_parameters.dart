// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Specify `@required` on named parameters without defaults.';

class AlwaysRequireNonNullNamedParameters extends LintRule {
  AlwaysRequireNonNullNamedParameters()
      : super(
          name: LintNames.always_require_non_null_named_parameters,
          description: _desc,
          state: State.removed(since: dart3_3),
        );

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
