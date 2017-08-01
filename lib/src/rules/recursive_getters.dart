// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Property getter recursivlely returns itself.';

const _details = r'''

**DON'T** Return the property itself in a getter body, this can be due to a typo.

**BAD:**
```
  int get field => field; // LINT
```

**BAD:**
```
  int get otherField {
    return otherField; // LINT
  }
```

**GOOD:**
```
  int get field => _field;
```

''';

class RecursiveGetters extends LintRule {
  _Visitor _visitor;

  RecursiveGetters()
      : super(
            name: 'recursive_getters',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

/// Tests if a simple identifier is a recursive getter by looking at its parent.
class _RecursiveGetterParentVisitor extends SimpleAstVisitor<bool> {
  @override
  bool visitPropertyAccess(PropertyAccess node) =>
      node.target is ThisExpression;

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.parent is ArgumentList ||
        node.parent is ConditionalExpression ||
        node.parent is ExpressionFunctionBody ||
        node.parent is ReturnStatement) {
      return true;
    }

    if (node.parent is PropertyAccess) {
      return node.parent.accept(this);
    }

    return false;
  }
}

class _Visitor extends SimpleAstVisitor {
  final visitor = new _RecursiveGetterParentVisitor();
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // getters have null arguments, methods have parameters, could be empty.
    if (node.functionExpression.parameters != null) {
      return;
    }

    final element = node.element;
    _verifyElement(node.functionExpression, element);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // getters have null arguments, methods have parameters, could be empty.
    if (node.parameters != null) {
      return;
    }

    final element = node.element;
    _verifyElement(node.body, element);
  }

  void _verifyElement(AstNode node, ExecutableElement element) {
    final nodes = DartTypeUtilities.traverseNodesInDFS(node);
    nodes
        .where((n) =>
            n is SimpleIdentifier &&
            element == n.staticElement &&
            n.accept(visitor))
        .forEach(rule.reportLint);
  }
}
