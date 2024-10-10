// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../analyzer.dart';

const _desc = r'Invocation of `Iterable<E>.contains` with references of'
    r' unrelated types.';

class IterableContainsUnrelatedType extends LintRule {
  IterableContainsUnrelatedType()
      : super(
          name: LintNames.iterable_contains_unrelated_type,
          description: _desc,
          state: State.removed(since: dart3_3),
        );

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
