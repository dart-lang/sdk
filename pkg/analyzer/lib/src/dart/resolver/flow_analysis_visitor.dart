// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis.dart';
import 'package:analyzer/src/generated/variable_type_provider.dart';

/// The helper for performing flow analysis during resolution.
///
/// It contains related precomputed data, result, and non-trivial pieces of
/// code that are independent from visiting AST during resolution, so can
/// be extracted.
class FlowAnalysisHelper {
  static final _trueLiteral = astFactory.booleanLiteral(null, true);

  /// The reused instance for creating new [FlowAnalysis] instances.
  final NodeOperations<Expression> _nodeOperations;

  /// The reused instance for creating new [FlowAnalysis] instances.
  final _TypeSystemTypeOperations _typeOperations;

  /// Precomputed sets of potentially assigned variables.
  final AssignedVariables<Statement, VariableElement> assignedVariables;

  /// The result for post-resolution stages of analysis.
  final FlowAnalysisResult result = FlowAnalysisResult();

  /// The current flow, when resolving a function body, or `null` otherwise.
  FlowAnalysis<Statement, Expression, VariableElement, DartType> flow;

  int _blockFunctionBodyLevel = 0;

  factory FlowAnalysisHelper(TypeSystem typeSystem, AstNode node) {
    var assignedVariables = AssignedVariables<Statement, VariableElement>();
    node.accept(_AssignedVariablesVisitor(assignedVariables));

    return FlowAnalysisHelper._(
      _NodeOperations(),
      _TypeSystemTypeOperations(typeSystem),
      assignedVariables,
    );
  }

  FlowAnalysisHelper._(
    this._nodeOperations,
    this._typeOperations,
    this.assignedVariables,
  );

  LocalVariableTypeProvider get localVariableTypeProvider {
    return _LocalVariableTypeProvider(this);
  }

  VariableElement assignmentExpression(AssignmentExpression node) {
    if (flow == null) return null;

    var left = node.leftHandSide;

    if (left is SimpleIdentifier) {
      var element = left.staticElement;
      if (element is VariableElement) {
        return element;
      }
    }

    return null;
  }

  void assignmentExpression_afterRight(
      VariableElement localElement, Expression right) {
    if (localElement == null) return;

    flow.write(localElement);
  }

  void binaryExpression_bangEq(
    BinaryExpression node,
    Expression left,
    Expression right,
  ) {
    if (flow == null) return;

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
  }

  void binaryExpression_eqEq(
    BinaryExpression node,
    Expression left,
    Expression right,
  ) {
    if (flow == null) return;

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
  }

  void blockFunctionBody_enter(BlockFunctionBody node) {
    _blockFunctionBodyLevel++;

    if (_blockFunctionBodyLevel > 1) {
      assert(flow != null);
      return;
    }

    flow = FlowAnalysis<Statement, Expression, VariableElement, DartType>(
      _nodeOperations,
      _typeOperations,
      _FunctionBodyAccess(node),
    );

    var parameters = _enclosingExecutableParameters(node);
    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        flow.add(parameter.declaredElement, assigned: true);
      }
    }
  }

  void blockFunctionBody_exit(BlockFunctionBody node) {
    _blockFunctionBodyLevel--;

    if (_blockFunctionBodyLevel > 0) {
      return;
    }

    if (!flow.isReachable) {
      result.functionBodiesThatDontComplete.add(node);
    }

    flow.verifyStackEmpty();
    flow = null;
  }

  void breakStatement(BreakStatement node) {
    var target = _getLabelTarget(node, node.label?.staticElement);
    flow.handleBreak(target);
  }

  /// Mark the [node] as unreachable if it is not covered by another node that
  /// is already known to be unreachable.
  void checkUnreachableNode(AstNode node) {
    if (flow == null) return;
    if (flow.isReachable) return;

    // Ignore the [node] if it is fully covered by the last unreachable.
    if (result.unreachableNodes.isNotEmpty) {
      var last = result.unreachableNodes.last;
      if (node.offset >= last.offset && node.end <= last.end) return;
    }

    result.unreachableNodes.add(node);
  }

  void continueStatement(ContinueStatement node) {
    var target = _getLabelTarget(node, node.label?.staticElement);
    flow.handleContinue(target);
  }

  void forStatement_bodyBegin(ForStatement node, Expression condition) {
    flow.forStatement_bodyBegin(node, condition ?? _trueLiteral);
  }

  void forStatement_conditionBegin(ForStatement node, Expression condition) {
    if (condition != null) {
      var assigned = assignedVariables[node];
      flow.forStatement_conditionBegin(assigned);
    } else {
      flow.booleanLiteral(_trueLiteral, true);
    }
  }

  void isExpression(IsExpression node) {
    if (flow == null) return;

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

  bool isPotentiallyNonNullableLocalReadBeforeWrite(SimpleIdentifier node) {
    if (flow == null) return false;

    if (node.inDeclarationContext()) return false;
    if (!node.inGetterContext()) return false;

    var element = node.staticElement;
    if (element is LocalVariableElement) {
      if (element.isLate) return false;

      var typeSystem = _typeOperations.typeSystem;
      if (typeSystem.isPotentiallyNonNullable(element.type)) {
        return !flow.isAssigned(element);
      }
    }

    return false;
  }

  void variableDeclarationStatement(VariableDeclarationStatement node) {
    var variables = node.variables.variables;
    for (var i = 0; i < variables.length; ++i) {
      var variable = variables[i];
      flow.add(variable.declaredElement,
          assigned: variable.initializer != null);
    }
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
}

/// The result of performing flow analysis on a unit.
class FlowAnalysisResult {
  static const _astKey = 'FlowAnalysisResult';

  /// The list of nodes, [Expression]s or [Statement]s, that cannot be reached,
  /// for example because a previous statement always exits.
  final List<AstNode> unreachableNodes = [];

  /// The list of [FunctionBody]s that don't complete, for example because
  /// there is a `return` statement at the end of the function body block.
  final List<FunctionBody> functionBodiesThatDontComplete = [];

  void putIntoNode(AstNode node) {
    node.setProperty(_astKey, this);
  }

  static FlowAnalysisResult getFromNode(AstNode node) {
    return node.getProperty(_astKey);
  }
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

/// The flow analysis based implementation of [LocalVariableTypeProvider].
class _LocalVariableTypeProvider implements LocalVariableTypeProvider {
  final FlowAnalysisHelper _manager;

  _LocalVariableTypeProvider(this._manager);

  @override
  DartType getType(SimpleIdentifier node) {
    var variable = node.staticElement as VariableElement;
    var promotedType = _manager.flow?.promotedType(variable);
    return promotedType ?? variable.type;
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
  bool isLocalVariable(VariableElement element) {
    return element is LocalVariableElement;
  }

  @override
  bool isSameType(covariant TypeImpl type1, covariant TypeImpl type2) {
    if (type1.nullabilitySuffix != type2.nullabilitySuffix) {
      // TODO(paulberry): after DartType.operator== has been updated to compare
      // nullabilities, this if test can be dropped.  See dartbug.com/37587.
      return false;
    }
    return type1 == type2;
  }

  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return typeSystem.isSubtypeOf(leftType, rightType);
  }

  @override
  DartType promoteToNonNull(DartType type) {
    return typeSystem.promoteToNonNull(type);
  }

  @override
  DartType variableType(VariableElement variable) {
    return variable.type;
  }
}
