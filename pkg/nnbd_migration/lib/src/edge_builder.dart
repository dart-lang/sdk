// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/fasta/flow_analysis/flow_analysis.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/utilities/annotation_tracker.dart';
import 'package:nnbd_migration/src/utilities/permissive_mode.dart';
import 'package:nnbd_migration/src/utilities/scoped_set.dart';

import 'decorated_type_operations.dart';

/// Test class mixing in _AssignmentChecker, to allow [checkAssignment] to be
/// more easily unit tested.
@visibleForTesting
class AssignmentCheckerForTesting extends Object with _AssignmentChecker {
  @override
  final TypeSystem _typeSystem;

  final NullabilityGraph _graph;

  /// Tests should fill in this map with the bounds of any type parameters being
  /// tested.
  final Map<TypeParameterElement, DecoratedType> bounds = {};

  @override
  final DecoratedClassHierarchy _decoratedClassHierarchy;

  AssignmentCheckerForTesting(
      this._typeSystem, this._graph, this._decoratedClassHierarchy);

  void checkAssignment(EdgeOrigin origin,
      {@required DecoratedType source,
      @required DecoratedType destination,
      @required bool hard}) {
    super._checkAssignment(origin,
        source: source, destination: destination, hard: hard);
  }

  @override
  void _connect(
      NullabilityNode source, NullabilityNode destination, EdgeOrigin origin,
      {bool hard = false}) {
    _graph.connect(source, destination, origin, hard: hard);
  }

  @override
  DecoratedType _getTypeParameterTypeBound(DecoratedType type) {
    return bounds[(type.type as TypeParameterType).element] ??
        (throw StateError('Unknown bound for $type'));
  }
}

