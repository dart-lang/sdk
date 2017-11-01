// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Prefer using `??=` over testing for null.';

const _details = r'''

**PREFER** using `??=` over testing for null.

As Dart has the `??=` operator, it is advisable to use it where applicable to
improve the brevity of your code.

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

Element _getElementInCondition(Expression rawExpression) {
  final expression = rawExpression.unParenthesized;
  if (expression is BinaryExpression &&
      expression.operator.type == TokenType.EQ_EQ) {
    if (DartTypeUtilities.isNullLiteral(expression.rightOperand)) {
      return DartTypeUtilities
          .getCanonicalElementFromIdentifier(expression.leftOperand);
    }
    if (DartTypeUtilities.isNullLiteral(expression.leftOperand)) {
      return DartTypeUtilities
          .getCanonicalElementFromIdentifier(expression.rightOperand);
    }
  }
  return null;
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
