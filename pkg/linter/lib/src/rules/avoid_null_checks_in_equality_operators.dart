// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';

import '../analyzer.dart';

const _desc = r"Don't check for `null` in custom `==` operators.";

class AvoidNullChecksInEqualityOperators extends LintRule {
  AvoidNullChecksInEqualityOperators()
      : super(
            name: LintNames.avoid_null_checks_in_equality_operators,
            description: _desc,
            state: State.removed(since: Version(3, 7, 0)));

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
