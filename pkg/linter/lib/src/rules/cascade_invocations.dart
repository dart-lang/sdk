// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Cascade consecutive method invocations on the same reference.';

const _details = r'''
**DO** Use the cascading style when successively invoking methods on the same
reference.

**BAD:**
```dart
SomeClass someReference = SomeClass();
someReference.firstMethod();
someReference.secondMethod();
```

**BAD:**
```dart
SomeClass someReference = SomeClass();
...
someReference.firstMethod();
someReference.aProperty = value;
someReference.secondMethod();
```

**GOOD:**
```dart
SomeClass someReference = SomeClass()
    ..firstMethod()
    ..aProperty = value
    ..secondMethod();
```

**GOOD:**
```dart
SomeClass someReference = SomeClass();
...
someReference
    ..firstMethod()
    ..aProperty = value
    ..secondMethod();
```

''';

Element? _getElementFromVariableDeclarationStatement(
    VariableDeclarationStatement statement) {
  var variables = statement.variables.variables;
  if (variables.length == 1) {
    var variable = variables.single;
    if (variable.initializer is AwaitExpression) {
      // `await` has a higher precedence than a cascade, but because the token
      // `await` is followed by whitespace, it may look like the cascade binds
      // tighter, for example in `await Future.value([1,2,3])..forEach(print)`.
      //
      // In such a case, we should not return any cascadable element here.
      return null;
    }
    return variable.declaredElement;
  }
  return null;
}

ExecutableElement? _getExecutableElementFromMethodInvocation(
    MethodInvocation node) {
  if (_isInvokedWithoutNullAwareOperator(node.operator)) {
    var executableElement = node.methodName.canonicalElement;
    if (executableElement is ExecutableElement) {
      return executableElement;
    }
  }
  return null;
}

Element? _getPrefixElementFromExpression(Expression rawExpression) {
  var expression = rawExpression.unParenthesized;
  if (expression is PrefixedIdentifier) {
    return expression.prefix.canonicalElement;
  } else if (expression is PropertyAccess &&
      _isInvokedWithoutNullAwareOperator(expression.operator) &&
      expression.target is SimpleIdentifier) {
    return expression.target.canonicalElement;
  }
  return null;
}

Element? _getTargetElementFromCascadeExpression(CascadeExpression node) =>
    node.target.canonicalElement;

Element? _getTargetElementFromMethodInvocation(MethodInvocation node) =>
    node.target.canonicalElement;

bool _isInvokedWithoutNullAwareOperator(Token? token) =>
    token?.type == TokenType.PERIOD;

/// Rule to lint consecutive invocations of methods or getters on the same
/// reference that could be done with the cascade operator.
class CascadeInvocations extends LintRule {
  static const LintCode code = LintCode(
      'cascade_invocations', 'Unnecessary duplication of receiver.',
      correctionMessage: 'Try using a cascade to avoid the duplication.');

