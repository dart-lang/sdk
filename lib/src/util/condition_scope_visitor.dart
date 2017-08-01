import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/generated/resolver.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

Element _getLeftElement(AssignmentExpression assignment) => DartTypeUtilities
    .getCanonicalElementFromIdentifier(assignment.leftHandSide);

List<Expression> _splitConjunctions(Expression rawExpression) {
  final expression = rawExpression?.unParenthesized;
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
  final environment = <_ExpressionBox>[];
  final ConditionScope outer;

  ConditionScope(this.outer);

  void add(_ExpressionBox e) {
    if (e != null) {
      environment.add(e);
    }
  }

  void addAll(Iterable<_ExpressionBox> expressions) {
    environment.addAll(expressions);
  }

  Iterable<Expression> getExpressions(Iterable<Element> elements,
      {bool value}) {
    final expressions = <Expression>[];
    _recursiveGetExpressions(expressions, elements, value);
    return expressions;
  }

  Iterable<_ExpressionBox> getUndefinedExpressions() =>
      environment.where((e) => e is _UndefinedExpression);

  void _recursiveGetExpressions(
      List<Expression> expressions, Iterable<Element> elements, bool value) {
    for (final element in environment.reversed) {
      if (element.haveToStop(elements)) {
        return;
      }
      if (element is _ConditionExpression && element.value == value) {
        expressions.add(element.expression);
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
/// - Visiting loop statements: [DoStatement] [WhileStatement] [ForStatement] [ForEachStatement].
///
/// When call the abstract method visitCondition(node.condition):
/// - After visiting a conditional statements: [IfStatement] [DoStatement] [WhileStatement] [ForStatement].
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
/// - After visiting loop statements: [DoStatement] [WhileStatement] [ForStatement] [ForEachStatement].
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
  ConditionScope outerScope;
  final breakScope = new BreakScope();

  Iterable<Expression> getFalseExpressions(Iterable<Element> elements) =>
      _getExpressions(elements, value: false);

  Iterable<Expression> getTrueExpressions(Iterable<Element> elements) =>
      _getExpressions(elements);

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    _addElementToEnvironment(new _UndefinedExpression(_getLeftElement(node)));
    node.visitChildren(this);
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    _addScope();
    _addElementToEnvironment(new _UndefinedAllExpression());
    node.visitChildren(this);
    _removeLastScope();
  }

  @override
  visitBreakStatement(BreakStatement node) {
    breakScope.add(node);
    node.visitChildren(this);
  }

  void visitCondition(Expression node);

  @override
  visitDoStatement(DoStatement node) {
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
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _addScope();
    _addElementToEnvironment(new _UndefinedAllExpression());
    node.visitChildren(this);
    _removeLastScope();
  }

  @override
  visitForEachStatement(ForEachStatement node) {
    _addScope();
    node.visitChildren(this);
    _propagateUndefinedExpressions(_removeLastScope());
  }

  @override
  visitForStatement(ForStatement node) {
    _addScope();
    _addTrueCondition(node.condition);
    node.variables?.accept(this);
    node.initialization?.accept(this);
    visitCondition(node.condition);
    node.condition?.accept(this);
    _addTrueCondition(node.condition);
    node.updaters.accept(this);
    node.body?.accept(this);
    _propagateUndefinedExpressions(_removeLastScope());
    // If a for statement do not have breaks inside, that means the condition
    // after the loop is false.
    if (!breakScope.hasBreak(node)) {
      _addFalseCondition(node.condition);
    }
    breakScope.deleteBreaksWithTarget(node);
  }

  @override
  visitIfStatement(IfStatement node) {
    final elseScope = _visitElseStatement(node.elseStatement, node.condition);
    _visitIfStatement(node);
    _propagateUndefinedExpressions(elseScope);
    final addFalseCondition =
        _isLastStatementAnExitStatement(node.thenStatement);
    final addTrueCondition =
        _isLastStatementAnExitStatement(node.elseStatement);
    // If addTrueCondition and addFalseCondition are true at the same time,
    // then the rest of the block is dead code.
    if (addTrueCondition && addFalseCondition) {
      _addElementToEnvironment(new _UndefinedAllExpression());
      return;
    }
    if (addFalseCondition) {
      _addFalseCondition(node.condition);
    }
    if (addTrueCondition) {
      _addTrueCondition(node.condition);
    }
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    final operand = node.operand;
    if (operand is SimpleIdentifier) {
      _addElementToEnvironment(new _UndefinedExpression(operand.bestElement));
    }
    node.visitChildren(this);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    final operand = node.operand;
    if (operand is SimpleIdentifier) {
      _addElementToEnvironment(new _UndefinedExpression(operand.bestElement));
    }
    node.visitChildren(this);
  }

  @override
  visitRethrowExpression(RethrowExpression node) {
    node.visitChildren(this);
    _addElementToEnvironment(new _UndefinedAllExpression());
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    node.visitChildren(this);
    _addElementToEnvironment(new _UndefinedAllExpression());
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    node.visitChildren(this);
    _addElementToEnvironment(new _UndefinedAllExpression());
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    _addElementToEnvironment(new _UndefinedExpression(node.element));
    node.visitChildren(this);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    _addScope();
    visitCondition(node.condition);
    node.condition?.accept(this);
    _addTrueCondition(node.condition);
    node.body?.accept(this);
    _propagateUndefinedExpressions(_removeLastScope());
    // If a while statement do not have breaks inside, that means the condition
    // after the loop is false.
    if (!breakScope.hasBreak(node)) {
      _addFalseCondition(node.condition);
    }
    breakScope.deleteBreaksWithTarget(node);
  }

  void _addElementToEnvironment(_ExpressionBox e) {
    outerScope?.add(e);
  }

  void _addFalseCondition(Expression expression) {
    _addElementToEnvironment(
        new _ConditionExpression(expression, value: false));
  }

  void _addScope() {
    outerScope = new ConditionScope(outerScope);
  }

  void _addTrueCondition(Expression expression) {
    _splitConjunctions(expression).forEach((e) {
      _addElementToEnvironment(new _ConditionExpression(e));
    });
  }

  Iterable<Expression> _getExpressions(Iterable<Element> elements,
          {bool value: true}) =>
      outerScope.getExpressions(elements, value: value);

  bool _isLastStatementAnExitStatement(Statement statement) {
    if (statement is Block) {
      return _isLastStatementAnExitStatement(
          DartTypeUtilities.getLastStatementInBlock(statement));
    } else {
      if (statement is BreakStatement) {
        return statement.label == null;
      } else if (statement is ContinueStatement) {
        return statement.label == null;
      } else if (statement is ReturnStatement) {
        return true;
      }
      return ExitDetector.exits(statement);
    }
  }

  void _propagateUndefinedExpressions(ConditionScope scope) {
    outerScope?.addAll(scope.getUndefinedExpressions());
  }

  ConditionScope _removeLastScope() {
    final deletedScope = outerScope;
    outerScope = outerScope.outer;
    return deletedScope;
  }

  ConditionScope _visitElseStatement(
      Statement elseStatement, Expression condition) {
    _addScope();
    _addFalseCondition(condition);
    elseStatement?.accept(this);
    return _removeLastScope();
  }

  _visitIfStatement(IfStatement node) {
    _addScope();
    node.condition?.accept(this);
    visitCondition(node.condition);
    _addTrueCondition(node.condition);
    node.thenStatement?.accept(this);
    _propagateUndefinedExpressions(_removeLastScope());
  }
}

class _ConditionExpression extends _ExpressionBox {
  Expression expression;
  bool value;

  _ConditionExpression(this.expression, {this.value: true});

  @override
  bool haveToStop(Iterable<Element> elements) => false;

  @override
  String toString() => '$expression is $value';
}

abstract class _ExpressionBox {
  bool haveToStop(Iterable<Element> elements);
}

class _UndefinedAllExpression extends _ExpressionBox {
  @override
  bool haveToStop(Iterable<Element> elements) => true;

  @override
  String toString() => '*All* got undefined';
}

class _UndefinedExpression extends _ExpressionBox {
  Element element;

  factory _UndefinedExpression(Element element) {
    final canonicalElement = DartTypeUtilities.getCanonicalElement(element);
    if (canonicalElement == null) return null;
    return new _UndefinedExpression._internal(canonicalElement);
  }

  _UndefinedExpression._internal(this.element);

  @override
  bool haveToStop(Iterable<Element> elements) => elements.contains(element);

  @override
  String toString() => '$element got undefined';
}
