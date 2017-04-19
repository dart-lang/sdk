// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.join_return_with_assignment_when_possible;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Join return statement with assignment when possible.';

const _details = r'''

**DO** join return statement with assignment when possible.

**BAD:**
```
class A {
  B _lazyInstance;
  static B get instance {
    _lazyInstance ??= new B(); // LINT
    return _lazyInstance;
  }
}
```

**GOOD:**
```
class A {
  B _lazyInstance;
  static B get instance => _lazyInstance ??= new B();
}
```

''';

Element _getElementFromAssignmentStatement(Statement node) {
  final visitor = new _AssignmentStatementVisitor();
  node.accept(visitor);
  return visitor.element;
}

Element _getElementFromReturnStatement(Statement node) {
  if (node is ReturnStatement) {
    return DartTypeUtilities.getCanonicalElementFromIdentifier(node.expression);
  }
  return null;
}

class JoinReturnWithAssignment extends LintRule {
  _Visitor _visitor;
  JoinReturnWithAssignment()
      : super(
            name: 'join_return_with_assignment',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _AssignmentStatementVisitor extends SimpleAstVisitor {
  Element element;
  @override
  visitAssignmentExpression(AssignmentExpression node) {
    element =
        DartTypeUtilities.getCanonicalElementFromIdentifier(node.leftHandSide);
  }

  @override
  visitExpressionStatement(ExpressionStatement statement) {
    statement.expression.accept(this);
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) {
    node.unParenthesized.accept(this);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    element = DartTypeUtilities.getCanonicalElementFromIdentifier(node.operand);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    element = DartTypeUtilities.getCanonicalElementFromIdentifier(node.operand);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitBlock(Block node) {
    final statements = node.statements;
    final length = statements.length;
    if (length < 2) {
      return;
    }
    final secondLastStatement = statements[length - 2];
    final lastStatement = statements.last;
    final secondLastElement =
        _getElementFromAssignmentStatement(secondLastStatement);
    final lastElement = _getElementFromReturnStatement(lastStatement);
    Element thirdLastElement;
    if (length >= 3) {
      final thirdLastStatement = statements[length - 3];
      thirdLastElement = _getElementFromAssignmentStatement(thirdLastStatement);
    }
    if (lastElement != null &&
        secondLastElement != thirdLastElement &&
        lastElement == secondLastElement) {
      rule.reportLint(secondLastStatement);
    }
  }
}
