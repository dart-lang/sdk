// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const _desc = r'Prefer const over final for declarations.';

const _details = r'''

**PREFER** using `const` for const declarations.

Const declarations are more hot-reload friendly and allow to use const
constructors if an instantiation references this declaration.

**GOOD:**
```
const o = const [];

class A {
  static const o = const [];
}
```

**BAD:**
```
final o = const [];

class A {
  static final o = const [];
}
```

''';

class PreferConstDeclarations extends LintRule {
  _Visitor _visitor;

  PreferConstDeclarations()
      : super(
            name: 'prefer_const_declarations',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic) return;
    _visitVariableDeclarationList(node.fields);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      _visitVariableDeclarationList(node.variables);

  @override
  visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      _visitVariableDeclarationList(node.variables);

  _visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.isConst) return;
    if (!node.isFinal) return;
    if (node.variables.every((declaration) =>
        declaration.initializer != null &&
        !hasErrorWithConstantVisitor(declaration.initializer))) {
      rule.reportLint(node);
    }
  }
}
