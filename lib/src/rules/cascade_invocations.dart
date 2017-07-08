// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Cascade consecutive method invocations on the same reference.';

const _details = r'''

**DO** Use the cascading style when succesively invoking methods on the same
 reference.

**BAD:**
```
SomeClass someReference = new SomeClass();
someReference.firstMethod();
someReference.secondMethod();
```

**BAD:**
```
SomeClass someReference = new SomeClass();
...
someReference.firstMethod();
someReference.aProperty = value;
someReference.secondMethod();
```

**GOOD:**
```
SomeClass someReference = new SomeClass()
    ..firstMethod()
    ..aProperty = value
    ..secondMethod();
```

**GOOD:**
```
SomeClass someReference = new SomeClass();
...
someReference
    ..firstMethod()
    ..aProperty = value
    ..secondMethod();
```

''';

Element _getElementFromVariableDeclarationStatement(
    VariableDeclarationStatement statement) {
  final variables = statement.variables.variables;
  if (variables.length == 1) {
    return variables.first.element;
  }
  return null;
}

ExecutableElement _getExecutableElementFromMethodInvocation(
    MethodInvocation node) {
  if (_isInvokedWithoutNullAwareOperator(node.operator)) {
    final executableElement =
        DartTypeUtilities.getCanonicalElementFromIdentifier(node.methodName);
    if (executableElement is ExecutableElement) {
      return executableElement;
    }
  }
  return null;
}

Element _getPrefixElementFromExpression(Expression rawExpression) {
  final expression = rawExpression.unParenthesized;
  if (expression is PrefixedIdentifier) {
    return DartTypeUtilities
        .getCanonicalElementFromIdentifier(expression.prefix);
  } else if (expression is PropertyAccess &&
      _isInvokedWithoutNullAwareOperator(expression.operator)) {
    return DartTypeUtilities
        .getCanonicalElementFromIdentifier(expression.target);
  }
  return null;
}

Element _getTargetElementFromCascadeExpression(CascadeExpression node) =>
    DartTypeUtilities.getCanonicalElementFromIdentifier(node.target);

Element _getTargetElementFromMethodInvocation(MethodInvocation node) =>
    DartTypeUtilities.getCanonicalElementFromIdentifier(node.target);

bool _isInvokedWithoutNullAwareOperator(Token token) =>
    token?.type == TokenType.PERIOD;

/// Rule to lint consecutive invocations of methods or getters on the same
/// reference that could be done with the cascade operator.
class CascadeInvocations extends LintRule {
  _Visitor _visitor;

