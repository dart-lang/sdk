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

**GOOD:**

* `library peg_parser;`

**BAD:**

* `library peg-parser;`

The lint `file_names` can be used to enforce the same kind of naming on the
file.

''';

class LibraryNames extends LintRule implements NodeLintRule {
  LibraryNames()
      : super(
            name: 'library_names',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addLibraryDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitLibraryDirective(LibraryDirective node) {
    if (!isLowerCaseUnderScoreWithDots(node.name.toString())) {
      rule.reportLint(node.name);
    }
  }
}
