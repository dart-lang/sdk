// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart' as type_utils;

const _desc = r'Join return statement with assignment when possible.';

const _details = r'''
**DO** join return statement with assignment when possible.

**BAD:**
```dart
class A {
  B _lazyInstance;
  static B get instance {
    _lazyInstance ??= B(); // LINT
    return _lazyInstance;
  }
}
```

**GOOD:**
```dart
class A {
  B _lazyInstance;
  static B get instance => _lazyInstance ??= B();
}
```

''';

Expression? _getExpressionFromAssignmentStatement(Statement node) {
  if (node is ExpressionStatement) {
    var expression = node.expression.unParenthesized;
    if (expression is AssignmentExpression) {
      return expression.leftHandSide;
    } else if (expression is PostfixExpression) {
      return expression.operand;
    } else if (expression is PrefixExpression) {
      return expression.operand;
    }
  }
  return null;
}

Expression? _getExpressionFromReturnStatement(Statement node) =>
    node is ReturnStatement ? node.expression : null;

class JoinReturnWithAssignment extends LintRule {
  static const LintCode code = LintCode('join_return_with_assignment',
      "Assignment could be inlined in 'return' statement.",
      correctionMessage:
          "Try inlining the assigned value in the 'return' statement.");

  JoinReturnWithAssignment()
      : super(
            name: 'join_return_with_assignment',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addBlock(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitBlock(Block node) {
    var statements = node.statements;
    var length = statements.length;
    if (length < 2) {
      return;
    }
    var lastExpression = _getExpressionFromReturnStatement(statements.last);

    // In this case, the last statement was not a return statement with a
    // simple target.
    if (lastExpression == null) {
      return;
    }

    var secondLastStatement = statements[length - 2];
    var secondLastExpression =
        _getExpressionFromAssignmentStatement(secondLastStatement);
    // Return if the second-to-last statement was not an assignment.
    if (secondLastExpression == null) {
      return;
    }

    Expression? thirdLastExpression;
    if (length >= 3) {
      var thirdLastStatement = statements[length - 3];
      thirdLastExpression =
          _getExpressionFromAssignmentStatement(thirdLastStatement);
    }
    if (!type_utils.canonicalElementsFromIdentifiersAreEqual(
            secondLastExpression, thirdLastExpression) &&
        type_utils.canonicalElementsFromIdentifiersAreEqual(
            lastExpression, secondLastExpression)) {
      rule.reportLint(secondLastStatement);
    }
  }
}
