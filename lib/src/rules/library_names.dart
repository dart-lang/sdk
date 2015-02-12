// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library library_names;

import 'package:analyzer/src/generated/ast.dart';
import 'package:linter/src/linter.dart';

const desc =
    'DO name libraries and source files using lowercase_with_underscores.';

const details = r'''
**DO** name libraries and source files using lowercase_with_underscores.

Some file systems are not case-sensitive, so many projects require filenames 
to be all lowercase. Using a separate character allows names to still be 
readable in that form. Using underscores as the separator ensures that the name 
is still a valid Dart identifier, which may be helpful if the language later 
supports symbolic imports.

**GOOD:**

* `slider_menu.dart`
* `file_system.dart`
* `library peg_parser;`

**BAD:**

* `SliderMenu.dart`
* `filesystem.dart`
* `library peg-parser;`
```
''';

final _lowerCaseUnderScore = new RegExp(r'^([a-z]+([_]?[a-z]+))+$');

bool isLowerCaseUnderScore(String id) =>
    _lowerCaseUnderScore.hasMatch(id);

class LibraryNames extends LintRule {
  LibraryNames()
      : super(
          name: 'LibraryNames',
          description: desc,
          details: details,
          group: Group.STYLE_GUIDE,
          kind: Kind.DO);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  @override
  visitLibraryDirective(LibraryDirective node) {
    if (!isLowerCaseUnderScore(node.name.toString())) {
      rule.reportLint(node);
    }
  }
}
