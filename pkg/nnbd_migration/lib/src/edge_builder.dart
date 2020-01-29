// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/error/best_practices_verifier.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/utilities/completeness_tracker.dart';
import 'package:nnbd_migration/src/utilities/permissive_mode.dart';
import 'package:nnbd_migration/src/utilities/resolution_utils.dart';
import 'package:nnbd_migration/src/utilities/scoped_set.dart';

import 'decorated_type_operations.dart';

/// A potentially reversible decision is that downcasts and sidecasts should
/// assume non-nullability. This could be changed such that we assume the
/// widest type, or the narrowest type. For now we assume non-nullability, but
/// have a flag to isolate that work.
const _assumeNonNullabilityInCasts = true;

/// Test class mixing in _AssignmentChecker, to allow [checkAssignment] to be
/// more easily unit tested.
@visibleForTesting
class AssignmentCheckerForTesting extends Object with _AssignmentChecker {
  @override
  final TypeSystem _typeSystem;

  @override
  final TypeProvider typeProvider;

  final NullabilityGraph _graph;

  /// Tests should fill in this map with the bounds of any type parameters being
  /// tested.
  final Map<TypeParameterElement, DecoratedType> bounds = {};

  @override
  final DecoratedClassHierarchy _decoratedClassHierarchy;

