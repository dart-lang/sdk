// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../analyzer.dart';
import '../../utils.dart';

const _desc = r'Use `lowercase_with_underscores` for package names.';

class PackageNames extends LintRule {
  PackageNames()
      : super(
          name: LintNames.package_names,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.package_names;

  @override
  PubspecVisitor<void> getPubspecVisitor() => Visitor(this);
}

class Visitor extends PubspecVisitor<void> {
  final LintRule rule;

  Visitor(this.rule);

  @override
  void visitPackageName(PSEntry name) {
    var packageName = name.value.text;
    if (packageName != null && !isValidPackageName(packageName)) {
      rule.reportPubLint(name.value, arguments: [packageName]);
    }
  }
}