  /// Default constructor.
  CascadeInvocations()
      : super(
            name: 'cascade_invocations',
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

/// A CascadableExpression is an object that is built from an expression and
/// knows if it is able to join to another CascadableExpression.
class _CascadableExpression {
  static final nullCascadableExpression =
      _CascadableExpression._internal(null, []);

  /// Whether this expression can be joined with a previous expression via a
  /// cascade operation.
  ///
  /// If this expression is a [PropertyAccess], [CascadeExpression], or
  /// [MethodInvocation] in which the target is not a [SimpleIdentifier], or an
  /// [AssignmentExpression] in which the left side is not a [SimpleIdentifier],
  /// it cannot join. See bugs https://github.com/dart-lang/linter/issues/1323
  /// and https://github.com/dart-lang/linter/issues/3240.
  // TODO(srawlins): Refactor this lint, (https://github.com/dart-lang/linter/issues/3240)
  // rule to use
  // DartTypeUtilities.canonicalElementsFromIdentifiersAreEqual(), which
  // should remove this need for checking for a simple target.
  final bool canJoin;

  /// Whether this expression can receive an additional expression with a
  /// cascade operation.
  ///
  /// For example, `a.b = 1` can receive, but `a = 1` cannot receive.
  ///
  /// If this expression is a [PropertyAccess], [CascadeExpression], or
  /// [MethodInvocation] in which the target is not a [SimpleIdentifier], or an
  /// [AssignmentExpression] in which the left side is not a [SimpleIdentifier],
  /// it cannot receive. See bugs
  /// https://github.com/dart-lang/linter/issues/1323 and
  /// https://github.com/dart-lang/linter/issues/3240.
  // TODO(srawlins): Refactor this lint, (https://github.com/dart-lang/linter/issues/3240)
  // rule to use
  // DartTypeUtilities.canonicalElementsFromIdentifiersAreEqual(), which
  // should remove this need for checking for a simple target.
  final bool canReceive;
  final bool canBeCascaded;

  /// This is necessary when you have a variable declaration so that element
  /// is critical and it can't be used as a parameter of a method invocation or
  /// in the right part of an assignment in a following expression that we would
  /// like to join to this.
  final bool isCritical;
  final Element? element;
  final List<AstNode> criticalNodes;

  factory _CascadableExpression.fromExpressionStatement(
      ExpressionStatement statement) {
    var expression = statement.expression.unParenthesized;
    if (expression is AssignmentExpression) {
      return _CascadableExpression._fromAssignmentExpression(expression);
    }
    if (expression is MethodInvocation) {
      return _CascadableExpression._fromMethodInvocation(expression);
    }
    if (expression is CascadeExpression) {
      return _CascadableExpression._fromCascadeExpression(expression);
    }
    if (expression is PropertyAccess &&
        _isInvokedWithoutNullAwareOperator(expression.operator)) {
      return _CascadableExpression._fromPropertyAccess(expression);
    }
    if (expression is PrefixedIdentifier) {
      return _CascadableExpression._fromPrefixedIdentifier(expression);
    }
    return nullCascadableExpression;
  }

  factory _CascadableExpression.fromVariableDeclarationStatement(
      VariableDeclarationStatement node) {
    var element = _getElementFromVariableDeclarationStatement(node);
    return _CascadableExpression._internal(element, [],
        canReceive: true, isCritical: true);
  }

  factory _CascadableExpression._fromAssignmentExpression(
      AssignmentExpression node) {
    var leftExpression = node.leftHandSide.unParenthesized;
    if (leftExpression is SimpleIdentifier) {
      return _CascadableExpression._internal(
          leftExpression.staticElement?.canonicalElement, [node.rightHandSide],
          canReceive: node.operator.type != TokenType.QUESTION_QUESTION_EQ,
          isCritical: true);
    }
    // setters
    var variable = _getPrefixElementFromExpression(leftExpression);
    var canReceive = node.operator.type != TokenType.QUESTION_QUESTION_EQ &&
        variable is VariableElement &&
        !variable.isStatic;
    return _CascadableExpression._internal(variable, [node.rightHandSide],
        canJoin: true, canReceive: canReceive, canBeCascaded: true);
  }

  factory _CascadableExpression._fromCascadeExpression(CascadeExpression node) {
    var targetIsSimple = node.target is SimpleIdentifier;
    return _CascadableExpression._internal(
        _getTargetElementFromCascadeExpression(node), node.cascadeSections,
        canJoin: targetIsSimple,
        canReceive: targetIsSimple,
        canBeCascaded: true);
  }

  factory _CascadableExpression._fromMethodInvocation(MethodInvocation node) {
    var executableElement = _getExecutableElementFromMethodInvocation(node);
    var isNonStatic = executableElement?.isStatic == false;
    if (isNonStatic) {
      var targetIsSimple = node.target is SimpleIdentifier;
      return _CascadableExpression._internal(
          _getTargetElementFromMethodInvocation(node), [node.argumentList],
          canJoin: targetIsSimple,
          canReceive: targetIsSimple,
          canBeCascaded: true);
    }
    return nullCascadableExpression;
  }

  factory _CascadableExpression._fromPrefixedIdentifier(
          PrefixedIdentifier node) =>
      _CascadableExpression._internal(node.prefix.canonicalElement, [],
          canJoin: true, canReceive: true, canBeCascaded: true);

  factory _CascadableExpression._fromPropertyAccess(PropertyAccess node) {
    var targetIsSimple = node.target is SimpleIdentifier;
    return _CascadableExpression._internal(node.target.canonicalElement, [],
        canJoin: targetIsSimple,
        canReceive: targetIsSimple,
        canBeCascaded: true);
  }

  _CascadableExpression._internal(this.element, this.criticalNodes,
      {this.canJoin = false,
      this.canReceive = false,
      this.canBeCascaded = false,
      this.isCritical = false});

  /// Whether `this` is compatible to be joined with [expressionBox] with a
  /// cascade operation.
  bool compatibleWith(_CascadableExpression expressionBox) =>
      element != null &&
      expressionBox.canReceive &&
      canJoin &&
      (canBeCascaded || expressionBox.canBeCascaded) &&
      element == expressionBox.element &&
      !_hasCriticalDependencies(expressionBox);

  bool _hasCriticalDependencies(_CascadableExpression expressionBox) {
    if (!expressionBox.isCritical) return false;

    for (var node in criticalNodes) {
      if (_NodeVisitor(expressionBox).isOrHasCriticalNode(node)) {
        return true;
      }
    }

    return false;
  }
}

class _NodeVisitor extends UnifyingAstVisitor {
  final _CascadableExpression expressionBox;

  bool foundCriticalNode = false;
  _NodeVisitor(this.expressionBox);

  bool isCriticalNode(AstNode node) =>
      node.canonicalElement == expressionBox.element;

  bool isOrHasCriticalNode(AstNode node) {
    node.accept(this);
    return foundCriticalNode;
  }

  @override
  visitNode(AstNode node) {
    if (foundCriticalNode) return;
    foundCriticalNode = isCriticalNode(node);

    if (!foundCriticalNode) {
      super.visitNode(node);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitBlock(Block node) {
    if (node.statements.length < 2) {
      return;
    }
    var previousExpressionBox = _CascadableExpression.nullCascadableExpression;
    for (var statement in node.statements) {
      var currentExpressionBox = _CascadableExpression.nullCascadableExpression;
      if (statement is VariableDeclarationStatement) {
        currentExpressionBox =
            _CascadableExpression.fromVariableDeclarationStatement(statement);
      }
      if (statement is ExpressionStatement) {
        currentExpressionBox =
            _CascadableExpression.fromExpressionStatement(statement);
      }
      if (currentExpressionBox.compatibleWith(previousExpressionBox)) {
        rule.reportLint(statement);
      }
      previousExpressionBox = currentExpressionBox;
    }
  }
}
