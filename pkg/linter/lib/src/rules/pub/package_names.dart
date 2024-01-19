// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../analyzer.dart';
import '../../utils.dart';

const _desc = r'Use `lowercase_with_underscores` for package names.';

const _details = r'''
From the [Pubspec format description](https://dart.dev/tools/pub/pubspec):

**DO** use `lowercase_with_underscores` for package names.

Package names should be all lowercase, with underscores to separate words,
`just_like_this`.  Use only basic Latin letters and Arabic digits: [a-z0-9_].
Also, make sure the name is a valid Dart identifier -- that it doesn't start
with digits and isn't a reserved word.

''';

class PackageNames extends LintRule {
  static const LintCode code = LintCode('package_names',
      "The package name '{0}' isn't a lower_case_with_underscores identifier.",
      correctionMessage:
          'Try changing the name to follow the lower_case_with_underscores '
          'style.');

  PackageNames()
      : super(
            name: 'package_names',
            description: _desc,
            details: _details,
            group: Group.pub);

  @override
  LintCode get lintCode => code;

  @override
  PubspecVisitor getPubspecVisitor() => Visitor(this);
}

class Visitor extends PubspecVisitor {
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