  AssignmentCheckerForTesting(this._typeSystem, this.typeProvider, this._graph,
      this._decoratedClassHierarchy);

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
      {bool hard = false, bool checkable = true}) {
    _graph.connect(source, destination, origin,
        hard: hard, checkable: checkable);
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
        CompletenessTracker<DecoratedType>,
        ResolutionUtils {
  final TypeSystem _typeSystem;

  final InheritanceManager3 _inheritanceManager;

  /// The repository of constraint variables and decorated types (from a
  /// previous pass over the source code).
  final VariableRepository _variables;

  final NullabilityMigrationListener /*?*/ listener;

  final NullabilityMigrationInstrumentation /*?*/ instrumentation;

  final NullabilityGraph _graph;

  TypeProvider typeProvider;

  @override
  final Source source;

  @override
  final DecoratedClassHierarchy _decoratedClassHierarchy;

  /// If we are visiting a function body or initializer, instance of flow
  /// analysis.  Otherwise `null`.
  FlowAnalysis<AstNode, Statement, Expression, PromotableElement, DecoratedType>
      _flowAnalysis;

  /// If we are visiting a function body or initializer, assigned variable
  /// information  used in flow analysis.  Otherwise `null`.
  AssignedVariables<AstNode, PromotableElement> _assignedVariables;

  /// The [DecoratedType] of the innermost function or method being visited, or
  /// `null` if the visitor is not inside any function or method.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// return statements.
  DecoratedType _currentFunctionType;

  /// The [ClassElement] or [ExtensionElement] of the current class or extension
  /// being visited, or null.
  Element _currentClassOrExtension;

  /// The [DecoratedType] of the innermost list or set literal being visited, or
  /// `null` if the visitor is not inside any list or set.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// ui as code elements.
  DecoratedType _currentLiteralElementType;

  /// The key [DecoratedType] of the innermost map literal being visited, or
  /// `null` if the visitor is not inside any map.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// ui as code elements.
  DecoratedType _currentMapKeyType;

  /// The value [DecoratedType] of the innermost map literal being visited, or
  /// `null` if the visitor is not inside any map.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// ui as code elements.
  DecoratedType _currentMapValueType;

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

  /// If we are visiting a cascade expression, the decorated type of the target
  /// of the cascade.  Otherwise `null`.
  DecoratedType _currentCascadeTargetType;

  /// While visiting a class declaration, set of class fields that lack
  /// initializers at their declaration sites.
  Set<FieldElement> _fieldsNotInitializedAtDeclaration;

  /// While visiting a constructor, set of class fields that lack initializers
  /// at their declaration sites *and* for which we haven't yet found an
  /// initializer in the constructor declaration.
  Set<FieldElement> _fieldsNotInitializedByConstructor;

  EdgeBuilder(this.typeProvider, this._typeSystem, this._variables, this._graph,
      this.source, this.listener, this._decoratedClassHierarchy,
      {this.instrumentation})
      : _inheritanceManager = InheritanceManager3();

  /// Gets the decorated type of [element] from [_variables], performing any
  /// necessary substitutions.
  DecoratedType getOrComputeElementType(Element element,
      {DecoratedType targetType}) {
    Map<TypeParameterElement, DecoratedType> substitution;
    Element baseElement = element.declaration;
    if (targetType != null) {
      var enclosingElement = baseElement.enclosingElement;
      if (enclosingElement is ClassElement) {
        if (enclosingElement.typeParameters.isNotEmpty) {
          substitution = _decoratedClassHierarchy
              .asInstanceOf(targetType, enclosingElement)
              .asSubstitution;
        }
      } else {
        assert(enclosingElement is ExtensionElement);
        final extensionElement = enclosingElement as ExtensionElement;
        final extendedType = extensionElement.extendedType;
        if (extendedType is InterfaceType) {
          if (extensionElement.typeParameters.isNotEmpty) {
            substitution = _decoratedClassHierarchy
                .asInstanceOf(targetType, extendedType.element)
                .asSubstitution;
          }
        } else {
          // TODO(srawlins): Handle generic typedef. Others?
          _unimplemented(
              null, 'Extension on $extendedType (${extendedType.runtimeType}');
        }
      }
    }
    DecoratedType decoratedBaseType;
    if (baseElement is PropertyAccessorElement &&
        baseElement.isSynthetic &&
        !baseElement.variable.isSynthetic) {
      var variable = baseElement.variable;
      var decoratedElementType = _variables.decoratedElementType(variable);
      if (baseElement.isGetter) {
        decoratedBaseType = DecoratedType(
            baseElement.type, NullabilityNode.forInferredType(),
            returnType: decoratedElementType);
      } else {
        assert(baseElement.isSetter);
        decoratedBaseType = DecoratedType(
            baseElement.type, NullabilityNode.forInferredType(),
            positionalParameters: [decoratedElementType],
            returnType: DecoratedType(
                VoidTypeImpl.instance, NullabilityNode.forInferredType()));
      }
    } else {
      decoratedBaseType = _variables.decoratedElementType(baseElement);
    }
    if (substitution != null) {
      return decoratedBaseType.substitute(substitution);
    } else {
      return decoratedBaseType;
    }
  }

  @override
  DecoratedType visitAsExpression(AsExpression node) {
    if (BestPracticesVerifier.isUnnecessaryCast(node, _typeSystem)) {
      _variables.recordUnnecessaryCast(source, node);
    }
    node.type.accept(this);
    final typeNode = _variables.decoratedTypeAnnotation(source, node.type);
    _handleAssignment(node.expression, destinationType: typeNode);
    _flowAnalysis.asExpression_end(node.expression, typeNode);
    return typeNode;
  }

  @override
  DecoratedType visitAssertInitializer(AssertInitializer node) {
    _flowAnalysis.assert_begin();
    _checkExpressionNotNull(node.condition);
    if (identical(_conditionInfo?.condition, node.condition)) {
      var intentNode = _conditionInfo.trueDemonstratesNonNullIntent;
      if (intentNode != null && _conditionInfo.postDominatingIntent) {
        _graph.makeNonNullable(_conditionInfo.trueDemonstratesNonNullIntent,
            NonNullAssertionOrigin(source, node));
      }
    }
    _flowAnalysis.assert_afterCondition(node.condition);
    node.message?.accept(this);
    _flowAnalysis.assert_end();
    return null;
  }

  @override
  DecoratedType visitAssertStatement(AssertStatement node) {
    _flowAnalysis.assert_begin();
    _checkExpressionNotNull(node.condition);
    if (identical(_conditionInfo?.condition, node.condition)) {
      var intentNode = _conditionInfo.trueDemonstratesNonNullIntent;
      if (intentNode != null && _conditionInfo.postDominatingIntent) {
        _graph.makeNonNullable(_conditionInfo.trueDemonstratesNonNullIntent,
            NonNullAssertionOrigin(source, node));
      }
    }
    _flowAnalysis.assert_afterCondition(node.condition);
    node.message?.accept(this);
    _flowAnalysis.assert_end();
    return null;
  }

  @override
  DecoratedType visitAssignmentExpression(AssignmentExpression node) {
    bool isQuestionAssign = false;
    bool isCompound = false;
    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ) {
      isQuestionAssign = true;
    } else if (node.operator.type != TokenType.EQ) {
      isCompound = true;
    }
    var expressionType = _handleAssignment(node.rightHandSide,
        destinationExpression: node.leftHandSide,
        compoundOperatorInfo: isCompound ? node : null,
        questionAssignNode: isQuestionAssign ? node : null);
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
    var leftOperand = node.leftOperand;
    var rightOperand = node.rightOperand;
    if (operatorType == TokenType.EQ_EQ || operatorType == TokenType.BANG_EQ) {
      var leftType = leftOperand.accept(this);
      _flowAnalysis.equalityOp_rightBegin(leftOperand);
      var rightType = rightOperand.accept(this);
      bool notEqual = operatorType == TokenType.BANG_EQ;
      _flowAnalysis.equalityOp_end(node, rightOperand, notEqual: notEqual);

      void buildNullConditionInfo(NullLiteral nullLiteral,
          Expression otherOperand, NullabilityNode otherNode) {
        assert(nullLiteral != otherOperand);
        // TODO(paulberry): only set falseChecksNonNull in unconditional
        // control flow
        // TODO(paulberry): figure out what the rules for isPure should be.
        bool isPure = otherOperand is SimpleIdentifier;
        var conditionInfo = _ConditionInfo(node,
            isPure: isPure,
            postDominatingIntent:
                _postDominatedLocals.isReferenceInScope(otherOperand),
            trueGuard: otherNode,
            falseDemonstratesNonNullIntent: otherNode);
        _conditionInfo = notEqual ? conditionInfo.not(node) : conditionInfo;
      }

      if (rightOperand is NullLiteral) {
        buildNullConditionInfo(rightOperand, leftOperand, leftType.node);
      } else if (leftOperand is NullLiteral) {
        buildNullConditionInfo(leftOperand, rightOperand, rightType.node);
      }

      return _makeNonNullableBoolType(node);
    } else if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
        operatorType == TokenType.BAR_BAR) {
      bool isAnd = operatorType == TokenType.AMPERSAND_AMPERSAND;
      _checkExpressionNotNull(leftOperand);
      _flowAnalysis.logicalBinaryOp_rightBegin(node.leftOperand, isAnd: isAnd);
      _postDominatedLocals.doScoped(
          action: () => _checkExpressionNotNull(rightOperand));
      _flowAnalysis.logicalBinaryOp_end(node, rightOperand, isAnd: isAnd);
      return _makeNonNullableBoolType(node);
    } else if (operatorType == TokenType.QUESTION_QUESTION) {
      DecoratedType expressionType;
      var leftType = leftOperand.accept(this);
      _flowAnalysis.ifNullExpression_rightBegin(node.leftOperand);
      try {
        _guards.add(leftType.node);
        DecoratedType rightType;
        _postDominatedLocals.doScoped(action: () {
          rightType = rightOperand.accept(this);
        });
        var ifNullNode = NullabilityNode.forIfNotNull();
        expressionType = _decorateUpperOrLowerBound(
            node, node.staticType, leftType, rightType, true,
            node: ifNullNode);
        _connect(
            rightType.node, expressionType.node, IfNullOrigin(source, node));
      } finally {
        _flowAnalysis.ifNullExpression_end();
        _guards.removeLast();
      }
      _variables.recordDecoratedExpressionType(node, expressionType);
      return expressionType;
    } else if (operatorType.isUserDefinableOperator) {
      var targetType = _checkExpressionNotNull(leftOperand);
      var callee = node.staticElement;
      if (callee == null) {
        rightOperand.accept(this);
        return _makeNullableDynamicType(node);
      } else {
        var calleeType =
            getOrComputeElementType(callee, targetType: targetType);
        assert(calleeType.positionalParameters.length > 0); // TODO(paulberry)
        _handleAssignment(rightOperand,
            destinationType: calleeType.positionalParameters[0]);
        return _fixNumericTypes(calleeType.returnType, node.staticType);
      }
    } else {
      // TODO(paulberry)
      leftOperand.accept(this);
      rightOperand.accept(this);
      _unimplemented(
          node, 'Binary expression with operator ${node.operator.lexeme}');
    }
  }

  @override
  DecoratedType visitBooleanLiteral(BooleanLiteral node) {
    _flowAnalysis.booleanLiteral(node, node.value);
    return _makeNonNullLiteralType(node);
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
    var oldCascadeTargetType = _currentCascadeTargetType;
    try {
      _currentCascadeTargetType = _checkExpressionNotNull(node.target);
      node.cascadeSections.accept(this);
      return _currentCascadeTargetType;
    } finally {
      _currentCascadeTargetType = oldCascadeTargetType;
    }
  }

  @override
  DecoratedType visitCatchClause(CatchClause node) {
    _flowAnalysis.tryCatchStatement_catchBegin(
        node.exceptionParameter?.staticElement as PromotableElement,
        node.stackTraceParameter?.staticElement as PromotableElement);
    node.exceptionType?.accept(this);
    // The catch clause may not execute, so create a new scope for
    // post-dominators.
    _postDominatedLocals.doScoped(action: () => node.body.accept(this));
    _flowAnalysis.tryCatchStatement_catchEnd();
    return null;
  }

  @override
  DecoratedType visitClassDeclaration(ClassDeclaration node) {
    visitClassOrMixinOrExtensionDeclaration(node);
    node.extendsClause?.accept(this);
    node.implementsClause?.accept(this);
    node.withClause?.accept(this);
    node.typeParameters?.accept(this);
    return null;
  }

  DecoratedType visitClassOrMixinOrExtensionDeclaration(
      CompilationUnitMember node) {
    assert(node is ClassOrMixinDeclaration || node is ExtensionDeclaration);
    try {
      _currentClassOrExtension = node.declaredElement;
      var members = node is ClassOrMixinDeclaration
          ? node.members
          : (node as ExtensionDeclaration).members;

      _fieldsNotInitializedAtDeclaration = {
        for (var member in members)
          if (member is FieldDeclaration)
            for (var field in member.fields.variables)
              if (field.initializer == null)
                field.declaredElement as FieldElement
      };
      if (_currentClassOrExtension is ClassElement &&
          (_currentClassOrExtension as ClassElement)
                  .unnamedConstructor
                  ?.isSynthetic ==
              true) {
        _handleUninitializedFields(node, _fieldsNotInitializedAtDeclaration);
      }
      node.metadata.accept(this);
      members.accept(this);
      _fieldsNotInitializedAtDeclaration = null;
    } finally {
      _currentClassOrExtension = null;
    }
    return null;
  }

  @override
  DecoratedType visitClassTypeAlias(ClassTypeAlias node) {
    node.superclass.accept(this);
    node.implementsClause?.accept(this);
    node.withClause?.accept(this);
    var classElement = node.declaredElement;
    var supertype = classElement.supertype;
    var superElement = supertype.element;
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
      var origin = ImplicitMixinSuperCallOrigin(source, node);
      _linkDecoratedTypeParameters(
          constructorDecoratedType, superConstructorDecoratedType, origin,
          isUnion: true);
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
    _fieldsNotInitializedByConstructor =
        _fieldsNotInitializedAtDeclaration.toSet();
    node.redirectedConstructor?.type?.typeArguments?.accept(this);
    _handleExecutableDeclaration(
        node,
        node.declaredElement,
        node.metadata,
        null,
        node.parameters,
        node.initializers,
        node.body,
        node.redirectedConstructor);
    _fieldsNotInitializedByConstructor = null;
    return null;
  }

  @override
  DecoratedType visitConstructorFieldInitializer(
      ConstructorFieldInitializer node) {
    _fieldsNotInitializedByConstructor.remove(node.fieldName.staticElement);
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
        _graph.makeNullable(getOrComputeElementType(node.declaredElement).node,
            OptionalFormalParameterOrigin(source, node));
      }
    } else {
      _handleAssignment(defaultValue,
          destinationType: getOrComputeElementType(node.declaredElement),
          fromDefaultValue: true);
    }
    return null;
  }

  @override
  DecoratedType visitDoStatement(DoStatement node) {
    _flowAnalysis.doStatement_bodyBegin(node);
    node.body.accept(this);
    _flowAnalysis.doStatement_conditionBegin();
    _checkExpressionNotNull(node.condition);
    _flowAnalysis.doStatement_end(node.condition);
    return null;
  }

  @override
  DecoratedType visitDoubleLiteral(DoubleLiteral node) {
    return _makeNonNullLiteralType(node);
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
        destinationType: _currentFunctionType.returnType,
        wrapFuture: node.isAsynchronous);
    return null;
  }

  DecoratedType visitExtensionDeclaration(ExtensionDeclaration node) {
    visitClassOrMixinOrExtensionDeclaration(node);
    node.extendedType.accept(this);
    return null;
  }

  @override
  DecoratedType visitFieldFormalParameter(FieldFormalParameter node) {
    node.metadata.accept(this);
    node.parameters?.accept(this);
    var parameterElement = node.declaredElement as FieldFormalParameterElement;
    var parameterType = _variables.decoratedElementType(parameterElement);
    var field = parameterElement.field;
    _fieldsNotInitializedByConstructor.remove(field);
    var fieldType = _variables.decoratedElementType(field);
    var origin = FieldFormalParameterOrigin(source, node);
    if (node.type == null) {
      _linkDecoratedTypes(parameterType, fieldType, origin, isUnion: true);
    } else {
      node.type.accept(this);
      _checkAssignment(origin,
          source: parameterType, destination: fieldType, hard: true);
    }

    return null;
  }

  @override
  DecoratedType visitForElement(ForElement node) {
    _handleForLoopParts(node, node.forLoopParts, node.body,
        (body) => _handleCollectionElement(body as CollectionElement));
    return null;
  }

  @override
  DecoratedType visitForStatement(ForStatement node) {
    _handleForLoopParts(
        node, node.forLoopParts, node.body, (body) => body.accept(this));
    return null;
  }

  @override
  DecoratedType visitFunctionDeclaration(FunctionDeclaration node) {
    node.metadata.accept(this);
    node.returnType?.accept(this);
    if (_flowAnalysis != null) {
      // This is a local function.
      _flowAnalysis.functionExpression_begin(node);
      node.functionExpression.accept(this);
      _flowAnalysis.functionExpression_end();
    } else {
      _createFlowAnalysis(node, node.functionExpression.parameters);
      // Initialize a new postDominator scope that contains only the parameters.
      try {
        node.functionExpression.accept(this);
        _flowAnalysis.finish();
      } finally {
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
    node.typeParameters?.accept(this);
    if (node.parent is! FunctionDeclaration) {
      _flowAnalysis.functionExpression_begin(node);
    }
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
      if (node.parent is! FunctionDeclaration) {
        _flowAnalysis.functionExpression_end();
      }
      _currentFunctionType = previousFunctionType;
    }
  }

  @override
  DecoratedType visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    final argumentList = node.argumentList;
    final typeArguments = node.typeArguments;
    typeArguments?.accept(this);
    DecoratedType calleeType = _checkExpressionNotNull(node.function);
    if (calleeType.type is FunctionType) {
      return _handleInvocationArguments(node, argumentList.arguments,
          typeArguments, node.typeArgumentTypes, calleeType, null,
          invokeType: node.staticInvokeType);
    } else {
      // Invocation of type `dynamic` or `Function`.
      argumentList.accept(this);
      return _makeNullableDynamicType(node);
    }
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
    var target = node.target;
    if (node.isCascaded) {
      targetType = _currentCascadeTargetType;
    } else if (target != null) {
      targetType = _checkExpressionNotNull(target);
    }
    var callee = node.staticElement;
    if (callee == null) {
      // Dynamic dispatch.  The return type is `dynamic`.
      // TODO(paulberry): would it be better to assume a return type of `Never`
      // so that we don't unnecessarily propagate nullabilities everywhere?
      return _makeNullableDynamicType(node);
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
    Iterable<DartType> typeArgumentTypes;
    List<DecoratedType> decoratedTypeArguments;
    var typeArguments = node.constructorName.type.typeArguments;
    if (typeArguments != null) {
      typeArguments.accept(this);
      typeArgumentTypes = typeArguments.arguments.map((t) => t.type);
      decoratedTypeArguments = typeArguments.arguments
          .map((t) => _variables.decoratedTypeAnnotation(source, t))
          .toList();
    } else {
      var staticType = node.staticType;
      if (staticType is InterfaceType) {
        typeArgumentTypes = staticType.typeArguments;
        decoratedTypeArguments = typeArgumentTypes
            .map((t) => DecoratedType.forImplicitType(typeProvider, t, _graph,
                offset: node.offset))
            .toList();
        instrumentation?.implicitTypeArguments(
            source, node, decoratedTypeArguments);
      } else {
        // Note: this could happen if the code being migrated has errors.
        typeArgumentTypes = const [];
        decoratedTypeArguments = const [];
      }
    }

    if (node.staticType.isDartCoreList &&
        callee.name == '' &&
        node.argumentList.arguments.length == 1) {
      _graph.connect(_graph.always, decoratedTypeArguments[0].node,
          ListLengthConstructorOrigin(source, node));
    }

    var nullabilityNode = NullabilityNode.forInferredType(offset: node.offset);
    _graph.makeNonNullable(
        nullabilityNode, InstanceCreationOrigin(source, node));
    var createdType = DecoratedType(node.staticType, nullabilityNode,
        typeArguments: decoratedTypeArguments);
    var calleeType = getOrComputeElementType(callee, targetType: createdType);
    for (var i = 0; i < decoratedTypeArguments.length; ++i) {
      _checkAssignment(null,
          source: decoratedTypeArguments[i],
          destination:
              _variables.decoratedTypeParameterBound(typeParameters[i]),
          hard: true);
    }
    _handleInvocationArguments(node, node.argumentList.arguments, typeArguments,
        typeArgumentTypes, calleeType, typeParameters);
    return createdType;
  }

  @override
  DecoratedType visitIntegerLiteral(IntegerLiteral node) {
    return _makeNonNullLiteralType(node);
  }

  @override
  DecoratedType visitIsExpression(IsExpression node) {
    var type = node.type;
    type.accept(this);
    var decoratedType = _variables.decoratedTypeAnnotation(source, type);
    if (type is NamedType) {
      // The main type of the is check historically could not be nullable.
      // Making it nullable could change runtime behavior.
      _graph.makeNonNullable(
          decoratedType.node, IsCheckMainTypeOrigin(source, type));
      if (!_assumeNonNullabilityInCasts) {
        // TODO(mfairhurst): wire this to handleDowncast if we do not assume
        // nullability.
        assert(false);
      }
    } else if (type is GenericFunctionType) {
      // TODO(brianwilkerson)
      _unimplemented(node, 'Is expression with GenericFunctionType');
    }
    var expression = node.expression;
    expression.accept(this);
    _flowAnalysis.isExpression_end(
        node, expression, node.notOperator != null, decoratedType);
    return _makeNonNullableBoolType(node);
  }

  @override
  DecoratedType visitLabel(Label node) {
    // Labels are identifiers but they don't have types so we don't need to
    // visit them directly.
    return null;
  }

  @override
  DecoratedType visitLibraryDirective(LibraryDirective node) {
    // skip directives, but not their metadata
    node.metadata.accept(this);
    return null;
  }

  @override
  DecoratedType visitListLiteral(ListLiteral node) {
    final previousLiteralType = _currentLiteralElementType;
    try {
      var listType = node.staticType as InterfaceType;
      if (node.typeArguments == null) {
        var elementType = DecoratedType.forImplicitType(
            typeProvider, listType.typeArguments[0], _graph,
            offset: node.offset);
        instrumentation?.implicitTypeArguments(source, node, [elementType]);
        _currentLiteralElementType = elementType;
      } else {
        node.typeArguments.accept(this);
        _currentLiteralElementType = _variables.decoratedTypeAnnotation(
            source, node.typeArguments.arguments[0]);
      }
      node.elements.forEach(_handleCollectionElement);
      return _makeNonNullLiteralType(node,
          typeArguments: [_currentLiteralElementType]);
    } finally {
      _currentLiteralElementType = previousLiteralType;
    }
  }

  @override
  DecoratedType visitMapLiteralEntry(MapLiteralEntry node) {
    assert(_currentMapKeyType != null);
    assert(_currentMapValueType != null);
    _handleAssignment(node.key, destinationType: _currentMapKeyType);
    _handleAssignment(node.value, destinationType: _currentMapValueType);
    return null;
  }

  @override
  DecoratedType visitMethodDeclaration(MethodDeclaration node) {
    _handleExecutableDeclaration(node, node.declaredElement, node.metadata,
        node.returnType, node.parameters, null, node.body, null);
    node.typeParameters?.accept(this);
    return null;
  }

  @override
  DecoratedType visitMethodInvocation(MethodInvocation node) {
    DecoratedType targetType;
    var target = node.target;
    bool isNullAware = node.isNullAware;
    var callee = node.methodName.staticElement;
    bool calleeIsStatic = callee is ExecutableElement && callee.isStatic;
    node.typeArguments?.accept(this);

    if (node.isCascaded) {
      targetType = _currentCascadeTargetType;
    } else if (target != null) {
      if (_isPrefix(target)) {
        // Nothing to do.
      } else if (calleeIsStatic) {
        target.accept(this);
      } else if (isNullAware) {
        targetType = target.accept(this);
      } else {
        targetType = _handleTarget(target, node.methodName.name, callee);
      }
    } else if (target == null && callee.enclosingElement is ClassElement) {
      targetType = _thisOrSuper(node);
    }
    if (callee == null) {
      // Dynamic dispatch.  The return type is `dynamic`.
      // TODO(paulberry): would it be better to assume a return type of `Never`
      // so that we don't unnecessarily propagate nullabilities everywhere?
      node.argumentList.accept(this);
      return _makeNullableDynamicType(node);
    }
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    if (callee is PropertyAccessorElement) {
      calleeType = calleeType.returnType;
    }
    var expressionType = _handleInvocationArguments(
        node,
        node.argumentList.arguments,
        node.typeArguments,
        node.typeArgumentTypes,
        calleeType,
        null,
        invokeType: node.staticInvokeType);
    if (isNullAware) {
      expressionType = expressionType.withNode(
          NullabilityNode.forLUB(targetType.node, expressionType.node));
      _variables.recordDecoratedExpressionType(node, expressionType);
    }
    return expressionType;
  }

  @override
  DecoratedType visitMixinDeclaration(MixinDeclaration node) {
    visitClassOrMixinOrExtensionDeclaration(node);
    node.implementsClause?.accept(this);
    node.onClause?.accept(this);
    node.typeParameters?.accept(this);
    return null;
  }

  @override
  DecoratedType visitNamespaceDirective(NamespaceDirective node) {
    // skip directives, but not their metadata
    node.metadata.accept(this);
    return null;
  }

  @override
  DecoratedType visitNullLiteral(NullLiteral node) {
    _flowAnalysis.nullLiteral(node);
    var decoratedType = DecoratedType.forImplicitType(
        typeProvider, node.staticType, _graph,
        offset: node.offset);
    _graph.makeNullable(decoratedType.node, LiteralOrigin(source, node));
    return decoratedType;
  }

  @override
  DecoratedType visitParenthesizedExpression(ParenthesizedExpression node) {
    var result = node.expression.accept(this);
    _flowAnalysis.parenthesizedExpression(node, node.expression);
    return result;
  }

  @override
  DecoratedType visitPartOfDirective(PartOfDirective node) {
    // skip directives, but not their metadata
    node.metadata.accept(this);
    return null;
  }

  @override
  DecoratedType visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type.isIncrementOperator) {
      var operand = node.operand;
      var targetType = _checkExpressionNotNull(operand);
      var callee = node.staticElement;
      DecoratedType writeType;
      if (callee == null) {
        // Dynamic dispatch.  The return type is `dynamic`.
        // TODO(paulberry): would it be better to assume a return type of `Never`
        // so that we don't unnecessarily propagate nullabilities everywhere?
        writeType = _makeNullableDynamicType(node);
      } else {
        var calleeType =
            getOrComputeElementType(callee, targetType: targetType);
        writeType = _fixNumericTypes(calleeType.returnType, node.staticType);
      }
      if (operand is SimpleIdentifier) {
        var element = operand.staticElement;
        if (element is PromotableElement) {
          _flowAnalysis.write(element, writeType);
        }
      }
      return targetType;
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
      return _handlePropertyAccess(
          node, node.prefix, node.identifier, false, false);
    }
  }

  @override
  DecoratedType visitPrefixExpression(PrefixExpression node) {
    var operand = node.operand;
    var targetType = _checkExpressionNotNull(operand);
    var operatorType = node.operator.type;
    if (operatorType == TokenType.BANG) {
      _flowAnalysis.logicalNot_end(node, operand);
      return _makeNonNullableBoolType(node);
    } else {
      var callee = node.staticElement;
      var isIncrementOrDecrement = operatorType.isIncrementOperator;
      DecoratedType staticType;
      if (callee == null) {
        // Dynamic dispatch.  The return type is `dynamic`.
        // TODO(paulberry): would it be better to assume a return type of `Never`
        // so that we don't unnecessarily propagate nullabilities everywhere?
        staticType = _makeNullableDynamicType(node);
      } else {
        var calleeType =
            getOrComputeElementType(callee, targetType: targetType);
        if (isIncrementOrDecrement) {
          staticType = _fixNumericTypes(calleeType.returnType, node.staticType);
        } else {
          staticType = _handleInvocationArguments(
              node, [], null, null, calleeType, null);
        }
      }
      if (isIncrementOrDecrement) {
        if (operand is SimpleIdentifier) {
          var element = operand.staticElement;
          if (element is PromotableElement) {
            _flowAnalysis.write(element, staticType);
          }
        }
      }
      return staticType;
    }
  }

  @override
  DecoratedType visitPropertyAccess(PropertyAccess node) {
    return _handlePropertyAccess(node, node.target, node.propertyName,
        node.isNullAware, node.isCascaded);
  }

  @override
  DecoratedType visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var callee = node.staticElement;
    var calleeType = _variables.decoratedElementType(callee);
    _handleInvocationArguments(
        node, node.argumentList.arguments, null, null, calleeType, null);
    return null;
  }

  @override
  DecoratedType visitRethrowExpression(RethrowExpression node) {
    _flowAnalysis.handleExit();
    var nullabilityNode = NullabilityNode.forInferredType(offset: node.offset);
    _graph.makeNonNullable(nullabilityNode, ThrowOrigin(source, node));
    return DecoratedType(node.staticType, nullabilityNode);
  }

  @override
  DecoratedType visitReturnStatement(ReturnStatement node) {
    DecoratedType returnType = _currentFunctionType.returnType;
    Expression returnValue = node.expression;
    final isAsync = node.thisOrAncestorOfType<FunctionBody>().isAsynchronous;
    if (returnValue == null) {
      var implicitNullType = DecoratedType.forImplicitType(
          typeProvider, typeProvider.nullType, _graph,
          offset: node.offset);
      _graph.makeNullable(
          implicitNullType.node, AlwaysNullableTypeOrigin(source, node));
      _checkAssignment(null,
          source: isAsync
              ? _futureOf(implicitNullType, offset: node.offset)
              : implicitNullType,
          destination: returnType,
          hard: false);
    } else {
      _handleAssignment(returnValue,
          destinationType: returnType, wrapFuture: isAsync);
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
    var setOrMapType = node.staticType as InterfaceType;
    var typeArguments = node.typeArguments?.arguments;

    if (node.isSet) {
      final previousLiteralType = _currentLiteralElementType;
      try {
        if (typeArguments == null) {
          assert(setOrMapType.typeArguments.length == 1);
          var elementType = DecoratedType.forImplicitType(
              typeProvider, setOrMapType.typeArguments[0], _graph,
              offset: node.offset);
          instrumentation?.implicitTypeArguments(source, node, [elementType]);
          _currentLiteralElementType = elementType;
        } else {
          assert(typeArguments.length == 1);
          node.typeArguments.accept(this);
          _currentLiteralElementType =
              _variables.decoratedTypeAnnotation(source, typeArguments[0]);
        }
        node.elements.forEach(_handleCollectionElement);
        return _makeNonNullLiteralType(node,
            typeArguments: [_currentLiteralElementType]);
      } finally {
        _currentLiteralElementType = previousLiteralType;
      }
    } else {
      assert(node.isMap);

      final previousKeyType = _currentMapKeyType;
      final previousValueType = _currentMapValueType;
      try {
        if (typeArguments == null) {
          assert(setOrMapType.typeArguments.length == 2);
          var keyType = DecoratedType.forImplicitType(
              typeProvider, setOrMapType.typeArguments[0], _graph,
              offset: node.offset);
          _currentMapKeyType = keyType;
          var valueType = DecoratedType.forImplicitType(
              typeProvider, setOrMapType.typeArguments[1], _graph,
              offset: node.offset);
          _currentMapValueType = valueType;
          instrumentation
              ?.implicitTypeArguments(source, node, [keyType, valueType]);
        } else {
          assert(typeArguments.length == 2);
          node.typeArguments.accept(this);
          _currentMapKeyType =
              _variables.decoratedTypeAnnotation(source, typeArguments[0]);
          _currentMapValueType =
              _variables.decoratedTypeAnnotation(source, typeArguments[1]);
        }

        node.elements.forEach(_handleCollectionElement);
        return _makeNonNullLiteralType(node,
            typeArguments: [_currentMapKeyType, _currentMapValueType]);
      } finally {
        _currentMapKeyType = previousKeyType;
        _currentMapValueType = previousValueType;
      }
    }
  }

  @override
  DecoratedType visitSimpleIdentifier(SimpleIdentifier node) {
    var staticElement = node.staticElement;
    if (staticElement is PromotableElement) {
      if (!node.inDeclarationContext()) {
        var promotedType = _flowAnalysis.variableRead(node, staticElement);
        if (promotedType != null) return promotedType;
      }
      var type = getOrComputeElementType(staticElement);
      if (!node.inDeclarationContext() &&
          node.inGetterContext() &&
          !_flowAnalysis.isAssigned(staticElement)) {
        _graph.makeNullable(type.node, UninitializedReadOrigin(source, node));
      }
      return type;
    } else if (staticElement is FunctionElement ||
        staticElement is MethodElement ||
        staticElement is ConstructorElement) {
      return getOrComputeElementType(staticElement,
          targetType: staticElement.enclosingElement is ClassElement
              ? _thisOrSuper(node)
              : null);
    } else if (staticElement is PropertyAccessorElement) {
      var elementType = getOrComputeElementType(staticElement,
          targetType: staticElement.enclosingElement is ClassElement
              ? _thisOrSuper(node)
              : null);
      return staticElement.isGetter
          ? elementType.returnType
          : elementType.positionalParameters[0];
    } else if (staticElement is TypeDefiningElement) {
      return _makeNonNullLiteralType(node);
    } else if (staticElement is ExtensionElement) {
      return _makeNonNullLiteralType(node);
    } else if (staticElement == null) {
      assert(node.toString() == 'void');
      return _makeNullableVoidType(node);
    } else if (staticElement.enclosingElement is ClassElement &&
        (staticElement.enclosingElement as ClassElement).isEnum) {
      return getOrComputeElementType(staticElement);
    } else {
      // TODO(paulberry)
      _unimplemented(node,
          'Simple identifier with a static element of type ${staticElement.runtimeType}');
    }
  }

  @override
  DecoratedType visitSpreadElement(SpreadElement node) {
    final spreadType = node.expression.staticType;
    DecoratedType spreadTypeDecorated;
    if (_typeSystem.isSubtypeOf(spreadType, typeProvider.mapObjectObjectType)) {
      assert(_currentMapKeyType != null && _currentMapValueType != null);
      final expectedType = typeProvider.mapType2(
          _currentMapKeyType.type, _currentMapValueType.type);
      final expectedDecoratedType = DecoratedType.forImplicitType(
          typeProvider, expectedType, _graph,
          typeArguments: [_currentMapKeyType, _currentMapValueType],
          offset: node.offset);

      spreadTypeDecorated = _handleAssignment(node.expression,
          destinationType: expectedDecoratedType);
    } else if (_typeSystem.isSubtypeOf(
        spreadType, typeProvider.iterableDynamicType)) {
      assert(_currentLiteralElementType != null);
      final expectedType =
          typeProvider.iterableType2(_currentLiteralElementType.type);
      final expectedDecoratedType = DecoratedType.forImplicitType(
          typeProvider, expectedType, _graph,
          typeArguments: [_currentLiteralElementType], offset: node.offset);

      spreadTypeDecorated = _handleAssignment(node.expression,
          destinationType: expectedDecoratedType);
    } else {
      // Downcast. We can't assume nullability here, so do nothing.
    }

    if (!node.isNullAware) {
      _checkExpressionNotNull(node.expression, sourceType: spreadTypeDecorated);
    }

    return null;
  }

  @override
  DecoratedType visitStringLiteral(StringLiteral node) {
    node.visitChildren(this);
    return _makeNonNullLiteralType(node);
  }

  @override
  DecoratedType visitSuperConstructorInvocation(
      SuperConstructorInvocation node) {
    var callee = node.staticElement;
    var nullabilityNode = NullabilityNode.forInferredType(offset: node.offset);
    var class_ = node.thisOrAncestorOfType<ClassDeclaration>();
    var decoratedSupertype = _decoratedClassHierarchy.getDecoratedSupertype(
        class_.declaredElement, callee.enclosingElement);
    var typeArguments = decoratedSupertype.typeArguments;
    Iterable<DartType> typeArgumentTypes;
    if (typeArguments != null) {
      typeArgumentTypes = typeArguments.map((t) => t.type);
    } else {
      typeArgumentTypes = [];
    }
    var createdType = DecoratedType(callee.returnType, nullabilityNode,
        typeArguments: typeArguments);
    var calleeType = getOrComputeElementType(callee, targetType: createdType);
    var constructorTypeParameters = callee.enclosingElement.typeParameters;

    _handleInvocationArguments(
        node,
        node.argumentList.arguments,
        null /*typeArguments*/,
        typeArgumentTypes,
        calleeType,
        constructorTypeParameters);
    return null;
  }

  @override
  DecoratedType visitSuperExpression(SuperExpression node) {
    return _thisOrSuper(node);
  }

  @override
  DecoratedType visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);
    _flowAnalysis.switchStatement_expressionEnd(node);
    var hasDefault = false;
    for (var member in node.members) {
      var hasLabel = member.labels.isNotEmpty;
      _flowAnalysis.switchStatement_beginCase(hasLabel, node);
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
    return _makeNonNullLiteralType(node);
  }

  @override
  DecoratedType visitThisExpression(ThisExpression node) {
    return _thisOrSuper(node);
  }

  @override
  DecoratedType visitThrowExpression(ThrowExpression node) {
    node.expression.accept(this);
    // TODO(paulberry): do we need to check the expression type?  I think not.
    _flowAnalysis.handleExit();
    var nullabilityNode = NullabilityNode.forInferredType(offset: node.offset);
    _graph.makeNonNullable(nullabilityNode, ThrowOrigin(source, node));
    return DecoratedType(node.staticType, nullabilityNode);
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
    if (catchClauses.isNotEmpty) {
      _flowAnalysis.tryCatchStatement_bodyEnd(body);
      catchClauses.accept(this);
      _flowAnalysis.tryCatchStatement_end();
    }
    if (finallyBlock != null) {
      _flowAnalysis.tryFinallyStatement_finallyBegin(
          catchClauses.isNotEmpty ? node : body);
      finallyBlock.accept(this);
      _flowAnalysis.tryFinallyStatement_end(finallyBlock);
    }
    return null;
  }

  @override
  DecoratedType visitTypeName(TypeName typeName) {
    var typeArguments = typeName.typeArguments?.arguments;
    var element = typeName.name.staticElement;
    if (element is GenericTypeAliasElement) {
      final typedefType = _variables.decoratedElementType(element);
      final typeNameType = _variables.decoratedTypeAnnotation(source, typeName);

      Map<TypeParameterElement, DecoratedType> substitutions;
      if (typeName.typeArguments == null) {
        // TODO(mfairhurst): substitute instantiations to bounds
        substitutions = {};
      } else {
        substitutions = Map<TypeParameterElement, DecoratedType>.fromIterables(
            element.typeParameters,
            typeName.typeArguments.arguments
                .map((t) => _variables.decoratedTypeAnnotation(source, t)));
      }

      final decoratedType = typedefType.substitute(substitutions);
      final origin = TypedefReferenceOrigin(source, typeName);
      _linkDecoratedTypes(decoratedType, typeNameType, origin, isUnion: true);
    } else if (element is TypeParameterizedElement) {
      if (typeArguments == null) {
        var instantiatedType =
            _variables.decoratedTypeAnnotation(source, typeName);
        if (instantiatedType == null) {
          throw new StateError('No type annotation for type name '
              '${typeName.toSource()}, offset=${typeName.offset}');
        }
        var origin = InstantiateToBoundsOrigin(source, typeName);
        for (int i = 0; i < instantiatedType.typeArguments.length; i++) {
          _linkDecoratedTypes(
              instantiatedType.typeArguments[i],
              _variables.decoratedTypeParameterBound(element.typeParameters[i]),
              origin,
              isUnion: false);
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
    typeName.visitChildren(this);
    typeNameVisited(typeName); // Note this has been visited to TypeNameTracker.
    return null;
  }

  @override
  DecoratedType visitVariableDeclarationList(VariableDeclarationList node) {
    var parent = node.parent;
    bool isTopLevel =
        parent is FieldDeclaration || parent is TopLevelVariableDeclaration;
    node.metadata.accept(this);
    node.type?.accept(this);
    for (var variable in node.variables) {
      variable.metadata.accept(this);
      var initializer = variable.initializer;
      var declaredElement = variable.declaredElement;
      if (isTopLevel) {
        assert(_flowAnalysis == null);
        _createFlowAnalysis(variable, null);
      } else {
        assert(_flowAnalysis != null);
      }
      try {
        if (initializer != null) {
          if (declaredElement is PromotableElement) {
            _flowAnalysis.initialize(declaredElement);
          }
          var destinationType = getOrComputeElementType(declaredElement);
          _handleAssignment(initializer, destinationType: destinationType);
        }
        if (isTopLevel) {
          _flowAnalysis.finish();
        }
      } finally {
        if (isTopLevel) {
          _flowAnalysis = null;
          _assignedVariables = null;
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
    _flowAnalysis.whileStatement_conditionBegin(node);
    _checkExpressionNotNull(node.condition);
    _flowAnalysis.whileStatement_bodyBegin(node, node.condition);
    _postDominatedLocals.doScoped(action: () => node.body.accept(this));
    _flowAnalysis.whileStatement_end();
    return null;
  }

  void _addParametersToFlowAnalysis(FormalParameterList parameters) {
    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        _flowAnalysis.initialize(parameter.declaredElement);
      }
    }
  }

  /// Visits [expression] and generates the appropriate edge to assert that its
  /// value is non-null.
  ///
  /// Returns the decorated type of [expression].
  DecoratedType _checkExpressionNotNull(Expression expression,
      {DecoratedType sourceType}) {
    if (_isPrefix(expression)) {
      throw ArgumentError('cannot check non-nullability of a prefix');
    }
    sourceType ??= expression.accept(this);
    if (sourceType == null) {
      throw StateError('No type computed for ${expression.runtimeType} '
          '(${expression.toSource()}) offset=${expression.offset}');
    }
    var origin = _makeEdgeOrigin(sourceType, expression);
    var edge = _graph.makeNonNullable(sourceType.node, origin,
        hard: _postDominatedLocals.isReferenceInScope(expression),
        guards: _guards);
    if (origin is ExpressionChecksOrigin) {
      origin.checks.edges.add(edge);
    }
    return sourceType;
  }

  @override
  void _connect(
      NullabilityNode source, NullabilityNode destination, EdgeOrigin origin,
      {bool hard = false, bool checkable = true}) {
    var edge = _graph.connect(source, destination, origin,
        hard: hard, checkable: checkable, guards: _guards);
    if (origin is ExpressionChecksOrigin) {
      origin.checks.edges.add(edge);
    }
  }

  void _createFlowAnalysis(Declaration node, FormalParameterList parameters) {
    assert(_flowAnalysis == null);
    assert(_assignedVariables == null);
    _assignedVariables =
        FlowAnalysisHelper.computeAssignedVariables(node, parameters);
    _flowAnalysis = FlowAnalysis<AstNode, Statement, Expression,
            PromotableElement, DecoratedType>(
        DecoratedTypeOperations(_typeSystem, _variables, _graph),
        _assignedVariables);
    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        _flowAnalysis.initialize(parameter.declaredElement);
      }
    }
  }

  /// Creates a type that can be used to check that an expression's value is
  /// non-nullable.
  DecoratedType _createNonNullableType(Expression expression) {
    // Note: it's not necessary for the type to precisely match the type of the
    // expression, since all we are going to do is cause a single graph edge to
    // be built; it is sufficient to pass in any decorated type whose node is
    // non-nullable.  So we use `Object`.
    var nullabilityNode =
        NullabilityNode.forInferredType(offset: expression.offset);
    _graph.makeNonNullableUnion(
        nullabilityNode, NonNullableUsageOrigin(source, expression));
    return DecoratedType(typeProvider.objectType, nullabilityNode);
  }

  DecoratedType _decorateUpperOrLowerBound(AstNode astNode, DartType type,
      DecoratedType left, DecoratedType right, bool isLUB,
      {NullabilityNode node}) {
    var leftType = left.type;
    var rightType = right.type;
    if (leftType is TypeParameterType && leftType != type) {
      // We are "unwrapping" a type parameter type to its bound.
      final typeParam = leftType.element;
      return _decorateUpperOrLowerBound(
          astNode,
          type,
          left.substitute(
              {typeParam: _variables.decoratedTypeParameterBound(typeParam)}),
          right,
          isLUB,
          node: node);
    }
    if (rightType is TypeParameterType && rightType != type) {
      // We are "unwrapping" a type parameter type to its bound.
      final typeParam = rightType.element;
      return _decorateUpperOrLowerBound(
          astNode,
          type,
          left,
          right.substitute(
              {typeParam: _variables.decoratedTypeParameterBound(typeParam)}),
          isLUB,
          node: node);
    }

    node ??= isLUB
        ? NullabilityNode.forLUB(left.node, right.node)
        : _nullabilityNodeForGLB(astNode, left.node, right.node);

    if (type.isDynamic || type.isVoid) {
      return DecoratedType(type, node);
    } else if (type is InterfaceType) {
      if (type.typeArguments.isEmpty) {
        return DecoratedType(type, node);
      } else {
        if (leftType.isDartCoreNull) {
          assert(isLUB, "shouldn't be possible to get C<T> from GLB(null, S)");
          return DecoratedType(type, node, typeArguments: right.typeArguments);
        } else if (rightType.isDartCoreNull) {
          assert(isLUB, "shouldn't be possible to get C<T> from GLB(S, null)");
          return DecoratedType(type, node, typeArguments: left.typeArguments);
        } else if (leftType is InterfaceType && rightType is InterfaceType) {
          List<DecoratedType> leftTypeArguments;
          List<DecoratedType> rightTypeArguments;
          if (isLUB) {
            leftTypeArguments = _decoratedClassHierarchy
                .asInstanceOf(left, type.element)
                .typeArguments;
            rightTypeArguments = _decoratedClassHierarchy
                .asInstanceOf(right, type.element)
                .typeArguments;
          } else {
            if (leftType.element != type.element ||
                rightType.element != type.element) {
              _unimplemented(astNode, 'GLB with substitution');
            }
            leftTypeArguments = left.typeArguments;
            rightTypeArguments = right.typeArguments;
          }
          List<DecoratedType> newTypeArguments = [];
          for (int i = 0; i < type.typeArguments.length; i++) {
            newTypeArguments.add(_decorateUpperOrLowerBound(
                astNode,
                type.typeArguments[i],
                leftTypeArguments[i],
                rightTypeArguments[i],
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
      if (leftType.isDartCoreNull) {
        assert(
            isLUB, "shouldn't be possible to get a function from GLB(null, S)");
        return DecoratedType(type, node,
            returnType: right.returnType,
            typeFormalBounds: right.typeFormalBounds,
            positionalParameters: right.positionalParameters,
            namedParameters: right.namedParameters);
      } else if (rightType.isDartCoreNull) {
        assert(
            isLUB, "shouldn't be possible to get a function from GLB(S, null)");
        return DecoratedType(type, node,
            returnType: left.returnType,
            typeFormalBounds: left.typeFormalBounds,
            positionalParameters: left.positionalParameters,
            namedParameters: left.namedParameters);
      }
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
      var leftType = left.type;
      var rightType = right.type;
      if (leftType.isDartCoreNull || rightType.isDartCoreNull) {
        assert(isLUB, "shouldn't be possible to get T from GLB(null, S)");
        return DecoratedType(type, node);
      }

      assert(leftType.element == type.element &&
          rightType.element == type.element);
      return DecoratedType(type, node);
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

  DecoratedType _futureOf(DecoratedType type, {@required int offset}) =>
      DecoratedType.forImplicitType(
          typeProvider, typeProvider.futureType2(type.type), _graph,
          typeArguments: [type], offset: offset);

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
  ///
  /// Set [wrapFuture] to true to handle assigning Future<flatten(T)> to R.
  DecoratedType _handleAssignment(Expression expression,
      {DecoratedType destinationType,
      Expression destinationExpression,
      AssignmentExpression compoundOperatorInfo,
      AssignmentExpression questionAssignNode,
      bool fromDefaultValue = false,
      bool wrapFuture = false}) {
    assert(
        (destinationExpression == null) != (destinationType == null),
        'Either destinationExpression or destinationType should be supplied, '
        'but not both');
    PromotableElement destinationLocalVariable;
    if (destinationType == null) {
      if (destinationExpression is SimpleIdentifier) {
        var element = destinationExpression.staticElement;
        if (element is PromotableElement) {
          destinationLocalVariable = element;
        }
      }
      if (destinationLocalVariable != null) {
        destinationType = getOrComputeElementType(destinationLocalVariable);
      } else {
        destinationType = destinationExpression.accept(this);
      }
    }

    if (questionAssignNode != null) {
      _guards.add(destinationType.node);
      _flowAnalysis
          .ifNullExpression_rightBegin(questionAssignNode.leftHandSide);
    }
    DecoratedType sourceType;
    try {
      sourceType = expression.accept(this);
      if (wrapFuture) {
        sourceType = _wrapFuture(sourceType, offset: expression.offset);
      }
      if (sourceType == null) {
        throw StateError('No type computed for ${expression.runtimeType} '
            '(${expression.toSource()}) offset=${expression.offset}');
      }
      EdgeOrigin edgeOrigin = _makeEdgeOrigin(sourceType, expression);
      if (compoundOperatorInfo != null) {
        var compoundOperatorMethod = compoundOperatorInfo.staticElement;
        if (compoundOperatorMethod != null) {
          _checkAssignment(
              CompoundAssignmentOrigin(source, compoundOperatorInfo),
              source: destinationType,
              destination: _createNonNullableType(compoundOperatorInfo),
              hard: _postDominatedLocals
                  .isReferenceInScope(destinationExpression));
          DecoratedType compoundOperatorType = getOrComputeElementType(
              compoundOperatorMethod,
              targetType: destinationType);
          assert(compoundOperatorType.positionalParameters.length > 0);
          _checkAssignment(edgeOrigin,
              source: sourceType,
              destination: compoundOperatorType.positionalParameters[0],
              hard: _postDominatedLocals.isReferenceInScope(expression));
          sourceType = _fixNumericTypes(
              compoundOperatorType.returnType, compoundOperatorInfo.staticType);
          _checkAssignment(
              CompoundAssignmentOrigin(source, compoundOperatorInfo),
              source: sourceType,
              destination: destinationType,
              hard: false);
        } else {
          sourceType = _makeNullableDynamicType(compoundOperatorInfo);
        }
      } else {
        _checkAssignment(edgeOrigin,
            source: sourceType,
            destination: destinationType,
            hard: questionAssignNode == null &&
                _postDominatedLocals.isReferenceInScope(expression));
      }
      if (destinationLocalVariable != null) {
        _flowAnalysis.write(destinationLocalVariable, sourceType);
      }
      if (questionAssignNode != null) {
        _flowAnalysis.ifNullExpression_end();
        // a ??= b is only nullable if both a and b are nullable.
        sourceType = destinationType.withNode(_nullabilityNodeForGLB(
            questionAssignNode, sourceType.node, destinationType.node));
        _variables.recordDecoratedExpressionType(
            questionAssignNode, sourceType);
      }
    } finally {
      if (questionAssignNode != null) {
        _guards.removeLast();
      }
    }
    if (destinationExpression != null) {
      _postDominatedLocals.removeReferenceFromAllScopes(destinationExpression);
    }
    return sourceType;
  }

  DecoratedType _handleCollectionElement(CollectionElement element) {
    if (element is Expression) {
      assert(_currentLiteralElementType != null);
      return _handleAssignment(element,
          destinationType: _currentLiteralElementType);
    } else {
      return element.accept(this);
    }
  }

  void _handleConstructorRedirection(
      FormalParameterList parameters, ConstructorName redirectedConstructor) {
    var callee = redirectedConstructor.staticElement.declaration;
    var redirectedClass = callee.enclosingElement;
    var calleeType = _variables.decoratedElementType(callee);
    var typeArguments = redirectedConstructor.type.typeArguments;
    var typeArgumentTypes =
        typeArguments?.arguments?.map((t) => t.type)?.toList();
    _handleInvocationArguments(
        redirectedConstructor,
        parameters.parameters,
        typeArguments,
        typeArgumentTypes,
        calleeType,
        redirectedClass.typeParameters);
  }

  void _handleExecutableDeclaration(
      Declaration node,
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
    _createFlowAnalysis(node, parameters);
    parameters?.accept(this);
    _currentFunctionType = _variables.decoratedElementType(declaredElement);
    _addParametersToFlowAnalysis(parameters);
    // Push a scope of post-dominated declarations on the stack.
    _postDominatedLocals.pushScope(elements: declaredElement.parameters);
    try {
      initializers?.accept(this);
      if (declaredElement is ConstructorElement &&
          !declaredElement.isFactory &&
          declaredElement.redirectedConstructor == null) {
        _handleUninitializedFields(node, _fieldsNotInitializedByConstructor);
      }
      body.accept(this);
      if (redirectedConstructor != null) {
        _handleConstructorRedirection(parameters, redirectedConstructor);
      }
      if (declaredElement is! ConstructorElement) {
        var enclosingElement = declaredElement.enclosingElement;
        if (enclosingElement is ClassElement) {
          var overriddenElements = _inheritanceManager.getOverridden(
              enclosingElement.thisType,
              Name(enclosingElement.library.source.uri, declaredElement.name));
          for (var overriddenElement
              in overriddenElements ?? <ExecutableElement>[]) {
            _handleExecutableOverriddenDeclaration(node, returnType, parameters,
                enclosingElement, overriddenElement);
          }
        }
      }
      _flowAnalysis.finish();
    } finally {
      _flowAnalysis = null;
      _assignedVariables = null;
      _currentFunctionType = null;
      _postDominatedLocals.popScope();
    }
  }

  void _handleExecutableOverriddenDeclaration(
      Declaration node,
      TypeAnnotation returnType,
      FormalParameterList parameters,
      ClassElement classElement,
      Element overriddenElement) {
    overriddenElement = overriddenElement.declaration;
    var overriddenClass = overriddenElement.enclosingElement as ClassElement;
    var decoratedSupertype = _decoratedClassHierarchy.getDecoratedSupertype(
        classElement, overriddenClass);
    var substitution = decoratedSupertype.asSubstitution;
    if (overriddenElement is PropertyAccessorElement &&
        overriddenElement.isSynthetic) {
      assert(node is MethodDeclaration);
      var method = node as MethodDeclaration;
      var decoratedOverriddenField =
          _variables.decoratedElementType(overriddenElement.variable);
      var overriddenFieldType =
          decoratedOverriddenField.substitute(substitution);
      if (method.isGetter) {
        _checkAssignment(ReturnTypeInheritanceOrigin(source, node),
            source: _currentFunctionType.returnType,
            destination: overriddenFieldType,
            hard: true);
      } else {
        assert(method.isSetter);
        DecoratedType currentParameterType =
            _currentFunctionType.positionalParameters.single;
        DecoratedType overriddenParameterType = overriddenFieldType;
        _checkAssignment(ParameterInheritanceOrigin(source, node),
            source: overriddenParameterType,
            destination: currentParameterType,
            hard: true);
      }
    } else {
      var decoratedOverriddenFunctionType =
          _variables.decoratedElementType(overriddenElement);
      var overriddenFunctionType =
          decoratedOverriddenFunctionType.substitute(substitution);
      if (returnType == null) {
        _linkDecoratedTypes(
            _currentFunctionType.returnType,
            overriddenFunctionType.returnType,
            ReturnTypeInheritanceOrigin(source, node),
            isUnion: true);
      } else {
        _checkAssignment(ReturnTypeInheritanceOrigin(source, node),
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
            normalParameter = (parameter as DefaultFormalParameter).parameter;
          }
          DecoratedType currentParameterType;
          DecoratedType overriddenParameterType;
          if (parameter.isNamed) {
            var name = normalParameter.identifier.name;
            currentParameterType = _currentFunctionType.namedParameters[name];
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
            var origin = ParameterInheritanceOrigin(source, node);
            if (_isUntypedParameter(normalParameter)) {
              _linkDecoratedTypes(
                  overriddenParameterType, currentParameterType, origin,
                  isUnion: true);
            } else {
              _checkAssignment(origin,
                  source: overriddenParameterType,
                  destination: currentParameterType,
                  hard: false,
                  checkable: false);
            }
          }
        }
      }
    }
  }

  void _handleForLoopParts(AstNode node, ForLoopParts parts, AstNode body,
      DecoratedType Function(AstNode) bodyHandler) {
    if (parts is ForParts) {
      if (parts is ForPartsWithDeclarations) {
        parts.variables?.accept(this);
      } else if (parts is ForPartsWithExpression) {
        parts.initialization?.accept(this);
      }
      _flowAnalysis.for_conditionBegin(node);
      if (parts.condition != null) {
        _checkExpressionNotNull(parts.condition);
      }
      _flowAnalysis.for_bodyBegin(
          node is Statement ? node : null, parts.condition);
    } else if (parts is ForEachParts) {
      Element lhsElement;
      if (parts is ForEachPartsWithDeclaration) {
        var variableElement = parts.loopVariable.declaredElement;
        lhsElement = variableElement;
        parts.loopVariable?.type?.accept(this);
      } else if (parts is ForEachPartsWithIdentifier) {
        lhsElement = parts.identifier.staticElement;
      } else {
        throw StateError(
            'Unexpected ForEachParts subtype: ${parts.runtimeType}');
      }
      var iterableType = _checkExpressionNotNull(parts.iterable);
      DecoratedType elementType;
      if (lhsElement != null) {
        DecoratedType lhsType = _variables.decoratedElementType(lhsElement);
        var iterableTypeType = iterableType.type;
        if (_typeSystem.isSubtypeOf(
            iterableTypeType, typeProvider.iterableDynamicType)) {
          elementType = _decoratedClassHierarchy
              .asInstanceOf(
                  iterableType, typeProvider.iterableDynamicType.element)
              .typeArguments[0];
          _checkAssignment(ForEachVariableOrigin(source, parts),
              source: elementType, destination: lhsType, hard: false);
        }
      }
      _flowAnalysis.forEach_bodyBegin(
          node,
          lhsElement is PromotableElement ? lhsElement : null,
          elementType ?? _makeNullableDynamicType(node));
    }

    // The condition may fail/iterable may be empty, so the body gets a new
    // post-dominator scope.
    _postDominatedLocals.doScoped(action: () {
      bodyHandler(body);

      if (parts is ForParts) {
        _flowAnalysis.for_updaterBegin();
        parts.updaters.accept(this);
        _flowAnalysis.for_end();
      } else {
        _flowAnalysis.forEach_end();
      }
    });
  }

  /// Instantiate [type] with [argumentTypes], assigning [argumentTypes] to
  /// [bounds].
  DecoratedType _handleInstantiation(
      DecoratedType type, List<DecoratedType> argumentTypes) {
    for (var i = 0; i < argumentTypes.length; ++i) {
      _checkAssignment(null,
          source: argumentTypes[i],
          destination: type.typeFormalBounds[i],
          hard: true);
    }

    return type.instantiate(argumentTypes);
  }

  /// Creates the necessary constraint(s) for an [ArgumentList] when invoking an
  /// executable element whose type is [calleeType].
  ///
  /// Only pass [typeArguments] or [typeArgumentTypes] depending on the use
  /// case; only one will be used.
  ///
  /// Returns the decorated return type of the invocation, after any necessary
  /// substitutions.
  DecoratedType _handleInvocationArguments(
      AstNode node,
      Iterable<AstNode> arguments,
      TypeArgumentList typeArguments,
      Iterable<DartType> typeArgumentTypes,
      DecoratedType calleeType,
      List<TypeParameterElement> constructorTypeParameters,
      {DartType invokeType}) {
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
          calleeType = _handleInstantiation(calleeType, argumentTypes);
        }
      } else {
        if (invokeType is FunctionType) {
          var argumentTypes = typeArgumentTypes
              .map((argType) => DecoratedType.forImplicitType(
                  typeProvider, argType, _graph,
                  offset: node.offset))
              .toList();
          instrumentation?.implicitTypeArguments(source, node, argumentTypes);
          calleeType = _handleInstantiation(calleeType, argumentTypes);
        } else if (constructorTypeParameters != null) {
          // No need to instantiate; caller has already substituted in the
          // correct type arguments.
        } else {
          assert(
              false,
              'invoke type should be a non-null function type, or '
              'dynamic/Function, which have no type arguments. '
              '(got $invokeType)');
        }
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
      entry.value.node.recordNamedParameterNotSupplied(
          _guards, _graph, NamedParameterNotSuppliedOrigin(source, node));
    }
    return calleeType.returnType;
  }

  DecoratedType _handlePropertyAccess(Expression node, Expression target,
      SimpleIdentifier propertyName, bool isNullAware, bool isCascaded) {
    DecoratedType targetType;
    var callee = propertyName.staticElement;
    bool calleeIsStatic = callee is ExecutableElement && callee.isStatic;
    if (isCascaded) {
      targetType = _currentCascadeTargetType;
    } else if (_isPrefix(target)) {
      return propertyName.accept(this);
    } else if (calleeIsStatic) {
      target.accept(this);
    } else if (isNullAware) {
      targetType = target.accept(this);
    } else {
      targetType = _handleTarget(target, propertyName.name, callee);
    }
    if (callee == null) {
      // Dynamic dispatch.
      return _makeNullableDynamicType(node);
    }
    var calleeType = getOrComputeElementType(callee, targetType: targetType);
    // TODO(paulberry): substitute if necessary
    if (propertyName.inSetterContext()) {
      if (isNullAware) {
        _conditionalNodes[node] = targetType.node;
      }
      return calleeType.positionalParameters[0];
    } else {
      var expressionType = callee is PropertyAccessorElement
          ? calleeType.returnType
          : calleeType;
      if (isNullAware) {
        expressionType = expressionType.withNode(
            NullabilityNode.forLUB(targetType.node, expressionType.node));
        _variables.recordDecoratedExpressionType(node, expressionType);
      }
      return expressionType;
    }
  }

  DecoratedType _handleTarget(Expression target, String name, Element method) {
    if (isDeclaredOnObject(name)) {
      return target.accept(this);
    } else if (method is MethodElement &&
        method.enclosingElement is ExtensionElement) {
      // Extension methods can be called on a `null` target, when the `on` type
      // of the extension is nullable.
      _handleAssignment(target,
          destinationType:
              _variables.decoratedElementType(method.enclosingElement));
      return target.accept(this);
    } else {
      return _checkExpressionNotNull(target);
    }
  }

  void _handleUninitializedFields(AstNode node, Set<FieldElement> fields) {
    for (var field in fields) {
      _graph.makeNullable(_variables.decoratedElementType(field).node,
          FieldNotInitializedOrigin(source, node));
    }
  }

  bool _isPrefix(Expression e) =>
      e is SimpleIdentifier && e.staticElement is PrefixElement;

  bool _isUntypedParameter(NormalFormalParameter parameter) {
    if (parameter is SimpleFormalParameter) {
      return parameter.type == null;
    } else if (parameter is FieldFormalParameter) {
      return parameter.type == null;
    } else {
      return false;
    }
  }

  void _linkDecoratedTypeParameters(
      DecoratedType x, DecoratedType y, EdgeOrigin origin,
      {bool isUnion = true}) {
    for (int i = 0;
        i < x.positionalParameters.length && i < y.positionalParameters.length;
        i++) {
      _linkDecoratedTypes(
          x.positionalParameters[i], y.positionalParameters[i], origin,
          isUnion: isUnion);
    }
    for (var entry in x.namedParameters.entries) {
      var superParameterType = y.namedParameters[entry.key];
      if (superParameterType != null) {
        _linkDecoratedTypes(entry.value, y.namedParameters[entry.key], origin,
            isUnion: isUnion);
      }
    }
  }

  void _linkDecoratedTypes(DecoratedType x, DecoratedType y, EdgeOrigin origin,
      {bool isUnion = true}) {
    if (isUnion) {
      _graph.union(x.node, y.node, origin);
    } else {
      _graph.connect(x.node, y.node, origin, hard: true);
    }
    _linkDecoratedTypeParameters(x, y, origin, isUnion: isUnion);
    for (int i = 0;
        i < x.typeArguments.length && i < y.typeArguments.length;
        i++) {
      _linkDecoratedTypes(x.typeArguments[i], y.typeArguments[i], origin,
          isUnion: isUnion);
    }
    if (x.returnType != null && y.returnType != null) {
      _linkDecoratedTypes(x.returnType, y.returnType, origin, isUnion: isUnion);
    }
  }

  EdgeOrigin _makeEdgeOrigin(DecoratedType sourceType, Expression expression) {
    if (sourceType.type.isDynamic) {
      return DynamicAssignmentOrigin(source, expression);
    } else {
      ExpressionChecksOrigin expressionChecksOrigin = ExpressionChecksOrigin(
          source, expression, ExpressionChecks(expression.end));
      _variables.recordExpressionChecks(
          source, expression, expressionChecksOrigin);
      return expressionChecksOrigin;
    }
  }

  DecoratedType _makeNonNullableBoolType(Expression expression) {
    assert(expression.staticType.isDartCoreBool);
    var nullabilityNode =
        NullabilityNode.forInferredType(offset: expression.offset);
    _graph.makeNonNullableUnion(
        nullabilityNode, NonNullableBoolTypeOrigin(source, expression));
    return DecoratedType(typeProvider.boolType, nullabilityNode);
  }

  DecoratedType _makeNonNullLiteralType(Expression expression,
      {List<DecoratedType> typeArguments = const []}) {
    var nullabilityNode =
        NullabilityNode.forInferredType(offset: expression.offset);
    _graph.makeNonNullableUnion(
        nullabilityNode, LiteralOrigin(source, expression));
    return DecoratedType(expression.staticType, nullabilityNode,
        typeArguments: typeArguments);
  }

  DecoratedType _makeNullableDynamicType(AstNode astNode) {
    var decoratedType = DecoratedType.forImplicitType(
        typeProvider, typeProvider.dynamicType, _graph,
        offset: astNode.offset);
    _graph.makeNullable(
        decoratedType.node, AlwaysNullableTypeOrigin(source, astNode));
    return decoratedType;
  }

  DecoratedType _makeNullableVoidType(SimpleIdentifier astNode) {
    var decoratedType = DecoratedType.forImplicitType(
        typeProvider, typeProvider.voidType, _graph,
        offset: astNode.offset);
    _graph.makeNullable(
        decoratedType.node, AlwaysNullableTypeOrigin(source, astNode));
    return decoratedType;
  }

  NullabilityNode _nullabilityNodeForGLB(
      AstNode astNode, NullabilityNode leftNode, NullabilityNode rightNode) {
    var node = NullabilityNode.forGLB();
    var origin = GreatestLowerBoundOrigin(source, astNode);
    _graph.connect(leftNode, node, origin, guards: [rightNode]);
    _graph.connect(node, leftNode, origin);
    _graph.connect(node, rightNode, origin);
    return node;
  }

  DecoratedType _thisOrSuper(Expression node) {
    if (_currentClassOrExtension == null) {
      return null;
    }

    NullabilityNode makeNonNullableNode() {
      var nullabilityNode =
          NullabilityNode.forInferredType(offset: node.offset);
      _graph.makeNonNullableUnion(
          nullabilityNode, ThisOrSuperOrigin(source, node));
      return nullabilityNode;
    }

    if (_currentClassOrExtension is ClassElement) {
      final type = (_currentClassOrExtension as ClassElement).thisType;

      // Instantiate the type, and any type arguments, with non-nullable types,
      // because the type of `this` is always `ClassName<Param, Param, ...>`
      // with no `?`s.  (Even if some of the type parameters are allowed to be
      // instantiated with nullable types at runtime, a reference to `this`
      // can't be migrated in such a way that forces them to be nullable.)
      return DecoratedType(type, makeNonNullableNode(),
          typeArguments: type.typeArguments
              .map((t) => DecoratedType(t, makeNonNullableNode()))
              .toList());
    } else {
      assert(_currentClassOrExtension is ExtensionElement);
      final type = (_currentClassOrExtension as ExtensionElement).extendedType;

      if (type is InterfaceType) {
        return DecoratedType(
            type, NullabilityNode.forInferredType(offset: node.offset),
            typeArguments: type.typeArguments
                .map((t) => DecoratedType(
                    t, NullabilityNode.forInferredType(offset: node.offset)))
                .toList());
      } else {
        _unimplemented(node, 'extension of $type (${type.runtimeType}');
      }
    }
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

  /// Produce Future<flatten(T)> for some T, however, we would like to merely
  /// upcast T to that type if possible, skipping the flatten when not
  /// necessary.
  DecoratedType _wrapFuture(DecoratedType type, {@required int offset}) {
    if (type.type.isDartCoreNull || type.type.isBottom) {
      return _futureOf(type, offset: offset);
    }

    if (_typeSystem.isSubtypeOf(type.type, typeProvider.futureDynamicType)) {
      return _decoratedClassHierarchy.asInstanceOf(
          type, typeProvider.futureDynamicType.element);
    }

    return _futureOf(type, offset: offset);
  }
}

/// Implementation of [_checkAssignment] for [EdgeBuilder].
///
/// This has been moved to its own mixin to allow it to be more easily unit
/// tested.
mixin _AssignmentChecker {
  TypeProvider get typeProvider;

  DecoratedClassHierarchy get _decoratedClassHierarchy;

  TypeSystem get _typeSystem;

  /// Creates the necessary constraint(s) for an assignment from [source] to
  /// [destination].  [origin] should be used as the origin for any edges
  /// created.  [hard] indicates whether a hard edge should be created.
  void _checkAssignment(EdgeOrigin origin,
      {@required DecoratedType source,
      @required DecoratedType destination,
      @required bool hard,
      bool checkable = true}) {
    var sourceType = source.type;
    var destinationType = destination.type;
    if (!_typeSystem.isSubtypeOf(sourceType, destinationType)) {
      // Not a proper upcast assignment.
      if (_typeSystem.isSubtypeOf(destinationType, sourceType)) {
        // But rather a downcast.
        _checkDowncast(origin,
            source: source, destination: destination, hard: hard);
        return;
      }
      // A side cast. This may be an explicit side cast, or illegal code. There
      // is no nullability we can infer here.
      assert(
          _assumeNonNullabilityInCasts,
          'side cast not supported without assuming non-nullability:'
          ' $sourceType to $destinationType');
      _connect(source.node, destination.node, origin, hard: hard);
      return;
    }
    _connect(source.node, destination.node, origin,
        hard: hard, checkable: checkable);
    _checkAssignment_recursion(origin,
        source: source, destination: destination);
  }

  /// Does the recursive part of [_checkAssignment], visiting all of the types
  /// constituting [source] and [destination], and creating the appropriate
  /// edges between them.
  void _checkAssignment_recursion(EdgeOrigin origin,
      {@required DecoratedType source, @required DecoratedType destination}) {
    var sourceType = source.type;
    var destinationType = destination.type;
    assert(_typeSystem.isSubtypeOf(sourceType, destinationType));
    if (destinationType.isDartAsyncFutureOr) {
      var s1 = destination.typeArguments[0];
      if (sourceType.isDartAsyncFutureOr) {
        // This is a special case not in the subtyping spec.  The subtyping spec
        // covers this case by expanding the LHS first, which is fine but
        // leads to redundant edges (which might be confusing for users)
        // if T0 is FutureOr<S0> then:
        // - T0 <: T1 iff Future<S0> <: T1 and S0 <: T1
        // Since T1 is FutureOr<S1>, this is equivalent to:
        // - T0 <: T1 iff (Future<S0> <: Future<S1> or Future<S0> <: S1) and
        //                (S0 <: Future<S1> or S0 <: S1)
        // Which is equivalent to:
        // - T0 <: T1 iff (S0 <: S1 or Future<S0> <: S1) and
        //                (S0 <: Future<S1> or S0 <: S1)
        // Which is equivalent to (distributing the "and"):
        // - T0 <: T1 iff (S0 <: S1 and (S0 <: Future<S1> or S0 <: S1)) or
        //                (Future<S0> <: S1 and (S0 <: Future<S1> or S0 <: S1))
        // Which is equivalent to (distributing the "and"s):
        // - T0 <: T1 iff (S0 <: S1 and S0 <: Future<S1>) or
        //                (S0 <: S1 and S0 <: S1) or
        //                (Future<S0> <: S1 and S0 <: Future<S1>) or
        //                (Future<S0> <: S1 and S0 <: S1)
        // If S0 <: S1, the relation is satisfied.  Otherwise the only term that
        // matters is (Future<S0> <: S1 and S0 <: Future<S1>), so this is
        // equivalent to:
        // - T0 <: T1 iff S0 <: S1 or (Future<S0> <: S1 and S0 <: Future<S1>)
        // Let's consider whether there are any cases where the RHS of this "or"
        // can be satisfied but not the LHS.  That is, assume that
        // Future<S0> <: S1 and S0 <: Future<S1> hold, but not S0 <: S1.  S1
        // must not be a top type (otherwise S0 <: S1 would hold), so the only
        // way Future<S0> <: S1 can hold is if S1 is Future<A> or FutureOr<A>
        // for some A.  In either case, Future<S1> simplifies to Future<A>, so
        // we know that S0 <: Future<A>.  Also, in either case, Future<A> <: S1.
        // Combining these, we have that S0 <: S1, contradicting our assumption.
        // So the RHS of the "or" is redundant, and we can simplify to:
        // - S0 <: S1.
        var s0 = source.typeArguments[0];
        _checkAssignment(origin, source: s0, destination: s1, hard: false);
        return;
      }
      // (From the subtyping spec):
      // if T1 is FutureOr<S1> then T0 <: T1 iff any of the following hold:
      // - either T0 <: Future<S1>
      if (_typeSystem.isSubtypeOf(
          sourceType, typeProvider.futureType2(s1.type))) {
        // E.g. FutureOr<int> = (... as Future<int>)
        // This is handled by the InterfaceType logic below, since we treat
        // FutureOr as a supertype of Future.
      }
      // - or T0 <: S1
      else if (_typeSystem.isSubtypeOf(sourceType, s1.type)) {
        // E.g. FutureOr<int> = (... as int)
        _checkAssignment_recursion(origin, source: source, destination: s1);
        return;
      }
      // - or T0 is X0 and X0 has bound S0 and S0 <: T1
      // - or T0 is X0 & S0 and S0 <: T1
      else if (sourceType is TypeParameterType) {
        throw UnimplementedError('TODO(paulberry)');
      } else {
        // Not a subtype.  This should never happen, since we handle the
        // implicit downcast case above.
        assert(false, 'not a subtype');
      }
    }
    if (sourceType.isBottom || sourceType.isDartCoreNull) {
      // No further edges need to be created, since all types are trivially
      // supertypes of bottom (and of Null, in the pre-migration world).
    } else if (sourceType is TypeParameterType) {
      // Handle this before handling dynamic/object/void, to correctly infer
      // nullabilities in `Object o = T`.
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
    } else if (destinationType.isDynamic ||
        destinationType.isVoid ||
        destinationType.isDartCoreObject) {
      // No further edges need to be created, since all types are trivially
      // subtypes of dynamic, Object, and void, since all are treated as
      // equivalent to dynamic for subtyping purposes.
    } else if (sourceType is InterfaceType &&
        destinationType is InterfaceType) {
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
            hard: false,
            checkable: false);
      }
      for (var entry in destination.namedParameters.entries) {
        // Note: source and destination are swapped due to contravariance.
        _checkAssignment(origin,
            source: entry.value,
            destination: source.namedParameters[entry.key],
            hard: false,
            checkable: false);
      }
    } else if (destinationType.isDynamic || sourceType.isDynamic) {
      // ok; nothing further to do.
    } else if (destinationType is InterfaceType && sourceType is FunctionType) {
      // Either this is an upcast to Function or Object, or it is erroneous
      // code.  In either case we don't need to create any additional edges.
    } else {
      throw '$destination <= $source'; // TODO(paulberry)
    }
  }

  void _checkDowncast(EdgeOrigin origin,
      {@required DecoratedType source,
      @required DecoratedType destination,
      @required bool hard}) {
    var destinationType = destination.type;
    assert(_typeSystem.isSubtypeOf(destinationType, source.type));
    // Nullability should narrow to maintain subtype relationship.
    _connect(source.node, destination.node, origin, hard: hard);

    if (source.type.isDynamic ||
        source.type.isDartCoreObject ||
        source.type.isVoid) {
      if (destinationType is InterfaceType) {
        for (final param in destinationType.element.typeParameters) {
          assert(param.bound == null,
              'downcast to type parameters with bounds not supported');
        }
      }
      if (destinationType is FunctionType) {
        // Nothing else to do.
        return;
      }
    } else if (destinationType is TypeParameterType) {
      if (source.type is! TypeParameterType) {
        // Assume an assignment to the type parameter's bound.
        _checkAssignment(origin,
            source: source,
            destination: _getTypeParameterTypeBound(destination),
            hard: false);
      } else if (destinationType == source.type) {
        // Nothing to do.
        return;
      }
    } else if (destinationType is InterfaceType) {
      if (source.type is InterfaceType) {
        final target = _decoratedClassHierarchy.asInstanceOf(
            destination, source.type.element as ClassElement);
        for (var i = 0; i < source.typeArguments.length; ++i) {
          _checkDowncast(origin,
              source: source.typeArguments[i],
              destination: target.typeArguments[i],
              hard: false);
        }
      } else {
        assert(false,
            'downcasting from ${source.type.runtimeType} to interface type');
      }
    } else if (destinationType is FunctionType) {
      if (source.type.isDartCoreFunction) {
        // Nothing else to do.
        return;
      }
    } else {
      assert(
          false,
          'downcasting from ${source.type.runtimeType} to '
          '${destinationType.runtimeType} not supported. (${source.type} $destinationType)');
    }
  }

  void _connect(
      NullabilityNode source, NullabilityNode destination, EdgeOrigin origin,
      {bool hard = false, bool checkable = true});

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
