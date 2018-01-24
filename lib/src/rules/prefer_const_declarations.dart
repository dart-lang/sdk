// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
// ignore: implementation_imports


const _desc = r'Prefer const over final for declarations.';

const _details = r'''

**PREFER** using `const` for const declarations.

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
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (node.variables.isConst) return;
    if (!node.variables.isFinal) return;
    if (node.variables.variables
        .every((declaration) => _isConst(declaration.initializer))) {
      rule.reportLint(node);
    }
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic) return;
    if (node.fields.isConst) return;
    if (!node.fields.isFinal) return;
    if (node.fields.variables
        .every((declaration) => _isConst(declaration.initializer))) {
      rule.reportLint(node);
    }
  }

  bool _isConst(Expression expression) {
    if (expression is ParenthesizedExpression)
      return _isConst(expression.unParenthesized);
    return expression is NullLiteral ||
        expression is IntegerLiteral ||
        expression is DoubleLiteral ||
        expression is SimpleStringLiteral ||
        expression is InstanceCreationExpression && expression.isConst ||
        expression is ListLiteral && expression.constKeyword != null ||
        expression is MapLiteral && expression.constKeyword != null;
  }
}
