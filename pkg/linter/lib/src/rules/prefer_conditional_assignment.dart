// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/dart_type_utilities.dart' as type_utils;

const _desc = r'Prefer using `??=` over testing for null.';

const _details = r'''
**PREFER** using `??=` over testing for null.

As Dart has the `??=` operator, it is advisable to use it where applicable to
improve the brevity of your code.

**BAD:**
```dart
String get fullName {
  if (_fullName == null) {
    _fullName = getFullUserName(this);
  }
  return _fullName;
}
```

**GOOD:**
```dart
String get fullName {
  return _fullName ??= getFullUserName(this);
}
```

''';

bool _checkExpression(Expression expression, Expression condition) =>
    expression is AssignmentExpression &&
    type_utils.canonicalElementsFromIdentifiersAreEqual(
        expression.leftHandSide, condition);

bool _checkStatement(Statement statement, Expression condition) {
  if (statement is ExpressionStatement) {
    return _checkExpression(statement.expression, condition);
  }
  if (statement is Block && statement.statements.length == 1) {
    return _checkStatement(statement.statements.first, condition);
  }
  return false;
}

Expression? _getExpressionCondition(Expression rawExpression) {
  var expression = rawExpression.unParenthesized;
  if (expression is BinaryExpression &&
      expression.operator.type == TokenType.EQ_EQ) {
    if (expression.rightOperand.isNullLiteral) {
      return expression.leftOperand;
    }
    if (expression.leftOperand.isNullLiteral) {
      return expression.rightOperand;
    }
  }
  return null;
}

class PreferConditionalAssignment extends LintRule {
  static const LintCode code = LintCode('prefer_conditional_assignment',
      "The 'if' statement could be replaced by a null-aware assignment.",
      correctionMessage:
          "Try using the '??=' operator to conditionally assign a value.");

  PreferConditionalAssignment()
      : super(
            name: 'prefer_conditional_assignment',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addIfStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitIfStatement(IfStatement node) {
    if (node.elseStatement != null) {
      return;
    }
    var expressionInCondition = _getExpressionCondition(node.expression);
    if (expressionInCondition != null &&
        _checkStatement(node.thenStatement, expressionInCondition)) {
      rule.reportLint(node);
    }
  }
}
