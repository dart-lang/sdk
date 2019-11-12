// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/ascii_utils.dart';

const _desc = r'Name source files using `lowercase_with_underscores`.';

const _details = r'''

**DO** name source files using `lowercase_with_underscores`.

Some file systems are not case-sensitive, so many projects require filenames to
be all lowercase. Using a separating character allows names to still be readable
in that form. Using underscores as the separator ensures that the name is still
a valid Dart identifier, which may be helpful if the language later supports
symbolic imports.

**GOOD:**

* `slider_menu.dart`
* `file_system.dart`

**BAD:**

* `SliderMenu.dart`
* `filesystem.dart`
* `file-system.dart`

Files without a strict `.dart` extension are ignored.  For example:

**OK:**

* `file-system.g.dart`
* `SliderMenu.css.dart`

The lint `library_names` can be used to enforce the same kind of naming on the
library.

''';

class FileNames extends LintRule implements NodeLintRule {
  FileNames()
      : super(
            name: 'file_names',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final fileName = node.declaredElement.source.shortName;
    if (!isValidDartFileName(fileName)) {
      rule.reportLint(node);
    }
  }
}
