// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../utils.dart';

const _desc = r'Name libraries using `lowercase_with_underscores`.';

const _details = r'''
**DO** name libraries using `lowercase_with_underscores`.

Some file systems are not case-sensitive, so many projects require filenames to
be all lowercase. Using a separating character allows names to still be readable
in that form. Using underscores as the separator ensures that the name is still
a valid Dart identifier, which may be helpful if the language later supports
symbolic imports.

**BAD:**
```dart
library peg-parser;
```

**GOOD:**
```dart
library peg_parser;
```

The lint `file_names` can be used to enforce the same kind of naming on the
file.

''';

class LibraryNames extends LintRule {
  static const LintCode code = LintCode(
      'library_names', "The library name '{0}' isn't a snake_case identifier.",
      correctionMessage:
          'Try changing the name to follow the snake_case style.');

  LibraryNames()
      : super(
            name: 'library_names',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addLibraryDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitLibraryDirective(LibraryDirective node) {
    var name = node.name2;
    if (name != null && !isLowerCaseUnderScoreWithDots(name.toString())) {
      rule.reportLint(name, arguments: [name.toString()]);
    }
  }
}
