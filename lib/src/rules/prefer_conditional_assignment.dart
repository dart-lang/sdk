// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.prefer_conditional_assignment;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Prefer ??= over testing for null.';

const _details = r'''

**PREFER** ??= over testing for null.

**BAD:**
```
String get fullName {
  if (_fullName == null) {
    _fullName = getFullUserName(this);
  }
  return _fullName;
}
```

**GOOD:**
```
String get fullName {
  return _fullName ??= getFullUserName(this);;
}
```

''';

bool _checkExpression(Expression expression, Element element) =>
    expression is AssignmentExpression &&
    DartTypeUtilities
            .getCanonicalElementFromIdentifier(expression.leftHandSide) ==
        element;

bool _checkStatement(Statement statement, Element element) {
  if (statement is ExpressionStatement) {
    return _checkExpression(statement.expression, element);
  }
  if (statement is Block && statement.statements.length == 1) {
    return _checkStatement(statement.statements.first, element);
  }
  return false;
}

Element _getElementInCondition(Expression node) {
  if (node is ParenthesizedExpression) {
    return _getElementInCondition(node.expression);
  }
  if (node is BinaryExpression && node.operator.type == TokenType.EQ_EQ) {
    if (_isNullLiteral(node.rightOperand)) {
      return DartTypeUtilities
          .getCanonicalElementFromIdentifier(node.leftOperand);
    }
    if (_isNullLiteral(node.leftOperand)) {
      return DartTypeUtilities
          .getCanonicalElementFromIdentifier(node.rightOperand);
    }
  }
  return null;
}

bool _isNullLiteral(Expression node) {
  if (node is ParenthesizedExpression) {
    return _isNullLiteral(node.expression);
  }
  return node is NullLiteral;
}

class PreferConditionalAssignment extends LintRule {
  _Visitor _visitor;
  PreferConditionalAssignment()
      : super(
            name: 'prefer_conditional_assignment',
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
  visitIfStatement(IfStatement node) {
    if (node.elseStatement != null) {
      return;
    }
    final elementInCondition = _getElementInCondition(node.condition);
    if (elementInCondition != null &&
        _checkStatement(node.thenStatement, elementInCondition)) {
      rule.reportLint(node);
    }
  }
}
