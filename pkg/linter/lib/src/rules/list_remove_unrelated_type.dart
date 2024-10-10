// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Invocation of `remove` with references of unrelated types.';

class ListRemoveUnrelatedType extends LintRule {
  ListRemoveUnrelatedType()
      : super(
          name: LintNames.list_remove_unrelated_type,
          description: _desc,
          state: State.removed(since: dart3_3),
        );

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