/// Visitor that builds nullability graph edges by examining code to be
/// migrated.
///
/// The return type of each `visit...` method is a [DecoratedType] indicating
/// the static type of the visited expression, along with the constraint
/// variables that will determine its nullability.  For `visit...` methods that
/// don't visit expressions, `null` will be returned.
class EdgeBuilder extends GeneralizingAstVisitor<DecoratedType>
    with
        _AssignmentChecker,
        PermissiveModeVisitor<DecoratedType>,
        AnnotationTracker<DecoratedType> {
  final TypeSystem _typeSystem;

  final InheritanceManager3 _inheritanceManager;

  /// The repository of constraint variables and decorated types (from a
  /// previous pass over the source code).
  final VariableRepository _variables;

  final NullabilityMigrationListener /*?*/ listener;

  final NullabilityGraph _graph;

  TypeProvider _typeProvider;

  @override
  final Source source;

  @override
  final DecoratedClassHierarchy _decoratedClassHierarchy;

  /// If we are visiting a function body or initializer, instance of flow
  /// analysis.  Otherwise `null`.
  FlowAnalysis<Statement, Expression, VariableElement, DecoratedType>
      _flowAnalysis;

  /// If we are visiting a function body or initializer, assigned variable
  /// information  used in flow analysis.  Otherwise `null`.
  AssignedVariables<AstNode, VariableElement> _assignedVariables;

  /// For convenience, a [DecoratedType] representing non-nullable `Object`.
  final DecoratedType _notNullType;

  /// For convenience, a [DecoratedType] representing non-nullable `bool`.
  final DecoratedType _nonNullableBoolType;

  /// For convenience, a [DecoratedType] representing non-nullable `Type`.
  final DecoratedType _nonNullableTypeType;

  /// For convenience, a [DecoratedType] representing `Null`.
  final DecoratedType _nullType;

  /// For convenience, a [DecoratedType] representing `dynamic`.
  final DecoratedType _dynamicType;

  /// The [DecoratedType] of the innermost function or method being visited, or
  /// `null` if the visitor is not inside any function or method.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// return statements.
  DecoratedType _currentFunctionType;

  /// The [DecoratedType] of the innermost list or set literal being visited, or
  /// `null` if the visitor is not inside any function or method.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// ui as code list elements.
  DecoratedType _currentLiteralType;

  /// Information about the most recently visited binary expression whose
  /// boolean value could possibly affect nullability analysis.
  _ConditionInfo _conditionInfo;

  /// The set of nullability nodes that would have to be `nullable` for the code
  /// currently being visited to be reachable.
  ///
  /// Guard variables are attached to the left hand side of any generated
  /// constraints, so that constraints do not take effect if they come from
  /// code that can be proven unreachable by the migration tool.
  final _guards = <NullabilityNode>[];

  /// The scope of locals (parameters, variables) that are post-dominated by the
  /// current node as we walk the AST. We use a [_ScopedLocalSet] so that outer
  /// scopes may track their post-dominators separately from inner scopes.
  ///
  /// Note that this is not guaranteed to be complete. It is used to make hard
  /// edges on a best-effort basis.
  final _postDominatedLocals = _ScopedLocalSet();

  /// Map whose keys are expressions of the form `a?.b` on the LHS of
  /// assignments, and whose values are the nullability nodes corresponding to
  /// the expression preceding `?.`.  These are needed in order to properly
  /// analyze expressions like `a?.b += c`, since the type of the compound
  /// assignment is nullable if the type of the expression preceding `?.` is
  /// nullable.
  final Map<Expression, NullabilityNode> _conditionalNodes = {};

  EdgeBuilder(this._typeProvider, this._typeSystem, this._variables,
      this._graph, this.source, this.listener)
      : _decoratedClassHierarchy = DecoratedClassHierarchy(_variables, _graph),
        _inheritanceManager = InheritanceManager3(_typeSystem),
        _notNullType = DecoratedType(_typeProvider.objectType, _graph.never),
        _nonNullableBoolType =
            DecoratedType(_typeProvider.boolType, _graph.never),
        _nonNullableTypeType =
            DecoratedType(_typeProvider.typeType, _graph.never),
        _nullType = DecoratedType(_typeProvider.nullType, _graph.always),
        _dynamicType = DecoratedType(_typeProvider.dynamicType, _graph.always);

  /// Gets the decorated type of [element] from [_variables], performing any
  /// necessary substitutions.
  DecoratedType getOrComputeElementType(Element element,
      {DecoratedType targetType}) {
    Map<TypeParameterElement, DecoratedType> substitution;
    Element baseElement;
    if (element is Member) {
      assert(targetType != null);
      baseElement = element.baseElement;
      var targetTypeType = targetType.type;
      if (targetTypeType is InterfaceType &&
          baseElement is ClassMemberElement) {
        var enclosingClass = baseElement.enclosingElement as ClassElement;
        assert(targetTypeType.element == enclosingClass); // TODO(paulberry)
        substitution = <TypeParameterElement, DecoratedType>{};
        assert(enclosingClass.typeParameters.length ==
            targetTypeType.typeArguments.length); // TODO(paulberry)
        for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
          substitution[enclosingClass.typeParameters[i]] =
              targetType.typeArguments[i];
        }
      }
    } else {
      baseElement = element;
    }
    DecoratedType decoratedBaseType;
    if (baseElement is PropertyAccessorElement &&
        baseElement.isSynthetic &&
        !baseElement.variable.isSynthetic) {
      var variable = baseElement.variable;
      var decoratedElementType = _variables.decoratedElementType(variable);
      if (baseElement.isGetter) {
        decoratedBaseType = DecoratedType(baseElement.type, _graph.never,
            returnType: decoratedElementType);
      } else {
        assert(baseElement.isSetter);
        decoratedBaseType = DecoratedType(baseElement.type, _graph.never,
            positionalParameters: [decoratedElementType],
            returnType: DecoratedType(VoidTypeImpl.instance, _graph.always));
      }
    } else {
      decoratedBaseType = _variables.decoratedElementType(baseElement);
    }
    if (substitution != null) {
      DartType elementType;
      if (element is MethodElement) {
        elementType = element.type;
      } else if (element is ConstructorElement) {
        elementType = element.type;
      } else {
        throw element.runtimeType; // TODO(paulberry)
      }
      return decoratedBaseType.substitute(substitution, elementType);
    } else {
      return decoratedBaseType;
    }
  }

  @override
  DecoratedType visitAsExpression(AsExpression node) {
    // TODO(brianwilkerson)
    _unimplemented(node, 'AsExpression');
  }

  @override
  DecoratedType visitAssertStatement(AssertStatement node) {
    _checkExpressionNotNull(node.condition);
    if (identical(_conditionInfo?.condition, node.condition)) {
      var intentNode = _conditionInfo.trueDemonstratesNonNullIntent;
      if (intentNode != null && _conditionInfo.postDominatingIntent) {
        _graph.connect(_conditionInfo.trueDemonstratesNonNullIntent,
            _graph.never, NonNullAssertionOrigin(source, node.offset),
            hard: true);
      }
    }
    node.message?.accept(this);
    return null;
  }

  @override
  DecoratedType visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type != TokenType.EQ) {
      // TODO(paulberry)
      _unimplemented(node, 'Assignment with operator ${node.operator.lexeme}');
    }
    _postDominatedLocals.removeReferenceFromAllScopes(node.leftHandSide);
    var expressionType = _handleAssignment(node.rightHandSide,
        destinationExpression: node.leftHandSide);
    var conditionalNode = _conditionalNodes[node.leftHandSide];
    if (conditionalNode != null) {
      expressionType = expressionType.withNode(
          NullabilityNode.forLUB(conditionalNode, expressionType.node));
      _variables.recordDecoratedExpressionType(node, expressionType);
    }
    return expressionType;
  }

  @override
  DecoratedType visitAwaitExpression(AwaitExpression node) {
    var expressionType = node.expression.accept(this);
    // TODO(paulberry) Handle subclasses of Future.
    if (expressionType.type.isDartAsyncFuture ||
        expressionType.type.isDartAsyncFutureOr) {
      expressionType = expressionType.typeArguments[0];
    }
    return expressionType;
  }

  @override
  DecoratedType visitBinaryExpression(BinaryExpression node) {
    var operatorType = node.operator.type;
    if (operatorType == TokenType.EQ_EQ || operatorType == TokenType.BANG_EQ) {
      assert(node.leftOperand is! NullLiteral); // TODO(paulberry)
      var leftType = node.leftOperand.accept(this);
      node.rightOperand.accept(this);
      if (node.rightOperand is NullLiteral) {
        // TODO(paulberry): only set falseChecksNonNull in unconditional
        // control flow
        bool notEqual = operatorType == TokenType.BANG_EQ;
        bool isPure = false;
        var leftOperand = node.leftOperand;
        if (leftOperand is SimpleIdentifier) {
          // TODO(paulberry): figure out what the rules for isPure should be.
          isPure = true;
          var element = leftOperand.staticElement;
          if (element is VariableElement) {
            _flowAnalysis.conditionEqNull(node, element, notEqual: notEqual);
          }
        }
        var conditionInfo = _ConditionInfo(node,
            isPure: isPure,
            postDominatingIntent:
                _postDominatedLocals.isReferenceInScope(node.leftOperand),
            trueGuard: leftType.node,
            falseDemonstratesNonNullIntent: leftType.node);
        _conditionInfo = notEqual ? conditionInfo.not(node) : conditionInfo;
      }
      return _nonNullableBoolType;
    } else if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
        operatorType == TokenType.BAR_BAR) {
      bool isAnd = operatorType == TokenType.AMPERSAND_AMPERSAND;
      _checkExpressionNotNull(node.leftOperand);
      _flowAnalysis.logicalBinaryOp_rightBegin(node.leftOperand, isAnd: isAnd);
      _postDominatedLocals.doScoped(
          action: () => _checkExpressionNotNull(node.rightOperand));
      _flowAnalysis.logicalBinaryOp_end(node, node.rightOperand, isAnd: isAnd);
      return _nonNullableBoolType;
    } else if (operatorType == TokenType.QUESTION_QUESTION) {
      DecoratedType expressionType;
      var leftType = node.leftOperand.accept(this);
      _flowAnalysis.ifNullExpression_rightBegin();
      try {
        _guards.add(leftType.node);
        DecoratedType rightType;
        _postDominatedLocals.doScoped(action: () {
          rightType = node.rightOperand.accept(this);
        });
        var ifNullNode = NullabilityNode.forIfNotNull();
        expressionType = DecoratedType(node.staticType, ifNullNode);
        _connect(rightType.node, expressionType.node,
            IfNullOrigin(source, node.offset));
      } finally {
        _flowAnalysis.ifNullExpression_end();
        _guards.removeLast();
      }
      _variables.recordDecoratedExpressionType(node, expressionType);
      return expressionType;
    } else if (operatorType.isUserDefinableOperator) {
      _checkExpressionNotNull(node.leftOperand);
      var callee = node.staticElement;
      assert(!(callee is ClassMemberElement &&
          (callee.enclosingElement as ClassElement)
              .typeParameters
              .isNotEmpty)); // TODO(paulberry)
      assert(callee != null); // TODO(paulberry)
      var calleeType = getOrComputeElementType(callee);
      // TODO(paulberry): substitute if necessary
      assert(calleeType.positionalParameters.length > 0); // TODO(paulberry)
      _handleAssignment(node.rightOperand,
          destinationType: calleeType.positionalParameters[0]);
      return _fixNumericTypes(calleeType.returnType, node.staticType);
    } else {
      // TODO(paulberry)
      node.leftOperand.accept(this);
      node.rightOperand.accept(this);
      _unimplemented(
          node, 'Binary expression with operator ${node.operator.lexeme}');
    }
  }

  @override
  DecoratedType visitBooleanLiteral(BooleanLiteral node) {
    _flowAnalysis.booleanLiteral(node, node.value);
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitBreakStatement(BreakStatement node) {
    _flowAnalysis.handleBreak(FlowAnalysisHelper.getLabelTarget(
        node, node.label?.staticElement as LabelElement));
    // Later statements no longer post-dominate the declarations because we
    // exited (or, in parent scopes, conditionally exited).
    // TODO(mfairhurst): don't clear post-dominators beyond the current loop.
    _postDominatedLocals.clearEachScope();

    return null;
  }

  @override
  DecoratedType visitCascadeExpression(CascadeExpression node) {
    var type = node.target.accept(this);
    node.cascadeSections.accept(this);
    return type;
  }

  @override
  DecoratedType visitCatchClause(CatchClause node) {
    _flowAnalysis.tryCatchStatement_catchBegin();
    node.exceptionType?.accept(this);
    for (var identifier in [
      node.exceptionParameter,
      node.stackTraceParameter
    ]) {
      if (identifier != null) {
        _flowAnalysis.add(identifier.staticElement as VariableElement,
            assigned: true);
      }
    }
    // The catch clause may not execute, so create a new scope for
    // post-dominators.
    _postDominatedLocals.doScoped(action: () => node.body.accept(this));
    _flowAnalysis.tryCatchStatement_catchEnd();
    return null;
  }

  @override
  DecoratedType visitClassDeclaration(ClassDeclaration node) {
    node.members.accept(this);
    return null;
  }

  @override
  DecoratedType visitClassTypeAlias(ClassTypeAlias node) {
    var classElement = node.declaredElement;
    var supertype = classElement.supertype;
    var superElement = supertype.element;
    if (superElement is ClassElementHandle) {
      superElement = (superElement as ClassElementHandle).actualElement;
    }
    for (var constructorElement in classElement.constructors) {
      assert(constructorElement.isSynthetic);
      var superConstructorElement =
          superElement.getNamedConstructor(constructorElement.name);
      var constructorDecoratedType = _variables
          .decoratedElementType(constructorElement)
          .substitute(_decoratedClassHierarchy
              .getDecoratedSupertype(classElement, superElement)
              .asSubstitution);
      var superConstructorDecoratedType =
          _variables.decoratedElementType(superConstructorElement);
      var origin = ImplicitMixinSuperCallOrigin(source, node.offset);
      _unionDecoratedTypeParameters(
          constructorDecoratedType, superConstructorDecoratedType, origin);
    }
    return null;
  }

  @override
  DecoratedType visitComment(Comment node) {
    // Ignore comments.
    return null;
  }

  @override
  DecoratedType visitConditionalExpression(ConditionalExpression node) {
    _checkExpressionNotNull(node.condition);

    DecoratedType thenType;
    DecoratedType elseType;

    // TODO(paulberry): guard anything inside the true and false branches

    // Post-dominators diverge as we branch in the conditional.
    // Note: we don't have to create a scope for each branch because they can't
    // define variables.
    _postDominatedLocals.doScoped(action: () {
      _flowAnalysis.conditional_thenBegin(node.condition);
      thenType = node.thenExpression.accept(this);
      _flowAnalysis.conditional_elseBegin(node.thenExpression);
      elseType = node.elseExpression.accept(this);
      _flowAnalysis.conditional_end(node, node.elseExpression);
    });

    var overallType = _decorateUpperOrLowerBound(
        node, node.staticType, thenType, elseType, true);
    _variables.recordDecoratedExpressionType(node, overallType);
    return overallType;
  }

  @override
  DecoratedType visitConstructorDeclaration(ConstructorDeclaration node) {
    _handleExecutableDeclaration(
        node,
        node.declaredElement,
        node.metadata,
        null,
        node.parameters,
        node.initializers,
        node.body,
        node.redirectedConstructor);
    return null;
  }

  @override
  DecoratedType visitConstructorFieldInitializer(
      ConstructorFieldInitializer node) {
    _handleAssignment(node.expression,
        destinationType: getOrComputeElementType(node.fieldName.staticElement));
    return null;
  }

  @override
  DecoratedType visitContinueStatement(ContinueStatement node) {
    _flowAnalysis.handleContinue(FlowAnalysisHelper.getLabelTarget(
        node, node.label?.staticElement as LabelElement));
    // Later statements no longer post-dominate the declarations because we
    // exited (or, in parent scopes, conditionally exited).
    // TODO(mfairhurst): don't clear post-dominators beyond the current loop.
    _postDominatedLocals.clearEachScope();

    return null;
  }

  @override
  DecoratedType visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
    var defaultValue = node.defaultValue;
    if (defaultValue == null) {
      if (node.declaredElement.hasRequired) {
        // Nothing to do; the implicit default value of `null` will never be
        // reached.
      } else {
        _connect(
            _graph.always,
            getOrComputeElementType(node.declaredElement).node,
            OptionalFormalParameterOrigin(source, node.offset));
      }
    } else {
      _handleAssignment(defaultValue,
          destinationType: getOrComputeElementType(node.declaredElement),
          canInsertChecks: false);
    }
    return null;
  }

  @override
  DecoratedType visitDoStatement(DoStatement node) {
    _flowAnalysis.doStatement_bodyBegin(node, _assignedVariables[node]);
    node.body.accept(this);
    _flowAnalysis.doStatement_conditionBegin();
    _checkExpressionNotNull(node.condition);
    _flowAnalysis.doStatement_end(node.condition);
    return null;
  }

  @override
  DecoratedType visitDoubleLiteral(DoubleLiteral node) {
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (_currentFunctionType == null) {
      _unimplemented(
          node,
          'ExpressionFunctionBody with no current function '
          '(parent is ${node.parent.runtimeType})');
    }
    _handleAssignment(node.expression,
        destinationType: _currentFunctionType.returnType);
    return null;
  }

  @override
  DecoratedType visitFieldDeclaration(FieldDeclaration node) {
    node.metadata.accept(this);
    _createFlowAnalysis(node);
    try {
      node.fields.accept(this);
    } finally {
      _flowAnalysis.finish();
      _flowAnalysis = null;
      _assignedVariables = null;
    }
    return null;
  }

  @override
  DecoratedType visitFieldFormalParameter(FieldFormalParameter node) {
    var parameterElement = node.declaredElement as FieldFormalParameterElement;
    var parameterType = _variables.decoratedElementType(parameterElement);
    var fieldType = _variables.decoratedElementType(parameterElement.field);
    var origin = FieldFormalParameterOrigin(source, node.offset);
    if (node.type == null) {
      _unionDecoratedTypes(parameterType, fieldType, origin);
    } else {
      _checkAssignment(origin,
          source: parameterType, destination: fieldType, hard: true);
    }
    return null;
  }

  @override
  DecoratedType visitForElement(ForElement node) {
    _handleForLoopParts(node, node.forLoopParts, node.body);
    return null;
  }

  @override
  DecoratedType visitForStatement(ForStatement node) {
    _handleForLoopParts(node, node.forLoopParts, node.body);
    return null;
  }

  @override
  DecoratedType visitFunctionDeclaration(FunctionDeclaration node) {
    if (_flowAnalysis != null) {
      // This is a local function.
      node.functionExpression.accept(this);
    } else {
      _createFlowAnalysis(node.functionExpression.body);
      // Initialize a new postDominator scope that contains only the parameters.
      try {
        node.functionExpression.accept(this);
      } finally {
        _flowAnalysis.finish();
        _flowAnalysis = null;
        _assignedVariables = null;
      }
    }
    return null;
  }

  @override
  DecoratedType visitFunctionExpression(FunctionExpression node) {
    // TODO(mfairhurst): enable edge builder "_insideFunction" hard edge tests.
    node.parameters?.accept(this);
    _addParametersToFlowAnalysis(node.parameters);
    var previousFunctionType = _currentFunctionType;
    _currentFunctionType =
        _variables.decoratedElementType(node.declaredElement);
    try {
      _postDominatedLocals.doScoped(
          elements: node.declaredElement.parameters,
          action: () => node.body.accept(this));
      return _currentFunctionType;
    } finally {
      _currentFunctionType = previousFunctionType;
    }
  }

  @override
  DecoratedType visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    DecoratedType calleeType = node.function.accept(this);
    return _handleInvocationArguments(node, node.argumentList.arguments,
        node.typeArguments, calleeType, null);
  }

  @override
  DecoratedType visitIfElement(IfElement node) {
    _checkExpressionNotNull(node.condition);
    NullabilityNode trueGuard;
    NullabilityNode falseGuard;
    if (identical(_conditionInfo?.condition, node.condition)) {
      trueGuard = _conditionInfo.trueGuard;
      falseGuard = _conditionInfo.falseGuard;
      _variables.recordConditionalDiscard(source, node,
          ConditionalDiscard(trueGuard, falseGuard, _conditionInfo.isPure));
    }
    if (trueGuard != null) {
      _guards.add(trueGuard);
    }
    try {
      _postDominatedLocals.doScoped(
          action: () => _handleCollectionElement(node.thenElement));
    } finally {
      if (trueGuard != null) {
        _guards.removeLast();
      }
    }
    if (node.elseElement != null) {
      if (falseGuard != null) {
        _guards.add(falseGuard);
      }
      try {
        _postDominatedLocals.doScoped(
            action: () => _handleCollectionElement(node.elseElement));
      } finally {
        if (falseGuard != null) {
          _guards.removeLast();
        }
      }
    }
    return null;
  }

  @override
  DecoratedType visitIfStatement(IfStatement node) {
    _checkExpressionNotNull(node.condition);
    NullabilityNode trueGuard;
    NullabilityNode falseGuard;
    if (identical(_conditionInfo?.condition, node.condition)) {
      trueGuard = _conditionInfo.trueGuard;
      falseGuard = _conditionInfo.falseGuard;
      _variables.recordConditionalDiscard(source, node,
          ConditionalDiscard(trueGuard, falseGuard, _conditionInfo.isPure));
    }
    if (trueGuard != null) {
      _guards.add(trueGuard);
    }
    try {
      _flowAnalysis.ifStatement_thenBegin(node.condition);
      // We branched, so create a new scope for post-dominators.
      _postDominatedLocals.doScoped(
          action: () => node.thenStatement.accept(this));
    } finally {
      if (trueGuard != null) {
        _guards.removeLast();
      }
    }
    if (falseGuard != null) {
      _guards.add(falseGuard);
    }
    var elseStatement = node.elseStatement;
    try {
      if (elseStatement != null) {
        _flowAnalysis.ifStatement_elseBegin();
        // We branched, so create a new scope for post-dominators.
        _postDominatedLocals.doScoped(
            action: () => node.elseStatement?.accept(this));
      }
    } finally {
      _flowAnalysis.ifStatement_end(elseStatement != null);
      if (falseGuard != null) {
        _guards.removeLast();
      }
    }
    return null;
  }

  @override
  DecoratedType visitIndexExpression(IndexExpression node) {
    DecoratedType targetType;
    var target = node.realTarget;
    if (target != null) {
      targetType = _checkExpressionNotNull(target);
    }
    var callee = node.staticElement;
    if (callee == null) {
      // TODO(paulberry)
      _unimplemented(node, 'Index expression with no static type');
    }
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    // TODO(paulberry): substitute if necessary
    _handleAssignment(node.index,
        destinationType: calleeType.positionalParameters[0]);
    if (node.inSetterContext()) {
      return calleeType.positionalParameters[1];
    } else {
      return calleeType.returnType;
    }
  }

  @override
  DecoratedType visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    var callee = node.staticElement;
    var typeParameters = callee.enclosingElement.typeParameters;
    List<DecoratedType> decoratedTypeArguments;
    var typeArguments = node.constructorName.type.typeArguments;
    if (typeArguments != null) {
      decoratedTypeArguments = typeArguments.arguments
          .map((t) => _variables.decoratedTypeAnnotation(source, t))
          .toList();
    } else {
      decoratedTypeArguments = const [];
    }
    var createdType = DecoratedType(node.staticType, _graph.never,
        typeArguments: decoratedTypeArguments);
    var calleeType = getOrComputeElementType(callee, targetType: createdType);
    _handleInvocationArguments(node, node.argumentList.arguments, typeArguments,
        calleeType, typeParameters);
    return createdType;
  }

  @override
  DecoratedType visitIntegerLiteral(IntegerLiteral node) {
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitIsExpression(IsExpression node) {
    var type = node.type;
    if (type is NamedType && type.typeArguments != null) {
      // TODO(brianwilkerson) Figure out what constraints we need to add to
      //  allow the tool to decide whether to make the type arguments nullable.
      // TODO(brianwilkerson)
      _unimplemented(node, 'Is expression with type arguments');
    } else if (type is GenericFunctionType) {
      // TODO(brianwilkerson)
      _unimplemented(node, 'Is expression with GenericFunctionType');
    }
    node.visitChildren(this);
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitLabel(Label node) {
    // Labels are identifiers but they don't have types so we don't need to
    // visit them directly.
    return null;
  }

  @override
  DecoratedType visitLibraryDirective(LibraryDirective node) {
    // skip directives
    return null;
  }

  @override
  DecoratedType visitListLiteral(ListLiteral node) {
    final previousLiteralType = _currentLiteralType;
    try {
      var listType = node.staticType as InterfaceType;
      if (node.typeArguments == null) {
        _currentLiteralType = DecoratedType.forImplicitType(
            _typeProvider, listType.typeArguments[0], _graph);
      } else {
        _currentLiteralType = _variables.decoratedTypeAnnotation(
            source, node.typeArguments.arguments[0]);
      }
      node.elements.forEach(_handleCollectionElement);
      return DecoratedType(listType, _graph.never,
          typeArguments: [_currentLiteralType]);
    } finally {
      _currentLiteralType = previousLiteralType;
    }
  }

  @override
  DecoratedType visitMethodDeclaration(MethodDeclaration node) {
    if (node.typeParameters != null) {
      _unimplemented(node, 'Generic method');
    }
    _handleExecutableDeclaration(node, node.declaredElement, node.metadata,
        node.returnType, node.parameters, null, node.body, null);
    return null;
  }

  @override
  DecoratedType visitMethodInvocation(MethodInvocation node) {
    DecoratedType targetType;
    var target = node.realTarget;
    bool isConditional = _isConditionalExpression(node);
    if (target != null) {
      if (isConditional) {
        targetType = target.accept(this);
      } else {
        _checkNonObjectMember(node.methodName.name); // TODO(paulberry)
        targetType = _checkExpressionNotNull(target);
      }
    }
    var callee = node.methodName.staticElement;
    if (callee == null) {
      // Dynamic dispatch.  The return type is `dynamic`.
      // TODO(paulberry): would it be better to assume a return type of `Never`
      // so that we don't unnecessarily propagate nullabilities everywhere?
      return _dynamicType;
    }
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    if (callee is PropertyAccessorElement) {
      calleeType = calleeType.returnType;
    }
    var expressionType = _handleInvocationArguments(node,
        node.argumentList.arguments, node.typeArguments, calleeType, null);
    if (isConditional) {
      expressionType = expressionType.withNode(
          NullabilityNode.forLUB(targetType.node, expressionType.node));
      _variables.recordDecoratedExpressionType(node, expressionType);
    }
    return expressionType;
  }

  @override
  DecoratedType visitNamespaceDirective(NamespaceDirective node) {
    // skip directives
    return null;
  }

  @override
  DecoratedType visitNullLiteral(NullLiteral node) {
    return _nullType;
  }

  @override
  DecoratedType visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  @override
  DecoratedType visitPostfixExpression(PostfixExpression node) {
    var operatorType = node.operator.type;
    if (operatorType == TokenType.PLUS_PLUS ||
        operatorType == TokenType.MINUS_MINUS) {
      _checkExpressionNotNull(node.operand);
      var callee = node.staticElement;
      if (callee is ClassMemberElement &&
          (callee.enclosingElement as ClassElement).typeParameters.isNotEmpty) {
        // TODO(paulberry)
        _unimplemented(node,
            'Operator ${operatorType.lexeme} defined on a class with type parameters');
      }
      if (callee == null) {
        // TODO(paulberry)
        _unimplemented(node, 'Unresolved operator ${operatorType.lexeme}');
      }
      var calleeType = getOrComputeElementType(callee);
      // TODO(paulberry): substitute if necessary
      return _fixNumericTypes(calleeType.returnType, node.staticType);
    }
    _unimplemented(
        node, 'Postfix expression with operator ${node.operator.lexeme}');
  }

  @override
  DecoratedType visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.staticElement is ImportElement) {
      // TODO(paulberry)
      _unimplemented(node, 'PrefixedIdentifier with a prefix');
    } else {
      return _handlePropertyAccess(node, node.prefix, node.identifier);
    }
  }

  @override
  DecoratedType visitPrefixExpression(PrefixExpression node) {
    var targetType = _checkExpressionNotNull(node.operand);
    var operatorType = node.operator.type;
    if (operatorType == TokenType.BANG) {
      _flowAnalysis.logicalNot_end(node, node.operand);
      return _nonNullableBoolType;
    } else if (operatorType == TokenType.PLUS_PLUS ||
        operatorType == TokenType.MINUS_MINUS) {
      var callee = node.staticElement;
      if (callee is ClassMemberElement &&
          (callee.enclosingElement as ClassElement).typeParameters.isNotEmpty) {
        // TODO(paulberry)
        _unimplemented(node,
            'Operator ${operatorType.lexeme} defined on a class with type parameters');
      }
      if (callee == null) {
        // TODO(paulberry)
        _unimplemented(node, 'Unresolved operator ${operatorType.lexeme}');
      }
      var calleeType = getOrComputeElementType(callee);
      // TODO(paulberry): substitute if necessary
      return _fixNumericTypes(calleeType.returnType, node.staticType);
    } else {
      var callee = node.staticElement;
      var calleeType = getOrComputeElementType(callee, targetType: targetType);
      return _handleInvocationArguments(node, [], null, calleeType, null);
    }
  }

  @override
  DecoratedType visitPropertyAccess(PropertyAccess node) {
    return _handlePropertyAccess(node, node.realTarget, node.propertyName);
  }

  @override
  DecoratedType visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var callee = node.staticElement;
    var calleeType = _variables.decoratedElementType(callee);
    _handleInvocationArguments(
        node, node.argumentList.arguments, null, calleeType, null);
    return null;
  }

  @override
  DecoratedType visitRethrowExpression(RethrowExpression node) {
    _flowAnalysis.handleExit();
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitReturnStatement(ReturnStatement node) {
    DecoratedType returnType = _currentFunctionType.returnType;
    Expression returnValue = node.expression;
    // TODO(danrubel): This does not handle situations where the returnType
    // or the returnValue's type extends or implements dart:async Future.
    if ((returnType.type.isDartAsyncFuture ||
            returnType.type.isDartAsyncFutureOr) &&
        node.thisOrAncestorOfType<FunctionBody>().isAsynchronous &&
        !returnValue.staticType.isDartAsyncFuture) {
      returnType = returnType.typeArguments.first;
    }
    if (returnValue == null) {
      _checkAssignment(null,
          source: _nullType, destination: returnType, hard: false);
    } else {
      _handleAssignment(returnValue, destinationType: returnType);
    }

    _flowAnalysis.handleExit();
    // Later statements no longer post-dominate the declarations because we
    // exited (or, in parent scopes, conditionally exited).
    // TODO(mfairhurst): don't clear post-dominators beyond the current function.
    _postDominatedLocals.clearEachScope();

    return null;
  }

  @override
  DecoratedType visitSetOrMapLiteral(SetOrMapLiteral node) {
    var listType = node.staticType as InterfaceType;
    var typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null) {
      // TODO(brianwilkerson) We might want to create fake nodes in the graph to
      //  represent the type arguments so that we can still create edges from
      //  the elements to them.
      // TODO(brianwilkerson)
      _unimplemented(node, 'Set or map literal with no type arguments');
    } else if (typeArguments.length == 1) {
      var elementType =
          _variables.decoratedTypeAnnotation(source, typeArguments[0]);
      for (var element in node.elements) {
        if (element is Expression) {
          _handleAssignment(element, destinationType: elementType);
        } else {
          // Handle spread and control flow elements.
          element.accept(this);
          // TODO(brianwilkerson)
          _unimplemented(node, 'Spread or control flow element');
        }
      }
      return DecoratedType(listType, _graph.never,
          typeArguments: [elementType]);
    } else if (typeArguments.length == 2) {
      var keyType =
          _variables.decoratedTypeAnnotation(source, typeArguments[0]);
      var valueType =
          _variables.decoratedTypeAnnotation(source, typeArguments[1]);
      for (var element in node.elements) {
        if (element is MapLiteralEntry) {
          _handleAssignment(element.key, destinationType: keyType);
          _handleAssignment(element.value, destinationType: valueType);
        } else {
          // Handle spread and control flow elements.
          element.accept(this);
          // TODO(brianwilkerson)
          _unimplemented(node, 'Spread or control flow element');
        }
      }
      return DecoratedType(listType, _graph.never,
          typeArguments: [keyType, valueType]);
    } else {
      // TODO(brianwilkerson)
      _unimplemented(
          node, 'Set or map literal with more than two type arguments');
    }
  }

  @override
  DecoratedType visitSimpleIdentifier(SimpleIdentifier node) {
    var staticElement = node.staticElement;
    if (staticElement is VariableElement) {
      if (!node.inDeclarationContext()) {
        var promotedType = _flowAnalysis.promotedType(staticElement);
        if (promotedType != null) return promotedType;
      }
      return getOrComputeElementType(staticElement);
    } else if (staticElement is FunctionElement ||
        staticElement is MethodElement) {
      return getOrComputeElementType(staticElement);
    } else if (staticElement is PropertyAccessorElement) {
      var elementType = getOrComputeElementType(staticElement);
      return staticElement.isGetter
          ? elementType.returnType
          : elementType.positionalParameters[0];
    } else if (staticElement is ClassElement) {
      return _nonNullableTypeType;
    } else {
      // TODO(paulberry)
      _unimplemented(node,
          'Simple identifier with a static element of type ${staticElement.runtimeType}');
    }
  }

  @override
  DecoratedType visitStringLiteral(StringLiteral node) {
    node.visitChildren(this);
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitSuperExpression(SuperExpression node) {
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);
    _flowAnalysis.switchStatement_expressionEnd(node);
    var notPromoted = _assignedVariables[node];
    var hasDefault = false;
    for (var member in node.members) {
      var hasLabel = member.labels.isNotEmpty;
      _flowAnalysis.switchStatement_beginCase(hasLabel, notPromoted);
      if (member is SwitchCase) {
        member.expression.accept(this);
      } else {
        hasDefault = true;
      }
      member.statements.accept(this);
    }
    _flowAnalysis.switchStatement_end(hasDefault);
    return null;
  }

  @override
  DecoratedType visitSymbolLiteral(SymbolLiteral node) {
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitThisExpression(ThisExpression node) {
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitThrowExpression(ThrowExpression node) {
    node.expression.accept(this);
    // TODO(paulberry): do we need to check the expression type?  I think not.
    _flowAnalysis.handleExit();
    return DecoratedType(node.staticType, _graph.never);
  }

  @override
  DecoratedType visitTopLevelVariableDeclaration(
      TopLevelVariableDeclaration node) {
    node.metadata.accept(this);
    _createFlowAnalysis(node);
    try {
      node.variables.accept(this);
    } finally {
      _flowAnalysis.finish();
      _flowAnalysis = null;
      _assignedVariables = null;
    }
    return null;
  }

  @override
  DecoratedType visitTryStatement(TryStatement node) {
    var finallyBlock = node.finallyBlock;
    if (finallyBlock != null) {
      _flowAnalysis.tryFinallyStatement_bodyBegin();
    }
    var catchClauses = node.catchClauses;
    if (catchClauses.isNotEmpty) {
      _flowAnalysis.tryCatchStatement_bodyBegin();
    }
    var body = node.body;
    body.accept(this);
    var assignedInBody = _assignedVariables[body];
    if (catchClauses.isNotEmpty) {
      _flowAnalysis.tryCatchStatement_bodyEnd(assignedInBody);
      catchClauses.accept(this);
      _flowAnalysis.tryCatchStatement_end();
    }
    if (finallyBlock != null) {
      _flowAnalysis.tryFinallyStatement_finallyBegin(assignedInBody);
      finallyBlock.accept(this);
      _flowAnalysis.tryFinallyStatement_end(_assignedVariables[finallyBlock]);
    }
    return null;
  }

  @override
  DecoratedType visitTypeName(TypeName typeName) {
    var typeArguments = typeName.typeArguments?.arguments;
    var element = typeName.name.staticElement;
    if (element is TypeParameterizedElement) {
      if (typeArguments == null) {
        var instantiatedType =
            _variables.decoratedTypeAnnotation(source, typeName);
        if (instantiatedType == null) {
          throw new StateError('No type annotation for type name '
              '${typeName.toSource()}, offset=${typeName.offset}');
        }
        var origin = InstantiateToBoundsOrigin(source, typeName.offset);
        for (int i = 0; i < instantiatedType.typeArguments.length; i++) {
          _unionDecoratedTypes(
              instantiatedType.typeArguments[i],
              _variables.decoratedTypeParameterBound(element.typeParameters[i]),
              origin);
        }
      } else {
        for (int i = 0; i < typeArguments.length; i++) {
          DecoratedType bound;
          bound =
              _variables.decoratedTypeParameterBound(element.typeParameters[i]);
          assert(bound != null);
          var argumentType =
              _variables.decoratedTypeAnnotation(source, typeArguments[i]);
          if (argumentType == null) {
            _unimplemented(typeName,
                'No decorated type for type argument ${typeArguments[i]} ($i)');
          }
          _checkAssignment(null,
              source: argumentType, destination: bound, hard: true);
        }
      }
    }
    return _nonNullableTypeType;
  }

  @override
  DecoratedType visitVariableDeclarationList(VariableDeclarationList node) {
    node.metadata.accept(this);
    var typeAnnotation = node.type;
    for (var variable in node.variables) {
      variable.metadata.accept(this);
      var initializer = variable.initializer;
      _flowAnalysis.add(variable.declaredElement,
          assigned: initializer != null);
      if (initializer != null) {
        var destinationType = getOrComputeElementType(variable.declaredElement);
        if (typeAnnotation == null) {
          var initializerType = initializer.accept(this);
          if (initializerType == null) {
            throw StateError('No type computed for ${initializer.runtimeType} '
                '(${initializer.toSource()}) offset=${initializer.offset}');
          }
          _unionDecoratedTypes(initializerType, destinationType,
              InitializerInferenceOrigin(source, variable.name.offset));
        } else {
          _handleAssignment(initializer, destinationType: destinationType);
        }
      }
    }

    // Track post-dominators, except we cannot make hard edges to multi
    // declarations. Consider:
    //
    // int? x = null, y = 0;
    // y.toDouble();
    //
    // We cannot make a hard edge from y to never in this case.
    if (node.variables.length == 1) {
      _postDominatedLocals.add(node.variables.single.declaredElement);
    }

    return null;
  }

  @override
  DecoratedType visitWhileStatement(WhileStatement node) {
    // Note: we do not create guards. A null check here is *very* unlikely to be
    // unnecessary after analysis.
    _flowAnalysis.whileStatement_conditionBegin(_assignedVariables[node]);
    _checkExpressionNotNull(node.condition);
    _flowAnalysis.whileStatement_bodyBegin(node, node.condition);
    _postDominatedLocals.doScoped(action: () => node.body.accept(this));
    _flowAnalysis.whileStatement_end();
    return null;
  }

  void _addParametersToFlowAnalysis(FormalParameterList parameters) {
    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        _flowAnalysis.add(parameter.declaredElement, assigned: true);
      }
    }
  }

  /// Visits [expression] and generates the appropriate edge to assert that its
  /// value is non-null.
  ///
  /// Returns the decorated type of [expression].
  DecoratedType _checkExpressionNotNull(Expression expression) {
    // Note: it's not necessary for `destinationType` to precisely match the
    // type of the expression, since all we are doing is causing a single graph
    // edge to be built; it is sufficient to pass in any decorated type whose
    // node is `never`.
    return _handleAssignment(expression, destinationType: _notNullType);
  }

  /// Double checks that [name] is not the name of a method or getter declared
  /// on [Object].
  ///
  /// TODO(paulberry): get rid of this method and put the correct logic into the
  /// call sites.
  void _checkNonObjectMember(String name) {
    assert(name != 'toString');
    assert(name != 'hashCode');
    assert(name != 'noSuchMethod');
    assert(name != 'runtimeType');
  }

  @override
  void _connect(
      NullabilityNode source, NullabilityNode destination, EdgeOrigin origin,
      {bool hard = false}) {
    var edge = _graph.connect(source, destination, origin,
        hard: hard, guards: _guards);
    if (origin is ExpressionChecks) {
      origin.edges.add(edge);
    }
  }

  void _createFlowAnalysis(AstNode node) {
    assert(_flowAnalysis == null);
    assert(_assignedVariables == null);
    _flowAnalysis =
        FlowAnalysis<Statement, Expression, VariableElement, DecoratedType>(
            const AnalyzerNodeOperations(),
            DecoratedTypeOperations(_typeSystem, _variables, _graph),
            AnalyzerFunctionBodyAccess(node is FunctionBody ? node : null));
    _assignedVariables = FlowAnalysisHelper.computeAssignedVariables(node);
  }

  DecoratedType _decorateUpperOrLowerBound(AstNode astNode, DartType type,
      DecoratedType left, DecoratedType right, bool isLUB,
      {NullabilityNode node}) {
    if (type.isDynamic || type.isVoid) {
      if (type.isDynamic) {
        _unimplemented(astNode, 'LUB/GLB with dynamic');
      }
      return DecoratedType(type, _graph.always);
    }
    node ??= isLUB
        ? NullabilityNode.forLUB(left.node, right.node)
        : _nullabilityNodeForGLB(astNode, left.node, right.node);
    if (type is InterfaceType) {
      if (type.typeArguments.isEmpty) {
        return DecoratedType(type, node);
      } else {
        var leftType = left.type;
        var rightType = right.type;
        if (leftType is InterfaceType && rightType is InterfaceType) {
          if (leftType.element != type.element ||
              rightType.element != type.element) {
            _unimplemented(astNode, 'LUB/GLB with substitution');
          }
          List<DecoratedType> newTypeArguments = [];
          for (int i = 0; i < type.typeArguments.length; i++) {
            newTypeArguments.add(_decorateUpperOrLowerBound(
                astNode,
                type.typeArguments[i],
                left.typeArguments[i],
                right.typeArguments[i],
                isLUB));
          }
          return DecoratedType(type, node, typeArguments: newTypeArguments);
        } else {
          _unimplemented(
              astNode,
              'LUB/GLB with unexpected types: ${leftType.runtimeType}/'
              '${rightType.runtimeType}');
        }
      }
    } else if (type is FunctionType) {
      var leftType = left.type;
      var rightType = right.type;
      if (leftType is FunctionType && rightType is FunctionType) {
        var returnType = _decorateUpperOrLowerBound(
            astNode, type.returnType, left.returnType, right.returnType, isLUB);
        List<DecoratedType> positionalParameters = [];
        Map<String, DecoratedType> namedParameters = {};
        int positionalParameterCount = 0;
        for (var parameter in type.parameters) {
          DecoratedType leftParameterType;
          DecoratedType rightParameterType;
          if (parameter.isNamed) {
            leftParameterType = left.namedParameters[parameter.name];
            rightParameterType = right.namedParameters[parameter.name];
          } else {
            leftParameterType =
                left.positionalParameters[positionalParameterCount];
            rightParameterType =
                right.positionalParameters[positionalParameterCount];
            positionalParameterCount++;
          }
          var decoratedParameterType = _decorateUpperOrLowerBound(astNode,
              parameter.type, leftParameterType, rightParameterType, !isLUB);
          if (parameter.isNamed) {
            namedParameters[parameter.name] = decoratedParameterType;
          } else {
            positionalParameters.add(decoratedParameterType);
          }
        }
        return DecoratedType(type, node,
            returnType: returnType,
            positionalParameters: positionalParameters,
            namedParameters: namedParameters);
      } else {
        _unimplemented(
            astNode,
            'LUB/GLB with unexpected types: ${leftType.runtimeType}/'
            '${rightType.runtimeType}');
      }
    } else if (type is TypeParameterType) {
      _unimplemented(astNode, 'LUB/GLB with type parameter types');
    }
    _unimplemented(astNode, '_decorateUpperOrLowerBound');
  }

  DecoratedType _fixNumericTypes(
      DecoratedType decoratedType, DartType undecoratedType) {
    if (decoratedType.type.isDartCoreNum && undecoratedType.isDartCoreInt) {
      // In a few cases the type computed by normal method lookup is `num`,
      // but special rules kick in to cause the type to be `int` instead.  If
      // that is the case, we need to fix up the decorated type.
      return DecoratedType(undecoratedType, decoratedType.node);
    } else {
      return decoratedType;
    }
  }

  @override
  DecoratedType _getTypeParameterTypeBound(DecoratedType type) {
    // TODO(paulberry): once we've wired up flow analysis, return promoted
    // bounds if applicable.
    return _variables
        .decoratedTypeParameterBound((type.type as TypeParameterType).element);
  }

  /// Creates the necessary constraint(s) for an assignment of the given
  /// [expression] to a destination whose type is [destinationType].
  ///
  /// Optionally, the caller may supply a [destinationExpression] instead of
  /// [destinationType].  In this case, then the type comes from visiting the
  /// destination expression.  If the destination expression refers to a local
  /// variable, we mark it as assigned in flow analysis at the proper time.
  DecoratedType _handleAssignment(Expression expression,
      {DecoratedType destinationType,
      Expression destinationExpression,
      bool canInsertChecks = true}) {
    assert(
        (destinationExpression == null) != (destinationType == null),
        'Either destinationExpression or destinationType should be supplied, '
        'but not both');
    VariableElement destinationLocalVariable;
    if (destinationType == null) {
      if (destinationExpression is SimpleIdentifier) {
        var element = destinationExpression.staticElement;
        if (element is VariableElement) {
          destinationLocalVariable = element;
        }
      }
      if (destinationLocalVariable != null) {
        destinationType = getOrComputeElementType(destinationLocalVariable);
      } else {
        destinationType = destinationExpression.accept(this);
      }
    }
    var sourceType = expression.accept(this);
    if (sourceType == null) {
      throw StateError('No type computed for ${expression.runtimeType} '
          '(${expression.toSource()}) offset=${expression.offset}');
    }
    ExpressionChecks expressionChecks;
    if (canInsertChecks && !sourceType.type.isDynamic) {
      expressionChecks = ExpressionChecks(expression.end);
      _variables.recordExpressionChecks(source, expression, expressionChecks);
    }
    _checkAssignment(expressionChecks,
        source: sourceType,
        destination: destinationType,
        hard: _postDominatedLocals.isReferenceInScope(expression));
    if (destinationLocalVariable != null) {
      _flowAnalysis.write(destinationLocalVariable);
    }
    return sourceType;
  }

  DecoratedType _handleCollectionElement(CollectionElement element) {
    if (element is Expression) {
      assert(_currentLiteralType != null);
      return _handleAssignment(element, destinationType: _currentLiteralType);
    } else {
      return element.accept(this);
    }
  }

  void _handleConstructorRedirection(
      FormalParameterList parameters, ConstructorName redirectedConstructor) {
    var callee = redirectedConstructor.staticElement;
    if (callee is ConstructorMember) {
      callee = (callee as ConstructorMember).baseElement;
    }
    var redirectedClass = callee.enclosingElement;
    var calleeType = _variables.decoratedElementType(callee);
    _handleInvocationArguments(
        redirectedConstructor,
        parameters.parameters,
        redirectedConstructor.type.typeArguments,
        calleeType,
        redirectedClass.typeParameters);
  }

  void _handleExecutableDeclaration(
      AstNode node,
      ExecutableElement declaredElement,
      NodeList<Annotation> metadata,
      TypeAnnotation returnType,
      FormalParameterList parameters,
      NodeList<ConstructorInitializer> initializers,
      FunctionBody body,
      ConstructorName redirectedConstructor) {
    assert(_currentFunctionType == null);
    metadata.accept(this);
    returnType?.accept(this);
    parameters?.accept(this);
    _currentFunctionType = _variables.decoratedElementType(declaredElement);
    _createFlowAnalysis(body);
    _addParametersToFlowAnalysis(parameters);
    // Push a scope of post-dominated declarations on the stack.
    _postDominatedLocals.pushScope(elements: declaredElement.parameters);
    try {
      initializers?.accept(this);
      body.accept(this);
      if (redirectedConstructor != null) {
        _handleConstructorRedirection(parameters, redirectedConstructor);
      }
      if (declaredElement is! ConstructorElement) {
        var classElement = declaredElement.enclosingElement as ClassElement;
        var origin = InheritanceOrigin(source, node.offset);
        for (var overriddenElement in _inheritanceManager.getOverridden(
                classElement.type,
                Name(classElement.library.source.uri, declaredElement.name)) ??
            const <ExecutableElement>[]) {
          if (overriddenElement is ExecutableMember) {
            var member = overriddenElement as ExecutableMember;
            overriddenElement = member.baseElement;
          }
          var overriddenClass =
              overriddenElement.enclosingElement as ClassElement;
          var decoratedOverriddenFunctionType =
              _variables.decoratedElementType(overriddenElement);
          var decoratedSupertype = _decoratedClassHierarchy
              .getDecoratedSupertype(classElement, overriddenClass);
          var substitution = decoratedSupertype.asSubstitution;
          var overriddenFunctionType =
              decoratedOverriddenFunctionType.substitute(substitution);
          if (returnType == null) {
            _unionDecoratedTypes(_currentFunctionType.returnType,
                overriddenFunctionType.returnType, origin);
          } else {
            _checkAssignment(origin,
                source: _currentFunctionType.returnType,
                destination: overriddenFunctionType.returnType,
                hard: true);
          }
          if (parameters != null) {
            int positionalParameterCount = 0;
            for (var parameter in parameters.parameters) {
              NormalFormalParameter normalParameter;
              if (parameter is NormalFormalParameter) {
                normalParameter = parameter;
              } else {
                normalParameter =
                    (parameter as DefaultFormalParameter).parameter;
              }
              DecoratedType currentParameterType;
              DecoratedType overriddenParameterType;
              if (parameter.isNamed) {
                var name = normalParameter.identifier.name;
                currentParameterType =
                    _currentFunctionType.namedParameters[name];
                overriddenParameterType =
                    overriddenFunctionType.namedParameters[name];
              } else {
                if (positionalParameterCount <
                    _currentFunctionType.positionalParameters.length) {
                  currentParameterType = _currentFunctionType
                      .positionalParameters[positionalParameterCount];
                }
                if (positionalParameterCount <
                    overriddenFunctionType.positionalParameters.length) {
                  overriddenParameterType = overriddenFunctionType
                      .positionalParameters[positionalParameterCount];
                }
                positionalParameterCount++;
              }
              if (overriddenParameterType != null) {
                if (_isUntypedParameter(normalParameter)) {
                  _unionDecoratedTypes(
                      overriddenParameterType, currentParameterType, origin);
                } else {
                  _checkAssignment(origin,
                      source: overriddenParameterType,
                      destination: currentParameterType,
                      hard: true);
                }
              }
            }
          }
        }
      }
    } finally {
      _flowAnalysis.finish();
      _flowAnalysis = null;
      _assignedVariables = null;
      _currentFunctionType = null;
      _postDominatedLocals.popScope();
    }
  }

  void _handleForLoopParts(AstNode node, ForLoopParts parts, AstNode body) {
    if (parts is ForParts) {
      if (parts is ForPartsWithDeclarations) {
        parts.variables?.accept(this);
      } else if (parts is ForPartsWithExpression) {
        parts.initialization?.accept(this);
      }
      _flowAnalysis.for_conditionBegin(_assignedVariables[node]);
      if (parts.condition != null) {
        _checkExpressionNotNull(parts.condition);
      }
      _flowAnalysis.for_bodyBegin(
          node is Statement ? node : null, parts.condition);
    } else if (parts is ForEachParts) {
      if (parts is ForEachPartsWithDeclaration) {
        _flowAnalysis.add(parts.loopVariable.declaredElement, assigned: true);
      }
      _checkExpressionNotNull(parts.iterable);
      _flowAnalysis.forEach_bodyBegin(_assignedVariables[node]);
    }

    // The condition may fail/iterable may be empty, so the body gets a new
    // post-dominator scope.
    _postDominatedLocals.doScoped(action: () {
      body.accept(this);

      if (parts is ForParts) {
        _flowAnalysis.for_updaterBegin();
        parts.updaters.accept(this);
        _flowAnalysis.for_end();
      } else {
        _flowAnalysis.forEach_end();
      }
    });
  }

  /// Creates the necessary constraint(s) for an [argumentList] when invoking an
  /// executable element whose type is [calleeType].
  ///
  /// Returns the decorated return type of the invocation, after any necessary
  /// substitutions.
  DecoratedType _handleInvocationArguments(
      AstNode node,
      Iterable<AstNode> arguments,
      TypeArgumentList typeArguments,
      DecoratedType calleeType,
      List<TypeParameterElement> constructorTypeParameters) {
    var typeFormals = constructorTypeParameters ?? calleeType.typeFormals;
    if (typeFormals.isNotEmpty) {
      if (typeArguments != null) {
        var argumentTypes = typeArguments.arguments
            .map((t) => _variables.decoratedTypeAnnotation(source, t))
            .toList();
        if (constructorTypeParameters != null) {
          calleeType = calleeType.substitute(
              Map<TypeParameterElement, DecoratedType>.fromIterables(
                  constructorTypeParameters, argumentTypes));
        } else {
          calleeType = calleeType.instantiate(argumentTypes);
        }
      } else {
        _unimplemented(node, 'Inferred type parameters in invocation');
      }
    }
    int i = 0;
    var suppliedNamedParameters = Set<String>();
    for (var argument in arguments) {
      String name;
      Expression expression;
      if (argument is NamedExpression) {
        name = argument.name.label.name;
        expression = argument.expression;
      } else if (argument is FormalParameter) {
        if (argument.isNamed) {
          name = argument.identifier.name;
        }
        expression = argument.identifier;
      } else {
        expression = argument as Expression;
      }
      DecoratedType parameterType;
      if (name != null) {
        parameterType = calleeType.namedParameters[name];
        if (parameterType == null) {
          // TODO(paulberry)
          _unimplemented(expression, 'Missing type for named parameter');
        }
        suppliedNamedParameters.add(name);
      } else {
        if (calleeType.positionalParameters.length <= i) {
          // TODO(paulberry)
          _unimplemented(node, 'Missing positional parameter at $i');
        }
        parameterType = calleeType.positionalParameters[i++];
      }
      _handleAssignment(expression, destinationType: parameterType);
    }
    // Any parameters not supplied must be optional.
    for (var entry in calleeType.namedParameters.entries) {
      if (suppliedNamedParameters.contains(entry.key)) continue;
      entry.value.node.recordNamedParameterNotSupplied(_guards, _graph,
          NamedParameterNotSuppliedOrigin(source, node.offset));
    }
    return calleeType.returnType;
  }

  DecoratedType _handlePropertyAccess(
      Expression node, Expression target, SimpleIdentifier propertyName) {
    DecoratedType targetType;
    bool isConditional = _isConditionalExpression(node);
    if (isConditional) {
      targetType = target.accept(this);
    } else {
      _checkNonObjectMember(propertyName.name); // TODO(paulberry)
      targetType = _checkExpressionNotNull(target);
    }
    var callee = propertyName.staticElement;
    if (callee == null) {
      // TODO(paulberry)
      _unimplemented(node, 'Unresolved property access');
    }
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    // TODO(paulberry): substitute if necessary
    if (propertyName.inSetterContext()) {
      if (isConditional) {
        _conditionalNodes[node] = targetType.node;
      }
      return calleeType.positionalParameters[0];
    } else {
      var expressionType = callee is PropertyAccessorElement
          ? calleeType.returnType
          : calleeType;
      if (isConditional) {
        expressionType = expressionType.withNode(
            NullabilityNode.forLUB(targetType.node, expressionType.node));
        _variables.recordDecoratedExpressionType(node, expressionType);
      }
      return expressionType;
    }
  }

  bool _isConditionalExpression(Expression expression) {
    Token token;
    if (expression is MethodInvocation) {
      token = expression.operator;
      if (token == null) return false;
    } else if (expression is PropertyAccess) {
      token = expression.operator;
    } else {
      return false;
    }
    switch (token.type) {
      case TokenType.PERIOD:
      case TokenType.PERIOD_PERIOD:
        return false;
      case TokenType.QUESTION_PERIOD:
        return true;
      default:
        // TODO(paulberry)
        _unimplemented(
            expression, 'Conditional expression with operator ${token.lexeme}');
    }
  }

  bool _isUntypedParameter(NormalFormalParameter parameter) {
    if (parameter is SimpleFormalParameter) {
      return parameter.type == null;
    } else if (parameter is FieldFormalParameter) {
      return parameter.type == null;
    } else {
      return false;
    }
  }

  NullabilityNode _nullabilityNodeForGLB(
      AstNode astNode, NullabilityNode leftNode, NullabilityNode rightNode) {
    var node = NullabilityNode.forGLB();
    var origin = GreatestLowerBoundOrigin(source, astNode.offset);
    _graph.connect(leftNode, node, origin, guards: [rightNode]);
    _graph.connect(node, leftNode, origin);
    _graph.connect(node, rightNode, origin);
    return node;
  }

  @alwaysThrows
  void _unimplemented(AstNode node, String message) {
    CompilationUnit unit = node.root as CompilationUnit;
    StringBuffer buffer = StringBuffer();
    buffer.write(message);
    buffer.write(' in "');
    buffer.write(node.toSource());
    buffer.write('" on line ');
    buffer.write(unit.lineInfo.getLocation(node.offset).lineNumber);
    buffer.write(' of "');
    buffer.write(unit.declaredElement.source.fullName);
    buffer.write('"');
    throw UnimplementedError(buffer.toString());
  }

  void _unionDecoratedTypeParameters(
      DecoratedType x, DecoratedType y, EdgeOrigin origin) {
    for (int i = 0;
        i < x.positionalParameters.length && i < y.positionalParameters.length;
        i++) {
      _unionDecoratedTypes(
          x.positionalParameters[i], y.positionalParameters[i], origin);
    }
    for (var entry in x.namedParameters.entries) {
      var superParameterType = y.namedParameters[entry.key];
      if (superParameterType != null) {
        _unionDecoratedTypes(entry.value, y.namedParameters[entry.key], origin);
      }
    }
  }

  void _unionDecoratedTypes(
      DecoratedType x, DecoratedType y, EdgeOrigin origin) {
    _graph.union(x.node, y.node, origin);
    _unionDecoratedTypeParameters(x, y, origin);
    for (int i = 0;
        i < x.typeArguments.length && i < y.typeArguments.length;
        i++) {
      _unionDecoratedTypes(x.typeArguments[i], y.typeArguments[i], origin);
    }
    if (x.returnType != null && y.returnType != null) {
      _unionDecoratedTypes(x.returnType, y.returnType, origin);
    }
  }
}

