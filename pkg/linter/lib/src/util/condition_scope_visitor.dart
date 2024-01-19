// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';

Element? _getLeftElement(AssignmentExpression assignment) =>
    assignment.writeElement?.canonicalElement;

List<Expression?> _splitConjunctions(Expression? rawExpression) {
  var expression = rawExpression?.unParenthesized;
  if (expression is BinaryExpression &&
      expression.operator.type == TokenType.AMPERSAND_AMPERSAND) {
    return _splitConjunctions(expression.leftOperand)
      ..addAll(_splitConjunctions(expression.rightOperand));
  }
  return [expression];
}

class BreakScope {
  var environment = <BreakStatement>[];

  void add(BreakStatement element) {
    if (element.target != null) {
      environment.add(element);
    }
  }

  void deleteBreaksWithTarget(AstNode node) {
    environment = environment.where((e) => e.target != node).toList();
  }

  bool hasBreak(AstNode node) => environment.any((e) => e.target == node);
}

class ConditionScope {
  final environment = <ExpressionBox>[];
  final ConditionScope? outer;

  ConditionScope(this.outer);

  void add(ExpressionBox e) {
    environment.add(e);
  }

  void addAll(Iterable<ExpressionBox> expressions) {
    environment.addAll(expressions);
  }

  Iterable<Expression> getExpressions(Iterable<Element?> elements,
      {bool? value}) {
    var expressions = <Expression>[];
    _recursiveGetExpressions(expressions, elements, value);
    return expressions;
  }

  Iterable<ExpressionBox> getUndefinedExpressions() =>
      environment.whereType<_UndefinedExpression>();

  void _recursiveGetExpressions(
      List<Expression> expressions, Iterable<Element?> elements, bool? value) {
    for (var element in environment.reversed) {
      if (element.haveToStop(elements)) {
        return;
      }
      if (element is _ConditionExpression && element.value == value) {
        var expression = element.expression;
        if (expression != null) {
          expressions.add(expression);
        }
      }
    }
    outer?._recursiveGetExpressions(expressions, elements, value);
  }
}

/// An AST visitor that keeps the conditions that are currently evaluated
/// to true or false.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or must explicitly ask the visited node to visit its children.
/// Failure to do so will cause the children of the visited node to not be
/// visited.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method and keep the scopes behavior consistent to its changes.
///
/// When add a new local scope:
/// - Visiting a non-empty function body: [BlockFunctionBody] [ExpressionFunctionBody].
/// - Visiting a flow-control statement: [IfStatement] ElseStatement.
/// - Visiting loop statements: [DoStatement] [WhileStatement] [ForStatement].
///
/// When call the abstract method visitCondition(node.condition):
/// - After visiting a conditional statements: [IfStatement] [DoStatement] [WhileStatement].
///
/// When undefine an element:
/// - Visiting reassignments of variables: [AssignmentExpression] [PrefixExpression] [PostfixExpression].
///
/// When undefine all elements:
/// - Visiting a non-empty function body: [BlockFunctionBody] [ExpressionFunctionBody].
/// - Visiting clauses that generates dead_code: [ReturnStatement] [ThrowExpression] [RethrowExpression].
/// - Visiting if/else with exit clauses inside in both cases (also generates dead code).
///
/// When propagate undefined elements:
/// - After visiting a flow-control statement: [IfStatement] ElseStatement.
/// - After visiting loop statements: [DoStatement] [WhileStatement] [ForStatement].
///
/// When add a Condition as true condition:
/// - Inside an if body and after an else body with exit clause.
/// - Inside pre evaluated conditional loops: [ForStatement] [WhileStatement]
///
/// When add a Condition as false condition:
/// - Inside an else body and after a then body with exit clause.
/// - Outside pre evaluated conditional loops without breaks: [ForStatement] [WhileStatement]
///
/// When add a BreakStatement in the breakScope.
/// - When visiting a BreakStatement.
///
/// When remove a BreakStatement in the breakScope.
/// - After visiting the target of the BreakStatement.
///
/// Clients may extend this class.
abstract class ConditionScopeVisitor extends RecursiveAstVisitor {
  ConditionScope? outerScope;
  final breakScope = BreakScope();

