// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r"Don't check for null in custom == operators.";

const _details = r'''

**DON'T** check for null in custom == operators.

As null is a special type, no class can be equivalent to it.  Thus, it is
redundant to check whether the other instance is null. 

**BAD:**
```
class Person {
  final String name;

  @override
  operator ==(other) =>
      other != null && other is Person && name == other.name;
}
```

**GOOD:**
```
class Person {
  final String name;

  @override
  operator ==(other) => other is Person && name == other.name;
}
```

''';

bool _isComparingEquality(TokenType tokenType) =>
    tokenType == TokenType.BANG_EQ || tokenType == TokenType.EQ_EQ;

bool _isComparingParameterWithNull(BinaryExpression node, Element parameter) =>
    _isComparingEquality(node.operator.type) &&
    ((DartTypeUtilities.isNullLiteral(node.leftOperand) &&
            _isParameter(node.rightOperand, parameter)) ||
        (DartTypeUtilities.isNullLiteral(node.rightOperand) &&
            _isParameter(node.leftOperand, parameter)));

bool _isParameter(Expression expression, Element parameter) =>
    DartTypeUtilities.getCanonicalElementFromIdentifier(expression) ==
    parameter;

bool _isParameterWithQuestion(AstNode node, Element parameter) =>
    (node is PropertyAccess &&
        node.operator?.type == TokenType.QUESTION_PERIOD &&
        DartTypeUtilities.getCanonicalElementFromIdentifier(node.target) ==
            parameter) ||
    (node is MethodInvocation &&
        node.operator?.type == TokenType.QUESTION_PERIOD &&
        DartTypeUtilities.getCanonicalElementFromIdentifier(node.target) ==
            parameter);

bool _isParameterWithQuestionQuestion(
        BinaryExpression node, Element parameter) =>
    node.operator.type == TokenType.QUESTION_QUESTION &&
    _isParameter(node.leftOperand, parameter);

class AvoidNullChecksInEqualityOperators extends LintRule {
  _Visitor _visitor;
  AvoidNullChecksInEqualityOperators()
      : super(
            name: 'avoid_null_checks_in_equality_operators',
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
  visitMethodDeclaration(MethodDeclaration node) {
    final parameters = node.parameters?.parameters;
    if (node.name.token?.type == TokenType.EQ_EQ && parameters?.length == 1) {
      final parameter = DartTypeUtilities
          .getCanonicalElementFromIdentifier(parameters.first.identifier);
      bool checkIfParameterIsNull(AstNode node) =>
          _isParameterWithQuestion(node, parameter) ||
          (node is BinaryExpression &&
              (_isParameterWithQuestionQuestion(node, parameter) ||
                  _isComparingParameterWithNull(node, parameter)));

      DartTypeUtilities
          .traverseNodesInDFS(node.body)
          .where(checkIfParameterIsNull)
          .forEach(rule.reportLint);
    }
  }
}