/// Implementation of [_checkAssignment] for [EdgeBuilder].
///
/// This has been moved to its own mixin to allow it to be more easily unit
/// tested.
mixin _AssignmentChecker {
  DecoratedClassHierarchy get _decoratedClassHierarchy;

  NullabilityGraph get _graph;

  TypeSystem get _typeSystem;

  /// Creates the necessary constraint(s) for an assignment from [source] to
  /// [destination].  [origin] should be used as the origin for any edges
  /// created.  [hard] indicates whether a hard edge should be created.
  void _checkAssignment(EdgeOrigin origin,
      {@required DecoratedType source,
      @required DecoratedType destination,
      @required bool hard}) {
    _connect(source.node, destination.node, origin, hard: hard);
    var sourceType = source.type;
    var destinationType = destination.type;
    if (sourceType.isBottom || sourceType.isDartCoreNull) {
      // No further edges need to be created, since all types are trivially
      // supertypes of bottom (and of Null, in the pre-migration world).
    } else if (destinationType.isDynamic || destinationType.isVoid) {
      // No further edges need to be created, since all types are trivially
      // subtypes of dynamic (and of void, since void is treated as equivalent
      // to dynamic for subtyping purposes).
    } else if (sourceType is TypeParameterType) {
      if (destinationType is TypeParameterType) {
        // No further edges need to be created, since type parameter types
        // aren't made up of other types.
      } else {
        // Effectively this is an assignment from the type parameter's bound to
        // the destination type.
        _checkAssignment(origin,
            source: _getTypeParameterTypeBound(source),
            destination: destination,
            hard: false);
        return;
      }
    } else if (destinationType is TypeParameterType) {
      // Effectively this is a downcast assignment from the source type to the
      // type parameter's bound.
      _checkAssignment(origin,
          source: source,
          destination:
              _getTypeParameterTypeBound(destination).withNode(_graph.always),
          hard: false);
    } else if (sourceType is InterfaceType &&
        destinationType is InterfaceType) {
      if (_typeSystem.isSubtypeOf(sourceType, destinationType)) {
        // Ordinary (upcast) assignment.  No cast necessary.
        var rewrittenSource = _decoratedClassHierarchy.asInstanceOf(
            source, destinationType.element);
        assert(rewrittenSource.typeArguments.length ==
            destination.typeArguments.length);
        for (int i = 0; i < rewrittenSource.typeArguments.length; i++) {
          _checkAssignment(origin,
              source: rewrittenSource.typeArguments[i],
              destination: destination.typeArguments[i],
              hard: false);
        }
      } else if (_typeSystem.isSubtypeOf(destinationType, sourceType)) {
        // Implicit downcast assignment.
        // TODO(paulberry): the migration tool should insert a cast.
        var rewrittenDestination = _decoratedClassHierarchy.asInstanceOf(
            destination, sourceType.element);
        assert(rewrittenDestination.typeArguments.length ==
            source.typeArguments.length);
        for (int i = 0; i < rewrittenDestination.typeArguments.length; i++) {
          _checkAssignment(origin,
              source: source.typeArguments[i],
              destination: rewrittenDestination.typeArguments[i],
              hard: false);
        }
      } else {
        // This should never arise for correct code; if it does arise, recover
        // from the error by just not creating any additional edges.
      }
    } else if (sourceType is FunctionType && destinationType is FunctionType) {
      _checkAssignment(origin,
          source: source.returnType,
          destination: destination.returnType,
          hard: false);
      if (source.typeArguments.isNotEmpty ||
          destination.typeArguments.isNotEmpty) {
        throw UnimplementedError('TODO(paulberry)');
      }
      for (int i = 0;
          i < source.positionalParameters.length &&
              i < destination.positionalParameters.length;
          i++) {
        // Note: source and destination are swapped due to contravariance.
        _checkAssignment(origin,
            source: destination.positionalParameters[i],
            destination: source.positionalParameters[i],
            hard: false);
      }
      for (var entry in destination.namedParameters.entries) {
        // Note: source and destination are swapped due to contravariance.
        _checkAssignment(origin,
            source: entry.value,
            destination: source.namedParameters[entry.key],
            hard: false);
      }
    } else if (destinationType.isDynamic || sourceType.isDynamic) {
      // ok; nothing further to do.
    } else {
      throw '$destination <= $source'; // TODO(paulberry)
    }
  }

  void _connect(
      NullabilityNode source, NullabilityNode destination, EdgeOrigin origin,
      {bool hard = false});

  /// Given a [type] representing a type parameter, retrieves the type's bound.
  DecoratedType _getTypeParameterTypeBound(DecoratedType type);
}

