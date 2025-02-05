// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';

import '../analyzer.dart';

class UnsafeHtml extends LintRule {
  UnsafeHtml()
      : super(
            name: LintNames.unsafe_html,
            description: 'Avoid unsafe HTML APIs.',
            state: State.removed(since: Version(3, 7, 0)));

  @override
  LintCode get lintCode => LinterLintCode.removed_lint;
}