  // TODO(pq): here and w/ getTrueExpressions, consider an empty iterable
  Iterable<Expression>? getFalseExpressions(Iterable<Element?> elements) =>
      _getExpressions(elements, value: false);

  Iterable<Expression>? getTrueExpressions(Iterable<Element?> elements) =>
      _getExpressions(elements);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _addElementToEnvironment(
        _UndefinedExpression.forElement(_getLeftElement(node)));
    node.visitChildren(this);
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    _addScope();
    _addElementToEnvironment(_UndefinedAllExpression());
    node.visitChildren(this);
    _removeLastScope();
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    breakScope.add(node);
    node.visitChildren(this);
  }

  void visitCondition(Expression? node);

  @override
  void visitDoStatement(DoStatement node) {
    _addScope();
    visitCondition(node.condition);
    node.visitChildren(this);
    _propagateUndefinedExpressions(_removeLastScope());
    // If a do statement do not have breaks inside, that means the condition
    // after the loop is false.
    if (!breakScope.hasBreak(node)) {
      _addFalseCondition(node.condition);
    }
    breakScope.deleteBreaksWithTarget(node);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _addScope();
    _addElementToEnvironment(_UndefinedAllExpression());
    node.visitChildren(this);
    _removeLastScope();
  }

  @override
  void visitForStatement(ForStatement node) {
    _addScope();
    var loopParts = node.forLoopParts;
    if (loopParts is ForParts) {
      _addTrueCondition(loopParts.condition);

      if (loopParts is ForPartsWithDeclarations) {
        loopParts.variables.accept(this);
      } else if (loopParts is ForPartsWithExpression) {
        loopParts.initialization?.accept(this);
      }

      visitCondition(loopParts.condition);
      loopParts.condition?.accept(this);
      _addTrueCondition(loopParts.condition);
      loopParts.updaters.accept(this);
      node.body.accept(this);
      _propagateUndefinedExpressions(_removeLastScope());
      if (_isRelevantOutsideOfForStatement(node)) {
        _addFalseCondition(loopParts.condition);
      }
      breakScope.deleteBreaksWithTarget(node);
    } else if (loopParts is ForEachParts) {
      node.visitChildren(this);
      _propagateUndefinedExpressions(_removeLastScope());
    } else {
      throw StateError('unsupported loop parts type');
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    var elseScope = _visitElseStatement(node.elseStatement, node.expression);
    _visitIfStatement(node);
    if (elseScope != null) {
      _propagateUndefinedExpressions(elseScope);
    }
    var addFalseCondition = _isLastStatementAnExitStatement(node.thenStatement);
    var addTrueCondition = _isLastStatementAnExitStatement(node.elseStatement);
    // If addTrueCondition and addFalseCondition are true at the same time,
    // then the rest of the block is dead code.
    if (addTrueCondition && addFalseCondition) {
      _addElementToEnvironment(_UndefinedAllExpression());
      return;
    }
    if (addFalseCondition) {
      _addFalseCondition(node.expression);
    }
    if (addTrueCondition) {
      _addTrueCondition(node.expression);
    }
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    var operand = node.operand;
    if (operand is SimpleIdentifier) {
      _addElementToEnvironment(
          _UndefinedExpression.forElement(operand.staticElement));
    }
    node.visitChildren(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var operand = node.operand;
    if (operand is SimpleIdentifier) {
      _addElementToEnvironment(
          _UndefinedExpression.forElement(operand.staticElement));
    }
    node.visitChildren(this);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    node.visitChildren(this);
    _addElementToEnvironment(_UndefinedAllExpression());
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    node.visitChildren(this);
    _addElementToEnvironment(_UndefinedAllExpression());
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    node.visitChildren(this);
    _addElementToEnvironment(_UndefinedAllExpression());
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _addElementToEnvironment(
        _UndefinedExpression.forElement(node.declaredElement));
    node.visitChildren(this);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _addScope();
    visitCondition(node.condition);
    node.condition.accept(this);
    _addTrueCondition(node.condition);
    node.body.accept(this);
    _propagateUndefinedExpressions(_removeLastScope());
    // If a while statement do not have breaks inside, that means the condition
    // after the loop is false.
    if (!breakScope.hasBreak(node)) {
      _addFalseCondition(node.condition);
    }
    breakScope.deleteBreaksWithTarget(node);
  }

  void _addElementToEnvironment(ExpressionBox? e) {
    if (e != null) {
      outerScope?.add(e);
    }
  }

  void _addFalseCondition(Expression? expression) {
    _addElementToEnvironment(_ConditionExpression(expression, value: false));
  }

  void _addScope() {
    outerScope = ConditionScope(outerScope);
  }

  void _addTrueCondition(Expression? expression) {
    _splitConjunctions(expression).forEach((e) {
      _addElementToEnvironment(_ConditionExpression(e));
    });
  }

  Iterable<Expression>? _getExpressions(Iterable<Element?> elements,
          {bool value = true}) =>
      outerScope?.getExpressions(elements, value: value);

  bool _isLastStatementAnExitStatement(Statement? statement) {
    if (statement is Block) {
      return _isLastStatementAnExitStatement(statement.lastStatement);
    } else {
      if (statement is BreakStatement) {
        return statement.label == null;
      } else if (statement is ContinueStatement) {
        return statement.label == null;
      } else if (statement is ReturnStatement) {
        return true;
      }
      return statement != null && ExitDetector.exits(statement);
    }
  }

  /// If any of the variables is declared inside the for statement then it does
  /// not mean anything afterwards.
  bool _isRelevantOutsideOfForStatement(ForStatement node) {
    if (breakScope.hasBreak(node)) {
      return false;
    }

    var loopParts = node.forLoopParts;
    if (loopParts is ForParts) {
      var condition = loopParts.condition;
      if (condition == null) {
        return false;
      }

      // TODO(pq): migrate away from `traverseNodesInDFS` (https://github.com/dart-lang/linter/issues/3745)
      // ignore: deprecated_member_use_from_same_package
      for (var ref in condition.traverseNodesInDFS()) {
        if (ref is SimpleIdentifier) {
          var element = ref.staticElement;
          if (element == null) {
            return false;
          }
          var refOffset = element.nameOffset;
          if (refOffset > node.offset && refOffset < node.end) {
            return false;
          }
        }
      }
    }

    return true;
  }

  void _propagateUndefinedExpressions(ConditionScope? scope) {
    if (scope != null) {
      outerScope?.addAll(scope.getUndefinedExpressions());
    }
  }

  ConditionScope? _removeLastScope() {
    var deletedScope = outerScope;
    outerScope = outerScope?.outer;
    return deletedScope;
  }

  ConditionScope? _visitElseStatement(
      Statement? elseStatement, Expression condition) {
    _addScope();
    _addFalseCondition(condition);
    elseStatement?.accept(this);
    return _removeLastScope();
  }

  void _visitIfStatement(IfStatement node) {
    _addScope();
    node.expression.accept(this);
    visitCondition(node.expression);
    _addTrueCondition(node.expression);
    node.thenStatement.accept(this);
    _propagateUndefinedExpressions(_removeLastScope());
  }
}

abstract class ExpressionBox {
  bool haveToStop(Iterable<Element?> elements);
}

class _ConditionExpression extends ExpressionBox {
  final Expression? expression;
  final bool value;

  _ConditionExpression(this.expression, {this.value = true});

  @override
  bool haveToStop(Iterable<Element?> elements) => false;

  @override
  String toString() => '$expression is $value';
}

class _UndefinedAllExpression extends ExpressionBox {
  @override
  bool haveToStop(Iterable<Element?> elements) => true;

  @override
  String toString() => '*All* got undefined';
}

class _UndefinedExpression extends ExpressionBox {
  final Element element;

  _UndefinedExpression._internal(this.element);

  @override
  bool haveToStop(Iterable<Element?> elements) => elements.contains(element);

  @override
  String toString() => '$element got undefined';

  static _UndefinedExpression? forElement(Element? element) {
    var canonicalElement = element?.canonicalElement;
    if (canonicalElement == null) return null;
    return _UndefinedExpression._internal(canonicalElement);
  }
}