/// Information about a binary expression whose boolean value could possibly
/// affect nullability analysis.
class _ConditionInfo {
  /// The [expression] of interest.
  final Expression condition;

  /// Indicates whether [condition] is pure (free from side effects).
  ///
  /// For example, a condition like `x == null` is pure (assuming `x` is a local
  /// variable or static variable), because evaluating it has no user-visible
  /// effect other than returning a boolean value.
  final bool isPure;

  /// Indicates whether the intents postdominate the intent node declarations.
  final bool postDominatingIntent;

  /// If not `null`, the [NullabilityNode] that would need to be nullable in
  /// order for [condition] to evaluate to `true`.
  final NullabilityNode trueGuard;

  /// If not `null`, the [NullabilityNode] that would need to be nullable in
  /// order for [condition] to evaluate to `false`.
  final NullabilityNode falseGuard;

  /// If not `null`, the [NullabilityNode] that should be asserted to have
  /// non-null intent if [condition] is asserted to be `true`.
  final NullabilityNode trueDemonstratesNonNullIntent;

  /// If not `null`, the [NullabilityNode] that should be asserted to have
  /// non-null intent if [condition] is asserted to be `false`.
  final NullabilityNode falseDemonstratesNonNullIntent;

  _ConditionInfo(this.condition,
      {@required this.isPure,
      this.postDominatingIntent,
      this.trueGuard,
      this.falseGuard,
      this.trueDemonstratesNonNullIntent,
      this.falseDemonstratesNonNullIntent});

  /// Returns a new [_ConditionInfo] describing the boolean "not" of `this`.
  _ConditionInfo not(Expression condition) => _ConditionInfo(condition,
      isPure: isPure,
      postDominatingIntent: postDominatingIntent,
      trueGuard: falseGuard,
      falseGuard: trueGuard,
      trueDemonstratesNonNullIntent: falseDemonstratesNonNullIntent,
      falseDemonstratesNonNullIntent: trueDemonstratesNonNullIntent);
}

/// A [ScopedSet] specific to the [Element]s of locals/parameters.
///
/// Contains helpers for dealing with expressions as if they were elements.
class _ScopedLocalSet extends ScopedSet<Element> {
  bool isReferenceInScope(Expression expression) {
    expression = expression.unParenthesized;
    if (expression is SimpleIdentifier) {
      var element = expression.staticElement;
      return isInScope(element);
    }
    return false;
  }

  void removeReferenceFromAllScopes(Expression expression) {
    expression = expression.unParenthesized;
    if (expression is SimpleIdentifier) {
      var element = expression.staticElement;
      removeFromAllScopes(element);
    }
  }
}
