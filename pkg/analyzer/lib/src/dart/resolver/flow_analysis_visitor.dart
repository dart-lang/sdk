// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis.dart';

/// Perform flow analysis for the given [unit].
FlowAnalysisResult performFlowAnalysis(
  TypeSystem typeSystem,
  CompilationUnit unit,
) {
  var assignedVariables = AssignedVariables<Statement, VariableElement>();
  unit.accept(_AssignedVariablesVisitor(assignedVariables));

  var readBeforeWritten = <LocalVariableElement>[];
  var nullableNodes = <SimpleIdentifier>[];
  var nonNullableNodes = <SimpleIdentifier>[];
  var unreachableNodes = <AstNode>[];
  var functionBodiesThatDontComplete = <FunctionBody>[];
  var promotedTypes = <SimpleIdentifier, DartType>{};

  unit.accept(_FlowAnalysisVisitor(
    typeSystem,
    assignedVariables,
    promotedTypes,
    readBeforeWritten,
    nullableNodes,
    nonNullableNodes,
    unreachableNodes,
    functionBodiesThatDontComplete,
  ));

  return FlowAnalysisResult(
    readBeforeWritten,
    nullableNodes,
    nonNullableNodes,
    unreachableNodes,
    functionBodiesThatDontComplete,
    promotedTypes,
  );
}

/// The result of performing flow analysis on a unit.
class FlowAnalysisResult {
  final List<LocalVariableElement> readBeforeWritten;

  /// The list of identifiers, resolved to a local variable or a parameter,
  /// where the variable is known to be nullable.
  final List<SimpleIdentifier> nullableNodes;

  /// The list of identifiers, resolved to a local variable or a parameter,
  /// where the variable is known to be non-nullable.
  final List<SimpleIdentifier> nonNullableNodes;

  /// The list of nodes, [Expression]s or [Statement]s, that cannot be reached,
  /// for example because a previous statement always exits.
  final List<AstNode> unreachableNodes;

  /// The list of [FunctionBody]s that don't complete, for example because
  /// there is a `return` statement at the end of the function body block.
  final List<FunctionBody> functionBodiesThatDontComplete;

  /// For each local variable or parameter, which type is promoted to a type
  /// specific than its declaration type, this map included references where
  /// the variable where it is read, and the type it has.
  final Map<SimpleIdentifier, DartType> promotedTypes;

  FlowAnalysisResult(
    this.readBeforeWritten,
    this.nullableNodes,
    this.nonNullableNodes,
    this.unreachableNodes,
    this.functionBodiesThatDontComplete,
    this.promotedTypes,
  );
}

/// The visitor that gathers local variables that are potentially assigned
/// in corresponding statements, such as loops, `switch` and `try`.
class _AssignedVariablesVisitor extends RecursiveAstVisitor<void> {
  final AssignedVariables assignedVariables;

  _AssignedVariablesVisitor(this.assignedVariables);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var left = node.leftHandSide;

    super.visitAssignmentExpression(node);

