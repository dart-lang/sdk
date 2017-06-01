// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.prefer_const_constructors_in_immutables;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart' show AstVisitor;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const desc = 'Prefer put asserts in initializer list.';

const details = '''
**DO** put asserts in initializer list for constructors with only asserts in
their body.

**GOOD:**
```
class A {
  A(int a) : assert(a != null);
}
```

**BAD:**
```
class A {
  A(int a) {
    assert(a != null);
  }
}
```
''';

class PreferAssertsInInitializerList extends LintRule {
  PreferAssertsInInitializerList()
      : super(
            name: 'prefer_asserts_in_initializer_list',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;

  Visitor(this.rule);

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.element.isFactory) return;

    final body = node.body;
    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is! AssertStatement) break;

        final assertVisitor = new _AssertVisitor(node.element);
        statement.visitChildren(assertVisitor);
        if (!assertVisitor.needInstance) {
          rule.reportLintForToken(statement.beginToken);
        }
      }
    }
  }
}

class _AssertVisitor extends RecursiveAstVisitor {
  _AssertVisitor(this.constructorElement);

  final ConstructorElement constructorElement;
  bool needInstance = false;

  ClassElement get classElement => constructorElement.enclosingElement;

  bool _isInstanceNeeded(Expression node) {
    if (node is MethodInvocation) {
      return _isInstanceNeeded(node.target);
    } else if (node is PropertyAccess) {
      return _isInstanceNeeded(node.target);
    } else if (node is SimpleIdentifier) {
      final element = node.staticElement;
      if (element?.enclosingElement == classElement) {
        if (element is MethodElement) return true;
        if (element is PropertyAccessorElement) {
          return !constructorElement.parameters
              .where((p) => p is FieldFormalParameterElement)
              .any((p) =>
                  (p as FieldFormalParameterElement).field.getter == element);
        }
      }
      return false;
    } else {
      return false;
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (_isInstanceNeeded(node)) {
      needInstance = true;
    }
    super.visitMethodInvocation(node);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    if (_isInstanceNeeded(node)) {
      needInstance = true;
    }
    super.visitPropertyAccess(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (_isInstanceNeeded(node)) {
      needInstance = true;
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  visitThisExpression(ThisExpression node) {
    needInstance = true;
    super.visitThisExpression(node);
  }
}