  /// Default constructor.
  CascadeInvocations()
      : super(
            name: 'cascade_invocations',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

/// A CascadableExpression is an object that is built from an expression and
/// knows if it is able to join to another CascadableExpression.
class _CascadableExpression {
  static final NULL_CASCADABLE_EXPRESSION = new _CascadableExpression._internal(
      null, [],
      canJoin: false, canReceive: false, canBeCascaded: false);

  final bool canJoin;
  final bool canReceive;
  final bool canBeCascaded;

  /// This is necessary when you have a variable declaration so that element
  /// is critical and it can't be used as a parameter of a method invocation or
  /// in the right part of an assignment in a following expression that we would
  /// like to join to this.
  final bool isCritical;
  final Element element;
  final List<AstNode> criticalNodes;

  factory _CascadableExpression.fromExpressionStatement(
      ExpressionStatement statement) {
    final expression = statement.expression.unParenthesized;
    if (expression is AssignmentExpression) {
      return new _CascadableExpression._fromAssignmentExpression(expression);
    }
    if (expression is MethodInvocation) {
      return new _CascadableExpression._fromMethodInvocation(expression);
    }
    if (expression is CascadeExpression) {
      return new _CascadableExpression._fromCascadeExpression(expression);
    }
    if (expression is PropertyAccess &&
        _isInvokedWithoutNullAwareOperator(expression.operator)) {
      return new _CascadableExpression._fromPropertyAccess(expression);
    }
    if (expression is PrefixedIdentifier) {
      return new _CascadableExpression._fromPrefixedIdentifier(expression);
    }
    return NULL_CASCADABLE_EXPRESSION;
  }

  factory _CascadableExpression.fromVariableDeclarationStatement(
      VariableDeclarationStatement node) {
    final element = _getElementFromVariableDeclarationStatement(node);
    return new _CascadableExpression._internal(element, [],
        canJoin: false,
        canReceive: true,
        canBeCascaded: false,
        isCritical: true);
  }

  factory _CascadableExpression._fromAssignmentExpression(
      AssignmentExpression node) {
    final leftExpression = node.leftHandSide.unParenthesized;
    if (leftExpression is SimpleIdentifier) {
      return new _CascadableExpression._internal(
          DartTypeUtilities.getCanonicalElement(leftExpression.bestElement),
          [node.rightHandSide],
          canJoin: false,
          canReceive: node.operator.type != TokenType.QUESTION_QUESTION_EQ,
          canBeCascaded: false,
          isCritical: true);
    }
    // setters
    final VariableElement variable =
        _getPrefixElementFromExpression(node.leftHandSide);
    final canReceive = node.operator.type != TokenType.QUESTION_QUESTION_EQ &&
        !variable.isStatic;
    return new _CascadableExpression._internal(variable, [node.rightHandSide],
        canJoin: true, canReceive: canReceive, canBeCascaded: true);
  }

  factory _CascadableExpression._fromCascadeExpression(
          CascadeExpression node) =>
      new _CascadableExpression._internal(
          _getTargetElementFromCascadeExpression(node), node.cascadeSections,
          canJoin: true, canReceive: true, canBeCascaded: true);

  factory _CascadableExpression._fromMethodInvocation(MethodInvocation node) {
    final executableElement = _getExecutableElementFromMethodInvocation(node);
    bool isNonStatic = executableElement?.isStatic == false;
    if (isNonStatic) {
      final isSimpleIdentifier = node.target is SimpleIdentifier;
      return new _CascadableExpression._internal(
          _getTargetElementFromMethodInvocation(node), [node.argumentList],
          canJoin: isSimpleIdentifier,
          canReceive: isSimpleIdentifier,
          canBeCascaded: true);
    }
    return NULL_CASCADABLE_EXPRESSION;
  }

  factory _CascadableExpression._fromPrefixedIdentifier(
      PrefixedIdentifier node) {
    return new _CascadableExpression._internal(
        DartTypeUtilities.getCanonicalElementFromIdentifier(node.prefix), [],
        canJoin: true, canReceive: true, canBeCascaded: true);
  }

  factory _CascadableExpression._fromPropertyAccess(PropertyAccess node) {
    return new _CascadableExpression._internal(
        DartTypeUtilities.getCanonicalElementFromIdentifier(node.target), [],
        canJoin: true, canReceive: true, canBeCascaded: true);
  }

  _CascadableExpression._internal(this.element, this.criticalNodes,
      {this.canJoin,
      this.canReceive,
      this.canBeCascaded,
      this.isCritical: false});

  bool compatibleWith(_CascadableExpression expressionBox) =>
      element != null &&
      expressionBox.canReceive &&
      canJoin &&
      (canBeCascaded || expressionBox.canBeCascaded) &&
      element == expressionBox.element &&
      !_hasCriticalDependencies(expressionBox);

  bool _hasCriticalDependencies(_CascadableExpression expressionBox) {
    bool _isCriticalNode(AstNode node) =>
        DartTypeUtilities.getCanonicalElementFromIdentifier(node) ==
        expressionBox.element;
    return expressionBox.isCritical &&
        criticalNodes.any((node) =>
            _isCriticalNode(node) ||
            DartTypeUtilities.traverseNodesInDFS(node).any(_isCriticalNode));
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitBlock(Block node) {
    if (node.statements.length < 2) {
      return;
    }
    var previousExpressionBox =
        _CascadableExpression.NULL_CASCADABLE_EXPRESSION;
    for (final statement in node.statements) {
      var currentExpressionBox =
          _CascadableExpression.NULL_CASCADABLE_EXPRESSION;
      if (statement is VariableDeclarationStatement) {
        currentExpressionBox =
            new _CascadableExpression.fromVariableDeclarationStatement(
                statement);
      }
      if (statement is ExpressionStatement) {
        currentExpressionBox =
            new _CascadableExpression.fromExpressionStatement(statement);
      }
      if (currentExpressionBox.compatibleWith(previousExpressionBox)) {
        rule.reportLint(statement);
      }
      previousExpressionBox = currentExpressionBox;
    }
  }
}
