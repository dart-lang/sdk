// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/analyzer.dart';
import 'package:linter/src/utils.dart';

const _desc = r'Use `lowercase_with_underscores` for package names.';

const _details = r'''

From the [Pubspec format description](https://www.dartlang.org/tools/pub/pubspec.html):

**DO** use `lowercase_with_underscores` for package names.

Package names should be all lowercase, with underscores to separate words,
`just_like_this`.  Use only basic Latin letters and Arabic digits: [a-z0-9_].
Also, make sure the name is a valid Dart identifier -- that it doesn't start
with digits and isn't a reserved word.

''';

class PubPackageNames extends LintRule {
  PubPackageNames()
      : super(
            name: 'package_names',
            description: _desc,
            details: _details,
            group: Group.pub);

  @override
  PubspecVisitor getPubspecVisitor() => new Visitor(this);
}

class Visitor extends PubspecVisitor {
  LintRule rule;
  Visitor(this.rule);

  @override
  visitPackageName(PSEntry name) {
    if (!isValidPackageName(name.value.text)) {
      rule.reportPubLint(name.value);
    }
  }
}