    if (left is SimpleIdentifier) {
      var element = left.staticElement;
      if (element is VariableElement) {
        assignedVariables.write(element);
      }
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    assignedVariables.beginStatement();
    super.visitDoStatement(node);
    assignedVariables.endStatement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    var forLoopParts = node.forLoopParts;
    if (forLoopParts is ForParts) {
      if (forLoopParts is ForPartsWithExpression) {
        forLoopParts.initialization?.accept(this);
      } else if (forLoopParts is ForPartsWithDeclarations) {
        forLoopParts.variables?.accept(this);
      } else {
        throw new StateError('Unrecognized for loop parts');
      }

      assignedVariables.beginStatement();
      forLoopParts.condition?.accept(this);
      node.body.accept(this);
      forLoopParts.updaters?.accept(this);
      assignedVariables.endStatement(node);
    } else if (forLoopParts is ForEachParts) {
      var iterable = forLoopParts.iterable;
      var body = node.body;

      iterable.accept(this);

      assignedVariables.beginStatement();
      body.accept(this);
      assignedVariables.endStatement(node);
    } else {
      throw new StateError('Unrecognized for loop parts');
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    var expression = node.expression;
    var members = node.members;

    expression.accept(this);

    assignedVariables.beginStatement();
    members.accept(this);
    assignedVariables.endStatement(node);
  }

  @override
  void visitTryStatement(TryStatement node) {
    assignedVariables.beginStatement();
    node.body.accept(this);
    assignedVariables.endStatement(node.body);

    node.catchClauses.accept(this);

    var finallyBlock = node.finallyBlock;
    if (finallyBlock != null) {
      assignedVariables.beginStatement();
      finallyBlock.accept(this);
      assignedVariables.endStatement(finallyBlock);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    assignedVariables.beginStatement();
    super.visitWhileStatement(node);
    assignedVariables.endStatement(node);
  }
}

/// [AstVisitor] that drives the [FlowAnalysis].
class _FlowAnalysisVisitor extends GeneralizingAstVisitor<void> {
  static final trueLiteral = astFactory.booleanLiteral(null, true);

  final NodeOperations<Expression> nodeOperations;
  final TypeOperations<VariableElement, DartType> typeOperations;
  final AssignedVariables assignedVariables;

  final Map<SimpleIdentifier, DartType> promotedTypes;
  final List<LocalVariableElement> readBeforeWritten;
  final List<SimpleIdentifier> nullableNodes;
  final List<SimpleIdentifier> nonNullableNodes;
  final List<AstNode> unreachableNodes;
  final List<FunctionBody> functionBodiesThatDontComplete;

  FlowAnalysis<Statement, Expression, VariableElement, DartType> flow;

  _FlowAnalysisVisitor(
      TypeSystem typeSystem,
      this.assignedVariables,
      this.promotedTypes,
      this.readBeforeWritten,
      this.nullableNodes,
      this.nonNullableNodes,
      this.unreachableNodes,
      this.functionBodiesThatDontComplete)
      : nodeOperations = _NodeOperations(),
        typeOperations = _TypeSystemTypeOperations(typeSystem);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (flow == null) {
      return super.visitAssignmentExpression(node);
    }

    var left = node.leftHandSide;
    var right = node.rightHandSide;

    VariableElement localElement;
    if (left is SimpleIdentifier) {
      var element = left.staticElement;
      if (element is VariableElement) {
        localElement = element;
      }
    }

    if (localElement != null) {
      var isCompound = node.operator.type != TokenType.EQ;
      if (isCompound) {
        flow.read(localElement);
      }
      right.accept(this);
      flow.write(
        localElement,
        isNull: _isNull(right),
        isNonNull: _isNonNull(right),
      );
    } else {
      left.accept(this);
      right.accept(this);
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (flow == null) {
      return super.visitBinaryExpression(node);
    }

    var left = node.leftOperand;
    var right = node.rightOperand;

    var operator = node.operator.type;

    if (operator == TokenType.AMPERSAND_AMPERSAND) {
      left.accept(this);

      flow.logicalAnd_rightBegin(node, node.leftOperand);
      _checkUnreachableNode(node.rightOperand);
      right.accept(this);

      flow.logicalAnd_end(node, node.rightOperand);
    } else if (operator == TokenType.BAR_BAR) {
      left.accept(this);

      flow.logicalOr_rightBegin(node, node.leftOperand);
      _checkUnreachableNode(node.rightOperand);
      right.accept(this);

      flow.logicalOr_end(node, node.rightOperand);
    } else if (operator == TokenType.BANG_EQ) {
      left.accept(this);
      right.accept(this);
      if (right is NullLiteral) {
        if (left is SimpleIdentifier) {
          var element = left.staticElement;
          if (element is VariableElement) {
            flow.conditionNotEqNull(node, element);
          }
        }
      } else if (left is NullLiteral) {
        if (right is SimpleIdentifier) {
          var element = right.staticElement;
          if (element is VariableElement) {
            flow.conditionNotEqNull(node, element);
          }
        }
      }
    } else if (operator == TokenType.EQ_EQ) {
      left.accept(this);
      right.accept(this);
      if (right is NullLiteral) {
        if (left is SimpleIdentifier) {
          var element = left.staticElement;
          if (element is VariableElement) {
            flow.conditionEqNull(node, element);
          }
        }
      } else if (left is NullLiteral) {
        if (right is SimpleIdentifier) {
          var element = right.staticElement;
          if (element is VariableElement) {
            flow.conditionEqNull(node, element);
          }
        }
      }
    } else if (operator == TokenType.QUESTION_QUESTION) {
      left.accept(this);

      flow.ifNullExpression_rightBegin();
      right.accept(this);

      flow.ifNullExpression_end();
    } else {
      left.accept(this);
      right.accept(this);
    }
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    if (flow != null) {
      super.visitBlockFunctionBody(node);
    } else {
      flow = FlowAnalysis<Statement, Expression, VariableElement, DartType>(
        nodeOperations,
        typeOperations,
        _FunctionBodyAccess(node),
      );

      var parameters = _enclosingExecutableParameters(node);
      if (parameters != null) {
        for (var parameter in parameters.parameters) {
          flow.add(parameter.declaredElement, assigned: true);
        }
      }

      super.visitBlockFunctionBody(node);

      for (var variable in flow.readBeforeWritten) {
        assert(variable is LocalVariableElement);
        readBeforeWritten.add(variable);
      }

      if (!flow.isReachable) {
        functionBodiesThatDontComplete.add(node);
      }

      flow.verifyStackEmpty();
      flow = null;
    }
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    if (flow == null) {
      return super.visitBooleanLiteral(node);
    }

    flow.booleanLiteral(node, node.value);
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    super.visitBreakStatement(node);
    var target = _getLabelTarget(node, node.label?.staticElement);
    flow.handleBreak(target);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (flow == null) {
      return super.visitConditionalExpression(node);
    }

    var condition = node.condition;
    var thenExpression = node.thenExpression;
    var elseExpression = node.elseExpression;

    condition.accept(this);

    flow.conditional_thenBegin(node, node.condition);
    _checkUnreachableNode(node.thenExpression);
    thenExpression.accept(this);
    var isBool = thenExpression.staticType.isDartCoreBool;

    flow.conditional_elseBegin(node, node.thenExpression, isBool);
    _checkUnreachableNode(node.elseExpression);
    elseExpression.accept(this);

    flow.conditional_end(node, node.elseExpression, isBool);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    super.visitContinueStatement(node);
    var target = _getLabelTarget(node, node.label?.staticElement);
    flow.handleContinue(target);
  }

  @override
  void visitDoStatement(DoStatement node) {
    _checkUnreachableNode(node);

    var body = node.body;
    var condition = node.condition;

    flow.doStatement_bodyBegin(node, assignedVariables[node]);
    body.accept(this);

    flow.doStatement_conditionBegin();
    condition.accept(this);

    flow.doStatement_end(node, node.condition);
  }

  @override
  void visitForStatement(ForStatement node) {
    _checkUnreachableNode(node);

    ForLoopParts parts = node.forLoopParts;
    if (parts is ForEachParts) {
      parts.iterable?.accept(this);

      flow.forEachStatement_bodyBegin(assignedVariables[node]);

      node.body.accept(this);

      flow.forEachStatement_end();
      return;
    }
    VariableDeclarationList variables;
    Expression initialization;
    Expression condition;
    NodeList<Expression> updaters;
    if (parts is ForPartsWithDeclarations) {
      variables = parts.variables;
      condition = parts.condition;
      updaters = parts.updaters;
    } else if (parts is ForPartsWithExpression) {
      initialization = parts.initialization;
      condition = parts.condition;
      updaters = parts.updaters;
    }
    initialization?.accept(this);
    variables?.accept(this);

    flow.forStatement_conditionBegin(assignedVariables[node]);
    if (condition != null) {
      condition.accept(this);
    } else {
      flow.booleanLiteral(trueLiteral, true);
    }

    flow.forStatement_bodyBegin(node, condition ?? trueLiteral);
    node.body.accept(this);

    flow.forStatement_updaterBegin();
    updaters?.accept(this);

    flow.forStatement_end();
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (flow == null) {
      return super.visitFunctionExpression(node);
    }

    flow.functionExpression_begin();
    super.visitFunctionExpression(node);
    flow.functionExpression_end();
  }

  @override
  void visitIfStatement(IfStatement node) {
    _checkUnreachableNode(node);

    var condition = node.condition;
    var thenStatement = node.thenStatement;
    var elseStatement = node.elseStatement;

    condition.accept(this);

    flow.ifStatement_thenBegin(node, node.condition);
    thenStatement.accept(this);

    if (elseStatement != null) {
      flow.ifStatement_elseBegin();
      elseStatement.accept(this);
    }

    flow.ifStatement_end(elseStatement != null);
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (flow == null) {
      return super.visitIsExpression(node);
    }

    super.visitIsExpression(node);
    var expression = node.expression;
    var typeAnnotation = node.type;

    if (expression is SimpleIdentifier) {
      var element = expression.staticElement;
      if (element is VariableElement) {
        flow.isExpression_end(
          node,
          element,
          node.notOperator != null,
          typeAnnotation.type,
        );
      }
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (flow == null) {
      return super.visitPrefixExpression(node);
    }

    var operand = node.operand;

    var operator = node.operator.type;
    if (operator == TokenType.BANG) {
      operand.accept(this);
      flow.logicalNot_end(node, node.operand);
    } else {
      operand.accept(this);
    }
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    if (flow == null) {
      return super.visitRethrowExpression(node);
    }

    super.visitRethrowExpression(node);
    flow.handleExit();
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    super.visitReturnStatement(node);
    flow.handleExit();
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (flow == null) {
      return super.visitSimpleIdentifier(node);
    }

    var element = node.staticElement;
    var isLocalVariable = element is LocalVariableElement;
    if (isLocalVariable || element is ParameterElement) {
      if (node.inGetterContext() && !node.inDeclarationContext()) {
        if (isLocalVariable) {
          flow.read(element);
        }

        if (flow.isNullable(element)) {
          nullableNodes?.add(node);
        }

        if (flow.isNonNullable(element)) {
          nonNullableNodes?.add(node);
        }

        var promotedType = flow.promotedType(element);
        if (promotedType != null) {
          promotedTypes[node] = promotedType;
        }
      }
    }
  }

  @override
  void visitStatement(Statement node) {
    _checkUnreachableNode(node);
    super.visitStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _checkUnreachableNode(node);

    node.expression.accept(this);
    flow.switchStatement_expressionEnd(node);

    var assignedInCases = assignedVariables[node];

    var members = node.members;
    var membersLength = members.length;
    var hasDefault = false;
    for (var i = 0; i < membersLength; i++) {
      var member = members[i];

      flow.switchStatement_beginCase(
        member.labels.isNotEmpty ? assignedInCases : assignedVariables.emptySet,
      );
      member.accept(this);

      // Implicit `break` at the end of `default`.
      if (member is SwitchDefault) {
        hasDefault = true;
        flow.handleBreak(node);
      }
    }

    flow.switchStatement_end(node, hasDefault);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    if (flow == null) {
      return super.visitThrowExpression(node);
    }

    super.visitThrowExpression(node);
    flow.handleExit();
  }

  @override
  void visitTryStatement(TryStatement node) {
    _checkUnreachableNode(node);

    var body = node.body;
    var catchClauses = node.catchClauses;
    var finallyBlock = node.finallyBlock;

    if (finallyBlock != null) {
      flow.tryFinallyStatement_bodyBegin();
    }

    flow.tryCatchStatement_bodyBegin();
    body.accept(this);
    flow.tryCatchStatement_bodyEnd(assignedVariables[body]);

    var catchLength = catchClauses.length;
    for (var i = 0; i < catchLength; ++i) {
      var catchClause = catchClauses[i];
      flow.tryCatchStatement_catchBegin();
      catchClause.accept(this);
      flow.tryCatchStatement_catchEnd();
    }

    flow.tryCatchStatement_end();

    if (finallyBlock != null) {
      flow.tryFinallyStatement_finallyBegin(assignedVariables[body]);
      finallyBlock.accept(this);
      flow.tryFinallyStatement_end(assignedVariables[finallyBlock]);
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    var variables = node.variables.variables;
    for (var i = 0; i < variables.length; ++i) {
      var variable = variables[i];
      flow.add(variable.declaredElement,
          assigned: variable.initializer != null);
    }

    super.visitVariableDeclarationStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _checkUnreachableNode(node);

    var condition = node.condition;
    var body = node.body;

    flow.whileStatement_conditionBegin(assignedVariables[node]);
    condition.accept(this);

    flow.whileStatement_bodyBegin(node, node.condition);
    body.accept(this);

    flow.whileStatement_end();
  }

  /// Mark the [node] as unreachable if it is not covered by another node that
  /// is already known to be unreachable.
  void _checkUnreachableNode(AstNode node) {
    if (flow.isReachable) return;

    // Ignore the [node] if it is fully covered by the last unreachable.
    if (unreachableNodes.isNotEmpty) {
      var last = unreachableNodes.last;
      if (node.offset >= last.offset && node.end <= last.end) return;
    }

    unreachableNodes.add(node);
  }

  FormalParameterList _enclosingExecutableParameters(FunctionBody node) {
    var parent = node.parent;
    if (parent is ConstructorDeclaration) {
      return parent.parameters;
    }
    if (parent is FunctionExpression) {
      return parent.parameters;
    }
    if (parent is MethodDeclaration) {
      return parent.parameters;
    }
    return null;
  }

  /// Return the target of the `break` or `continue` statement with the
  /// [element] label. The [element] might be `null` (when the statement does
  /// not specify a label), so the default enclosing target is returned.
  AstNode _getLabelTarget(AstNode node, LabelElement element) {
    for (; node != null; node = node.parent) {
      if (node is DoStatement ||
          node is ForStatement ||
          node is SwitchStatement ||
          node is WhileStatement) {
        if (element == null) {
          return node;
        }
        var parent = node.parent;
        if (parent is LabeledStatement) {
          for (var nodeLabel in parent.labels) {
            if (identical(nodeLabel.label.staticElement, element)) {
              return node;
            }
          }
        }
      }
      if (element != null && node is SwitchStatement) {
        for (var member in node.members) {
          for (var nodeLabel in member.labels) {
            if (identical(nodeLabel.label.staticElement, element)) {
              return node;
            }
          }
        }
      }
    }
    return null;
  }

  static bool _isNonNull(Expression node) {
    if (node is NullLiteral) return false;

    return node is Literal;
  }

  static bool _isNull(Expression node) {
    return node is NullLiteral;
  }
}

class _FunctionBodyAccess implements FunctionBodyAccess<VariableElement> {
  final FunctionBody node;

  _FunctionBodyAccess(this.node);

  @override
  bool isPotentiallyMutatedInClosure(VariableElement variable) {
    return node.isPotentiallyMutatedInClosure(variable);
  }

  @override
  bool isPotentiallyMutatedInScope(VariableElement variable) {
    return node.isPotentiallyMutatedInScope(variable);
  }
}

class _NodeOperations implements NodeOperations<Expression> {
  @override
  Expression unwrapParenthesized(Expression node) {
    return node.unParenthesized;
  }
}

class _TypeSystemTypeOperations
    implements TypeOperations<VariableElement, DartType> {
  final TypeSystem typeSystem;

  _TypeSystemTypeOperations(this.typeSystem);

  @override
  DartType elementType(VariableElement element) {
    return element.type;
  }

  @override
  bool isLocalVariable(VariableElement element) {
    return element is LocalVariableElement;
  }

  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return typeSystem.isSubtypeOf(leftType, rightType);
  }
}
