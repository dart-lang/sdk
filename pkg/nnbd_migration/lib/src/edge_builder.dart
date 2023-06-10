// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart' show TypeSystemImpl;
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/error/best_practices_verifier.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/fix_reason_target.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_origin.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/nullability_node_target.dart';
import 'package:nnbd_migration/src/utilities/built_value_transformer.dart';
import 'package:nnbd_migration/src/utilities/completeness_tracker.dart';
import 'package:nnbd_migration/src/utilities/hint_utils.dart';
import 'package:nnbd_migration/src/utilities/permissive_mode.dart';
import 'package:nnbd_migration/src/utilities/resolution_utils.dart';
import 'package:nnbd_migration/src/utilities/scoped_set.dart';
import 'package:nnbd_migration/src/utilities/where_not_null_transformer.dart';
import 'package:nnbd_migration/src/utilities/where_or_null_transformer.dart';
import 'package:nnbd_migration/src/variables.dart';

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
      {required DecoratedType source,
      required DecoratedType destination,
      required bool hard}) {
    super._checkAssignment(origin, FixReasonTarget.root,
        source: source, destination: destination, hard: hard);
  }

  @override
  void _connect(NullabilityNode? source, NullabilityNode? destination,
      EdgeOrigin origin, FixReasonTarget edgeTarget,
      {bool hard = false, bool checkable = true}) {
    _graph.connect(source, destination!, origin,
        hard: hard, checkable: checkable);
  }

  @override
  DecoratedType? _getCallMethodType(DecoratedType type) => null;

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
  final Variables _variables;

  final NullabilityMigrationListener? listener;

  final NullabilityMigrationInstrumentation? instrumentation;

  final NullabilityGraph _graph;

  TypeProvider typeProvider;

  @override
  final Source? source;

  @override
  final DecoratedClassHierarchy? _decoratedClassHierarchy;

  /// If we are visiting a function body or initializer, instance of flow
  /// analysis.  Otherwise `null`.
  FlowAnalysis<AstNode, Statement, Expression, PromotableElement,
      DecoratedType>? _flowAnalysis;

  /// If we are visiting a function body or initializer, assigned variable
  /// information used in flow analysis.  Otherwise `null`.
  AssignedVariables<AstNode, PromotableElement>? _assignedVariables;

  /// The outermost function or method being visited, or `null` if the visitor
  /// is not inside any function or method.
  ExecutableElement? _currentExecutable;

  /// The [DecoratedType] of the innermost function or method being visited, or
  /// `null` if the visitor is not inside any function or method.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// return statements.
  DecoratedType? _currentFunctionType;

  /// If the innermost enclosing executable is a constructor with field formal
  /// parameters, a map from each field's getter to the corresponding field
  /// formal parameter element.  Otherwise, an empty map.
  Map<PropertyAccessorElement, FieldFormalParameterElement>
      _currentFieldFormals = const {};

  FunctionExpression? _currentFunctionExpression;

  /// The [InterfaceElement] or [ExtensionElement] of the current interface
  /// or extension being visited, or null.
  Element? _currentInterfaceOrExtension;

  /// If an extension declaration is being visited, the decorated type of the
  /// type appearing in the `on` clause (this is the type of `this` inside the
  /// extension declaration).  Null if an extension declaration is not being
  /// visited.
  DecoratedType? _currentExtendedType;

  /// The [DecoratedType] of the innermost list or set literal being visited, or
  /// `null` if the visitor is not inside any list or set.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// ui as code elements.
  DecoratedType? _currentLiteralElementType;

  /// The key [DecoratedType] of the innermost map literal being visited, or
  /// `null` if the visitor is not inside any map.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// ui as code elements.
  DecoratedType? _currentMapKeyType;

  /// The value [DecoratedType] of the innermost map literal being visited, or
  /// `null` if the visitor is not inside any map.
  ///
  /// This is needed to construct the appropriate nullability constraints for
  /// ui as code elements.
  DecoratedType? _currentMapValueType;

  /// Information about the most recently visited binary expression whose
  /// boolean value could possibly affect nullability analysis.
  _ConditionInfo? _conditionInfo;

  /// The set of nullability nodes that would have to be `nullable` for the code
  /// currently being visited to be reachable.
  ///
  /// Guard variables are attached to the left hand side of any generated
  /// constraints, so that constraints do not take effect if they come from
  /// code that can be proven unreachable by the migration tool.
  final _guards = <NullabilityNode?>[];

  /// The scope of locals (parameters, variables) that are post-dominated by the
  /// current node as we walk the AST. We use a [_ScopedLocalSet] so that outer
  /// scopes may track their post-dominators separately from inner scopes.
  ///
  /// Note that this is not guaranteed to be complete. It is used to make hard
  /// edges on a best-effort basis.
  var _postDominatedLocals = ScopedSet<Element>();

  /// Map whose keys are expressions of the form `a?.b` on the LHS of
  /// assignments, and whose values are the nullability nodes corresponding to
  /// the expression preceding `?.`.  These are needed in order to properly
  /// analyze expressions like `a?.b += c`, since the type of the compound
  /// assignment is nullable if the type of the expression preceding `?.` is
  /// nullable.
  final Map<Expression, NullabilityNode?> _conditionalNodes = {};

  /// If we are visiting a cascade expression, the decorated type of the target
  /// of the cascade.  Otherwise `null`.
  DecoratedType? _currentCascadeTargetType;

  /// While visiting a class declaration, set of class fields that lack
  /// initializers at their declaration sites.
  Set<FieldElement?>? _fieldsNotInitializedAtDeclaration;

  /// While visiting a constructor, set of class fields that lack initializers
  /// at their declaration sites *and* for which we haven't yet found an
  /// initializer in the constructor declaration.
  Set<FieldElement?>? _fieldsNotInitializedByConstructor;

  /// Current nesting depth of [visitNamedType]
  int _typeNameNesting = 0;

  final Set<PromotableElement> _lateHintedLocals = {};

  final Map<Token, HintComment?> _nullCheckHints = {};

  /// Helper that assists us in transforming Iterable methods to their "OrNull"
  /// equivalents.
  final WhereOrNullTransformer _whereOrNullTransformer;

  /// Helper that assists us in transforming calls to `Iterable.where` to
  /// `Iterable.whereNotNull`.
  final WhereNotNullTransformer _whereNotNullTransformer;

  /// Deferred processing that should be performed once we have finished
  /// evaluating the decorated type of a method invocation.
  final Map<MethodInvocation, DecoratedType Function(DecoratedType?)>
      _deferredMethodInvocationProcessing = {};

  /// If we are visiting a local function or closure, the set of local variables
  /// assigned to so far inside it.  Otherwise `null`.
  Set<Element>? _elementsWrittenToInLocalFunction;

  final LibraryElement _library;

  EdgeBuilder(this.typeProvider, this._typeSystem, this._variables, this._graph,
      this.source, this.listener, this._decoratedClassHierarchy, this._library,
      {this.instrumentation})
      : _inheritanceManager = InheritanceManager3(),
        _whereOrNullTransformer =
            WhereOrNullTransformer(typeProvider, _typeSystem),
        _whereNotNullTransformer =
            WhereNotNullTransformer(typeProvider, _typeSystem);

  /// The synthetic element we use as a stand-in for `this` when analyzing
  /// extension methods.
  Element get _extensionThis => DynamicElementImpl.instance;

  /// Gets the decorated type of [element] from [_variables], performing any
  /// necessary substitutions.
  ///
  /// [node] is used as the AST node for the edge origin if any graph edges need
  /// to be created.  [targetType], if provided, indicates the type of the
  /// target (receiver) for a method, getter, or setter invocation.
  /// [targetExpression], if provided, is the expression for the target
  /// (receiver) for a method, getter, or setter invocation.
  DecoratedType getOrComputeElementType(AstNode node, Element element,
      {DecoratedType? targetType,
      Expression? targetExpression,
      bool isNullAware = false}) {
    Map<TypeParameterElement, DecoratedType>? substitution;
    Element? baseElement = element.declaration;
    if (targetType != null) {
      var enclosingElement = baseElement!.enclosingElement;
      if (enclosingElement is InterfaceElement) {
        if (targetType.type.explicitBound is InterfaceType &&
            enclosingElement.typeParameters.isNotEmpty) {
          substitution = _decoratedClassHierarchy!
              .asInstanceOf(targetType, enclosingElement)
              .asSubstitution;
        }
      } else {
        assert(enclosingElement is ExtensionElement);
        final extensionElement = enclosingElement as ExtensionElement;
        // The semantics of calling an extension method or extension property
        // are essentially the same as calling a static function where the
        // receiver is passed as an invisible `this` parameter whose type is the
        // extension's "on" type.  If the extension declaration has type
        // parameters, they behave like inferred type parameters of the static
        // function.
        //
        // So what we need to do is (1) create a set of DecoratedTypes to
        // represent the inferred types of the type parameters, (2) ensure that
        // the receiver type is assignable to "on" type (with those decorated
        // types substituted into it), and (3) substitute those decorated types
        // into the declared type of the extension method or extension property,
        // so that the caller will match up parameter types and the return type
        // appropriately.
        //
        // Taking each step in turn:
        // (1) create a set of decorated types to represent the inferred types
        // of the type parameters.  Note that we must make sure each of these
        // types satisfies its associated bound.
        var typeParameters = extensionElement.typeParameters;
        if (typeParameters.isNotEmpty) {
          var preMigrationSubstitution = (element as Member).substitution.map;
          substitution = {};
          var target = NullabilityNodeTarget.text('extension');
          for (int i = 0; i < typeParameters.length; i++) {
            var typeParameter = typeParameters[i];
            var decoratedTypeArgument = DecoratedType.forImplicitType(
                typeProvider,
                preMigrationSubstitution[typeParameter],
                _graph,
                target.typeArgument(i));
            substitution[typeParameter] = decoratedTypeArgument;
            var edgeOrigin =
                InferredTypeParameterInstantiationOrigin(source, node);
            _checkAssignment(edgeOrigin, FixReasonTarget.root,
                source: decoratedTypeArgument,
                destination:
                    _variables.decoratedTypeParameterBound(typeParameter)!,
                hard: true);
          }
        }
        // (2) ensure that the receiver type is assignable to "on" type (with
        // those decorated types substituted into it)
        var onType = _variables.decoratedElementType(extensionElement);
        if (substitution != null) {
          onType = onType.substitute(substitution);
        }
        _checkAssignment(InferredTypeParameterInstantiationOrigin(source, node),
            FixReasonTarget.root,
            source: targetType,
            destination: onType,
            hard: !isNullAware &&
                (targetExpression == null ||
                    _isReferenceInScope(targetExpression)));
        // (3) substitute those decorated types into the declared type of the
        // extension method or extension property, so that the caller will match
        // up parameter types and the return type appropriately.
        //
        // There's nothing more we need to do here.  The substitution below
        // will do the job.
      }
    }
    DecoratedType decoratedBaseType;
    if (baseElement is PropertyAccessorElement &&
        baseElement.isSynthetic &&
        !baseElement.variable.isSynthetic) {
      var variable = baseElement.variable;
      var decoratedElementType = _variables.decoratedElementType(variable);
      if (baseElement.isGetter) {
        var target = NullabilityNodeTarget.text('getter function');
        decoratedBaseType = DecoratedType(
            baseElement.type, NullabilityNode.forInferredType(target),
            returnType: decoratedElementType);
      } else {
        assert(baseElement.isSetter);
        var target = NullabilityNodeTarget.text('setter function');
        decoratedBaseType = DecoratedType(
            baseElement.type, NullabilityNode.forInferredType(target),
            positionalParameters: [decoratedElementType],
            returnType: DecoratedType(VoidTypeImpl.instance,
                NullabilityNode.forInferredType(target.returnType())));
      }
    } else {
      decoratedBaseType = _variables.decoratedElementType(baseElement!);
    }
    if (substitution != null) {
      return decoratedBaseType.substitute(substitution);
    } else {
      return decoratedBaseType;
    }
  }

  @override
  // TODO(srawlins): Theoretically, edges should be connected between arguments
  // and parameters, as in an instance creation. It is quite rare though, to
  // declare a class and use it as an annotation in the same package.
  DecoratedType? visitAnnotation(Annotation node) {
    var previousFlowAnalysis = _flowAnalysis;
    var previousAssignedVariables = _assignedVariables;
    if (_flowAnalysis == null) {
      _assignedVariables = AssignedVariables();
      // Note: we are using flow analysis to help us track true nullabilities;
      // it's not necessary to replicate old bugs.  So we pass `true` for
      // `respectImplicitlyTypedVarInitializers`.
      _flowAnalysis = FlowAnalysis<AstNode, Statement, Expression,
              PromotableElement, DecoratedType>(
          DecoratedTypeOperations(
              _typeSystem, typeProvider, _variables, _graph),
          _assignedVariables!,
          respectImplicitlyTypedVarInitializers: true);
    }
    try {
      _dispatch(node.constructorName);
      _dispatchList(node.arguments?.arguments);
    } finally {
      _flowAnalysis = previousFlowAnalysis;
      _assignedVariables = previousAssignedVariables;
    }
    annotationVisited(node);
    return null;
  }

  @override
  DecoratedType visitAsExpression(AsExpression node) {
    if (BestPracticesVerifier.isUnnecessaryCast(
        node, _typeSystem as TypeSystemImpl)) {
      _variables.recordUnnecessaryCast(source, node);
    }
    _dispatch(node.type);
    final typeNode = _variables.decoratedTypeAnnotation(source, node.type);
    _handleAssignment(node.expression, destinationType: typeNode);
    _flowAnalysis!.asExpression_end(node.expression, typeNode);
    return typeNode;
  }

  @override
  DecoratedType? visitAssertInitializer(AssertInitializer node) {
    _flowAnalysis!.assert_begin();
    _checkExpressionNotNull(node.condition);
    if (identical(_conditionInfo?.condition, node.condition)) {
      var intentNode = _conditionInfo!.trueDemonstratesNonNullIntent;
      if (intentNode != null && _conditionInfo!.postDominatingIntent!) {
        _graph.makeNonNullable(_conditionInfo!.trueDemonstratesNonNullIntent,
            NonNullAssertionOrigin(source, node));
      }
    }
    _flowAnalysis!.assert_afterCondition(node.condition);
    _dispatch(node.message);
    _flowAnalysis!.assert_end();
    return null;
  }

  @override
  DecoratedType? visitAssertStatement(AssertStatement node) {
    _flowAnalysis!.assert_begin();
    _checkExpressionNotNull(node.condition);
    if (identical(_conditionInfo?.condition, node.condition)) {
      var intentNode = _conditionInfo!.trueDemonstratesNonNullIntent;
      if (intentNode != null && _conditionInfo!.postDominatingIntent!) {
        _graph.makeNonNullable(_conditionInfo!.trueDemonstratesNonNullIntent,
            NonNullAssertionOrigin(source, node));
      }
    }
    _flowAnalysis!.assert_afterCondition(node.condition);
    _dispatch(node.message);
    _flowAnalysis!.assert_end();
    return null;
  }

  @override
  DecoratedType? visitAssignmentExpression(AssignmentExpression node) {
    bool isQuestionAssign = false;
    bool isCompound = false;
    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ) {
      isQuestionAssign = true;
    } else if (node.operator.type != TokenType.EQ) {
      isCompound = true;
    }

    var sourceIsSetupCall = false;
    if (node.leftHandSide is SimpleIdentifier &&
        _isCurrentFunctionExpressionFoundInTestSetUpCall()) {
      var assignee =
          getWriteOrReadElement(node.leftHandSide as SimpleIdentifier)!;
      var enclosingElementOfCurrentFunction =
          _currentFunctionExpression!.declaredElement!.enclosingElement;
      if (enclosingElementOfCurrentFunction == assignee.enclosingElement) {
        // [node]'s enclosing function is a function expression passed directly
        // to a call to the test package's `setUp` function, and [node] is an
        // assignment to a variable declared in the same scope as the call to
        // `setUp`.
        sourceIsSetupCall = true;
      }
    }

    var isInjectorGetAssignment = _isInjectorGetCall(node.rightHandSide);

    var expressionType = _handleAssignment(node.rightHandSide,
        assignmentExpression: node,
        compoundOperatorInfo: isCompound ? node : null,
        questionAssignNode: isQuestionAssign ? node : null,
        sourceIsSetupCall: sourceIsSetupCall,
        isInjectorGetAssignment: isInjectorGetAssignment);
    var conditionalNode = _conditionalNodes[node.leftHandSide];
    if (conditionalNode != null) {
      expressionType = expressionType!.withNode(
          NullabilityNode.forLUB(conditionalNode, expressionType.node));
      _variables.recordDecoratedExpressionType(node, expressionType);
    }

    return expressionType;
  }

  @override
  DecoratedType visitAwaitExpression(AwaitExpression node) {
    var expressionType = _dispatch(node.expression)!;
    var type = expressionType.type!;
    if (type.isDartCoreNull) {
      // Nothing to do; awaiting `null` produces `null`.
    } else if (_typeSystem.isSubtypeOf(type, typeProvider.futureDynamicType)) {
      expressionType = _decoratedClassHierarchy!
          .asInstanceOf(expressionType, typeProvider.futureElement)
          .typeArguments[0]!;
    } else if (type.isDartAsyncFutureOr) {
      expressionType = expressionType.typeArguments[0]!;
    }
    return expressionType;
  }

  @override
  DecoratedType visitBinaryExpression(BinaryExpression node) {
    var operatorType = node.operator.type;
    var leftOperand = node.leftOperand;
    var rightOperand = node.rightOperand;
    if (operatorType == TokenType.EQ_EQ || operatorType == TokenType.BANG_EQ) {
      var leftType = _dispatch(leftOperand)!;
      _graph.connectDummy(leftType.node, DummyOrigin(source, node));
      var equalityInfo =
          _flowAnalysis!.equalityOperand_end(leftOperand, leftType);
      var rightType = _dispatch(rightOperand)!;
      _graph.connectDummy(rightType.node, DummyOrigin(source, node));
      bool notEqual = operatorType == TokenType.BANG_EQ;
      _flowAnalysis!.equalityOperation_end(node, equalityInfo,
          _flowAnalysis!.equalityOperand_end(rightOperand, rightType),
          notEqual: notEqual);

      void buildNullConditionInfo(NullLiteral nullLiteral,
          Expression otherOperand, DecoratedType otherType) {
        assert(nullLiteral != otherOperand);
        // TODO(paulberry): only set falseChecksNonNull in unconditional
        // control flow
        // TODO(paulberry): figure out what the rules for isPure should be.
        bool isPure = otherOperand is SimpleIdentifier;
        var otherNode = otherType.node;
        var otherTypeType = otherType.type;
        if (otherTypeType is TypeParameterType) {
          var boundNullability =
              DecoratedTypeParameterBounds.current!.get(otherTypeType.element);
          if (boundNullability != null) {
            otherNode =
                NullabilityNode.forLUB(otherNode, boundNullability.node);
          }
        }
        var conditionInfo = _ConditionInfo(node,
            isPure: isPure,
            postDominatingIntent: _isReferenceInScope(otherOperand),
            trueGuard: otherNode,
            falseDemonstratesNonNullIntent: otherNode);
        _conditionInfo = notEqual ? conditionInfo.not(node) : conditionInfo;
      }

      if (rightOperand is NullLiteral) {
        buildNullConditionInfo(rightOperand, leftOperand, leftType);
        _graph.makeNullable(leftType.node, NullAwareAccessOrigin(source, node));
      } else if (leftOperand is NullLiteral) {
        buildNullConditionInfo(leftOperand, rightOperand, rightType);
        _graph.makeNullable(
            rightType.node, NullAwareAccessOrigin(source, node));
      }

      return _makeNonNullableBoolType(node);
    } else if (operatorType == TokenType.AMPERSAND_AMPERSAND ||
        operatorType == TokenType.BAR_BAR) {
      bool isAnd = operatorType == TokenType.AMPERSAND_AMPERSAND;
      _flowAnalysis!.logicalBinaryOp_begin();
      _checkExpressionNotNull(leftOperand);
      _flowAnalysis!
          .logicalBinaryOp_rightBegin(node.leftOperand, node, isAnd: isAnd);
      _postDominatedLocals.doScoped(
          action: () => _checkExpressionNotNull(rightOperand));
      _flowAnalysis!.logicalBinaryOp_end(node, rightOperand, isAnd: isAnd);
      return _makeNonNullableBoolType(node);
    } else if (operatorType == TokenType.QUESTION_QUESTION) {
      DecoratedType expressionType;
      var leftType = _dispatch(leftOperand)!;
      _flowAnalysis!.ifNullExpression_rightBegin(node.leftOperand, leftType);
      try {
        _guards.add(leftType.node);
        DecoratedType? rightType;
        _postDominatedLocals.doScoped(action: () {
          rightType = _dispatch(rightOperand);
        });
        var ifNullNode = NullabilityNode.forIfNotNull(node);
        expressionType = _decorateUpperOrLowerBound(
            node, node.staticType, leftType, rightType!, true,
            node: ifNullNode);
        _connect(rightType!.node, expressionType.node,
            IfNullOrigin(source, node), null);
      } finally {
        _flowAnalysis!.ifNullExpression_end();
        _guards.removeLast();
      }
      _variables.recordDecoratedExpressionType(node, expressionType);
      return expressionType;
    } else if (operatorType.isUserDefinableOperator) {
      var targetType = _checkExpressionNotNull(leftOperand);
      var callee = node.staticElement;
      if (callee == null) {
        _dispatch(rightOperand);
        return _makeNullableDynamicType(node);
      } else {
        var calleeType = getOrComputeElementType(node, callee,
            targetType: targetType, targetExpression: leftOperand);
        assert(calleeType.positionalParameters!.isNotEmpty); // TODO(paulberry)
        _handleAssignment(rightOperand,
            destinationType: calleeType.positionalParameters![0]);
        return _fixNumericTypes(calleeType.returnType!, node.staticType);
      }
    } else {
      // TODO(paulberry)
      _dispatch(leftOperand);
      _dispatch(rightOperand);
      _unimplemented(
          node, 'Binary expression with operator ${node.operator.lexeme}');
    }
  }

  @override
  DecoratedType visitBooleanLiteral(BooleanLiteral node) {
    _flowAnalysis!.booleanLiteral(node, node.value);
    return _makeNonNullLiteralType(node);
  }

  @override
  DecoratedType? visitBreakStatement(BreakStatement node) {
    _flowAnalysis!.handleBreak(FlowAnalysisHelper.getLabelTarget(
        node, node.label?.staticElement as LabelElement?,
        isBreak: true));
    // Later statements no longer post-dominate the declarations because we
    // exited (or, in parent scopes, conditionally exited).
    // TODO(mfairhurst): don't clear post-dominators beyond the current loop.
    _postDominatedLocals.clearEachScope();

    return null;
  }

  @override
  DecoratedType? visitCascadeExpression(CascadeExpression node) {
    var oldCascadeTargetType = _currentCascadeTargetType;
    try {
      _currentCascadeTargetType = _checkExpressionNotNull(node.target);
      _dispatchList(node.cascadeSections);
      return _currentCascadeTargetType;
    } finally {
      _currentCascadeTargetType = oldCascadeTargetType;
    }
  }

  @override
  DecoratedType? visitCatchClause(CatchClause node) {
    _flowAnalysis!.tryCatchStatement_catchBegin(
        node.exceptionParameter?.declaredElement,
        node.stackTraceParameter?.declaredElement);
    _dispatch(node.exceptionType);
    // The catch clause may not execute, so create a new scope for
    // post-dominators.
    _postDominatedLocals.doScoped(action: () => _dispatch(node.body));
    _flowAnalysis!.tryCatchStatement_catchEnd();
    return null;
  }

  @override
  DecoratedType? visitClassDeclaration(ClassDeclaration node) {
    visitClassOrMixinOrExtensionDeclaration(node);
    _dispatch(node.extendsClause);
    _dispatch(node.implementsClause);
    _dispatch(node.withClause);
    _dispatch(node.typeParameters);
    return null;
  }

  DecoratedType? visitClassOrMixinOrExtensionDeclaration(
      CompilationUnitMember node) {
    assert(node is ClassDeclaration ||
        node is ExtensionDeclaration ||
        node is MixinDeclaration);
    try {
      _currentInterfaceOrExtension = node.declaredElement;

      List<ClassMember> members;
      if (node is ClassDeclaration) {
        members = node.members;
      } else if (node is ExtensionDeclaration) {
        members = node.members;
      } else {
        members = (node as MixinDeclaration).members;
      }

      _fieldsNotInitializedAtDeclaration = {
        for (var member in members)
          if (member is FieldDeclaration &&
              _variables.getLateHint(source, member.fields) == null)
            for (var field in member.fields.variables)
              if (!field.declaredElement!.isStatic && field.initializer == null)
                field.declaredElement as FieldElement?
      };
      if (_currentInterfaceOrExtension is ClassElement &&
          (_currentInterfaceOrExtension as ClassElement)
                  .unnamedConstructor
                  ?.isSynthetic ==
              true) {
        _handleUninitializedFields(node, _fieldsNotInitializedAtDeclaration!);
      }
      _dispatchList(node.metadata);
      _dispatchList(members);
      _fieldsNotInitializedAtDeclaration = null;
    } finally {
      _currentInterfaceOrExtension = null;
    }
    return null;
  }

  @override
  DecoratedType? visitClassTypeAlias(ClassTypeAlias node) {
    _dispatch(node.superclass);
    _dispatch(node.implementsClause);
    _dispatch(node.withClause);
    var classElement = node.declaredElement!;
    var supertype = classElement.supertype!;
    var superElement = supertype.element;
    for (var constructorElement in classElement.constructors) {
      assert(constructorElement.isSynthetic);
      var superConstructorElement =
          superElement.getNamedConstructor(constructorElement.name)!;
      var constructorDecoratedType = _variables
          .decoratedElementType(constructorElement)
          .substitute(_decoratedClassHierarchy!
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
  DecoratedType? visitComment(Comment node) {
    // Ignore comments.
    return null;
  }

  @override
  DecoratedType visitConditionalExpression(ConditionalExpression node) {
    _flowAnalysis!.conditional_conditionBegin();
    _checkExpressionNotNull(node.condition);
    NullabilityNode? trueGuard;
    NullabilityNode? falseGuard;
    if (identical(_conditionInfo?.condition, node.condition)) {
      trueGuard = _conditionInfo!.trueGuard;
      falseGuard = _conditionInfo!.falseGuard;
      _variables.recordConditionalDiscard(source, node,
          ConditionalDiscard(trueGuard, falseGuard, _conditionInfo!.isPure));
    }

    late DecoratedType thenType;
    late DecoratedType elseType;

    // Post-dominators diverge as we branch in the conditional.
    // Note: we don't have to create a scope for each branch because they can't
    // define variables.
    _postDominatedLocals.doScoped(action: () {
      _flowAnalysis!.conditional_thenBegin(node.condition, node);
      if (trueGuard != null) {
        _guards.add(trueGuard);
      }
      try {
        thenType = _dispatch(node.thenExpression)!;
        if (trueGuard != null) {
          thenType = thenType
              .withNode(_nullabilityNodeForGLB(node, thenType.node, trueGuard));
        }
      } finally {
        if (trueGuard != null) {
          _guards.removeLast();
        }
      }
      _flowAnalysis!.conditional_elseBegin(node.thenExpression, thenType);
      if (falseGuard != null) {
        _guards.add(falseGuard);
      }
      try {
        elseType = _dispatch(node.elseExpression)!;
        if (falseGuard != null) {
          elseType = elseType.withNode(
              _nullabilityNodeForGLB(node, elseType.node, falseGuard));
        }
      } finally {
        if (falseGuard != null) {
          _guards.removeLast();
        }
      }
    });

    var overallType = _decorateUpperOrLowerBound(
        node, node.staticType, thenType, elseType, true);
    _flowAnalysis!
        .conditional_end(node, overallType, node.elseExpression, elseType);
    _variables.recordDecoratedExpressionType(node, overallType);
    return overallType;
  }

  @override
  DecoratedType? visitConstructorDeclaration(ConstructorDeclaration node) {
    _fieldsNotInitializedByConstructor =
        _fieldsNotInitializedAtDeclaration!.toSet();
    _dispatch(node.redirectedConstructor?.type.typeArguments);
    _handleExecutableDeclaration(
        node,
        node.declaredElement!,
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
  DecoratedType? visitConstructorFieldInitializer(
      ConstructorFieldInitializer node) {
    _fieldsNotInitializedByConstructor!.remove(node.fieldName.staticElement);
    _handleAssignment(node.expression,
        destinationType:
            getOrComputeElementType(node, node.fieldName.staticElement!));
    return null;
  }

  @override
  DecoratedType? visitContinueStatement(ContinueStatement node) {
    _flowAnalysis!.handleContinue(FlowAnalysisHelper.getLabelTarget(
        node, node.label?.staticElement as LabelElement?,
        isBreak: false));
    // Later statements no longer post-dominate the declarations because we
    // exited (or, in parent scopes, conditionally exited).
    // TODO(mfairhurst): don't clear post-dominators beyond the current loop.
    _postDominatedLocals.clearEachScope();

    return null;
  }

  @override
  DecoratedType? visitDefaultFormalParameter(DefaultFormalParameter node) {
    _dispatch(node.parameter);
    var defaultValue = node.defaultValue;
    var declaredElement = node.declaredElement;
    if (defaultValue == null) {
      if (declaredElement!.hasRequired) {
        // Nothing to do; the implicit default value of `null` will never be
        // reached.
      } else if (_variables.getRequiredHint(source, node) != null) {
        // Nothing to do; assume the implicit default value of `null` will never
        // be reached.
      } else {
        var enclosingElement = declaredElement.enclosingElement;
        if (enclosingElement is ConstructorElement &&
            enclosingElement.isFactory &&
            enclosingElement.redirectedConstructor != null) {
          // Redirecting factory constructors inherit their parameters' default
          // values from the constructors they redirect to, so the lack of a
          // default value doesn't mean the parameter has to be nullable.
        } else {
          _graph.makeNullable(
              getOrComputeElementType(node, declaredElement).node,
              OptionalFormalParameterOrigin(source, node));
        }
      }
    } else {
      _handleAssignment(defaultValue,
          destinationType: getOrComputeElementType(node, declaredElement!),
          fromDefaultValue: true);
    }
    return null;
  }

  @override
  DecoratedType? visitDoStatement(DoStatement node) {
    _flowAnalysis!.doStatement_bodyBegin(node);
    _dispatch(node.body);
    _flowAnalysis!.doStatement_conditionBegin();
    _checkExpressionNotNull(node.condition);
    _flowAnalysis!.doStatement_end(node.condition);
    return null;
  }

  @override
  DecoratedType visitDoubleLiteral(DoubleLiteral node) {
    return _makeNonNullLiteralType(node);
  }

  @override
  DecoratedType? visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (_currentFunctionType == null) {
      _unimplemented(
          node,
          'ExpressionFunctionBody with no current function '
          '(parent is ${node.parent.runtimeType})');
    }
    _handleAssignment(node.expression,
        destinationType: _currentFunctionType!.returnType,
        wrapFuture: node.isAsynchronous);
    return null;
  }

  @override
  DecoratedType visitExpressionStatement(ExpressionStatement node) {
    var decoratedType = _dispatch(node.expression)!;
    if (node.expression is! CascadeExpression) {
      // Don't add a dummy edge for cascade expression, since
      // it forces the target of cascade to be nullable, which
      // is almost always wrong.
      _graph.connectDummy(decoratedType.node, DummyOrigin(source, node));
    }
    return decoratedType;
  }

  DecoratedType? visitExtensionDeclaration(ExtensionDeclaration node) {
    _dispatch(node.typeParameters);
    _dispatch(node.extendedType);
    _currentExtendedType =
        _variables.decoratedTypeAnnotation(source, node.extendedType);
    visitClassOrMixinOrExtensionDeclaration(node);
    _currentExtendedType = null;
    return null;
  }

  @override
  DecoratedType? visitExtensionOverride(ExtensionOverride node) {
    return _dispatch(node.argumentList.arguments.single);
  }

  @override
  DecoratedType? visitFieldFormalParameter(FieldFormalParameter node) {
    _dispatchList(node.metadata);
    _dispatch(node.parameters);
    var parameterElement = node.declaredElement as FieldFormalParameterElement;
    var parameterType = _variables.decoratedElementType(parameterElement);
    var field = parameterElement.field;
    if (field != null) {
      _fieldsNotInitializedByConstructor!.remove(field);
      var fieldType = _variables.decoratedElementType(field);
      var origin = FieldFormalParameterOrigin(source, node);
      if (node.type == null) {
        _linkDecoratedTypes(parameterType, fieldType, origin, isUnion: false);
        _checkAssignment(origin, FixReasonTarget.root,
            source: fieldType, destination: parameterType, hard: false);
      } else {
        _dispatch(node.type);
        _checkAssignment(origin, FixReasonTarget.root,
            source: parameterType, destination: fieldType, hard: true);
      }
    }

    return null;
  }

  @override
  DecoratedType? visitForElement(ForElement node) {
    _handleForLoopParts(node, node.forLoopParts, node.body,
        (body) => _handleCollectionElement(body as CollectionElement));
    return null;
  }

  @override
  DecoratedType? visitForStatement(ForStatement node) {
    _handleForLoopParts(
        node, node.forLoopParts, node.body, (body) => _dispatch(body));
    return null;
  }

  @override
  DecoratedType? visitFunctionDeclaration(FunctionDeclaration node) {
    _dispatchList(node.metadata);
    _dispatch(node.returnType);
    if (_flowAnalysis != null) {
      // This is a local function.
      var previousPostDominatedLocals = _postDominatedLocals;
      var previousElementsWrittenToInLocalFunction =
          _elementsWrittenToInLocalFunction;
      try {
        _elementsWrittenToInLocalFunction = {};
        _postDominatedLocals = ScopedSet<Element>();
        _flowAnalysis!.functionExpression_begin(node);
        _dispatch(node.functionExpression);
        _flowAnalysis!.functionExpression_end();
      } finally {
        for (var element in _elementsWrittenToInLocalFunction!) {
          previousElementsWrittenToInLocalFunction?.add(element);
          previousPostDominatedLocals.removeFromAllScopes(element);
        }
        _elementsWrittenToInLocalFunction =
            previousElementsWrittenToInLocalFunction;
        _postDominatedLocals = previousPostDominatedLocals;
      }
    } else {
      _createFlowAnalysis(node, node.functionExpression.parameters);
      // Initialize a new postDominator scope that contains only the parameters.
      try {
        _dispatch(node.functionExpression);
        _flowAnalysis!.finish();
      } finally {
        _flowAnalysis = null;
        _assignedVariables = null;
      }
      var declaredElement = node.declaredElement;
      if (declaredElement is PropertyAccessorElement) {
        if (declaredElement.isGetter) {
          var setter = declaredElement.correspondingSetter;
          if (setter != null) {
            _handleGetterSetterCorrespondence(
                node, null, declaredElement, setter.declaration);
          }
        } else {
          assert(declaredElement.isSetter);
          var getter = declaredElement.correspondingGetter;
          if (getter != null) {
            _handleGetterSetterCorrespondence(
                node, null, getter.declaration, declaredElement);
          }
        }
      } else if (declaredElement != null && declaredElement.isPublic) {
        _makeArgumentsNullable(declaredElement, node);
      }
    }
    return null;
  }

  @override
  DecoratedType? visitFunctionExpression(FunctionExpression node) {
    // TODO(mfairhurst): enable edge builder "_insideFunction" hard edge tests.
    _dispatch(node.parameters);
    _dispatch(node.typeParameters);
    if (node.parent is! FunctionDeclaration) {
      _flowAnalysis!.functionExpression_begin(node);
    }
    _addParametersToFlowAnalysis(node.parameters);
    var previousFunction = _currentFunctionExpression;
    var previousFunctionType = _currentFunctionType;
    var previousFieldFormals = _currentFieldFormals;
    _currentFunctionExpression = node;
    _currentFunctionType =
        _variables.decoratedElementType(node.declaredElement!);
    _currentFieldFormals = const {};
    var previousPostDominatedLocals = _postDominatedLocals;
    var previousElementsWrittenToInLocalFunction =
        _elementsWrittenToInLocalFunction;
    var previousExecutable = _currentExecutable;
    _currentExecutable ??= node.declaredElement;
    try {
      if (node.parent is! FunctionDeclaration) {
        _elementsWrittenToInLocalFunction = {};
      }
      _postDominatedLocals = ScopedSet<Element>();
      _postDominatedLocals.doScoped(
          elements: node.declaredElement!.parameters,
          action: () => _dispatch(node.body));
      _variables.recordDecoratedExpressionType(node, _currentFunctionType);
      return _currentFunctionType;
    } finally {
      if (node.parent is! FunctionDeclaration) {
        _flowAnalysis!.functionExpression_end();
        for (var element in _elementsWrittenToInLocalFunction!) {
          previousElementsWrittenToInLocalFunction?.add(element);
          previousPostDominatedLocals.removeFromAllScopes(element);
        }
        _elementsWrittenToInLocalFunction =
            previousElementsWrittenToInLocalFunction;
      }
      _currentFunctionType = previousFunctionType;
      _currentFieldFormals = previousFieldFormals;
      _currentFunctionExpression = previousFunction;
      _postDominatedLocals = previousPostDominatedLocals;
      _currentExecutable = previousExecutable;
    }
  }

  @override
  DecoratedType? visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    final argumentList = node.argumentList;
    final typeArguments = node.typeArguments;
    _dispatch(typeArguments);
    DecoratedType calleeType = _checkExpressionNotNull(node.function);
    DecoratedType? result;
    if (calleeType.type is FunctionType) {
      result = _handleInvocationArguments(node, argumentList.arguments,
          typeArguments, node.typeArgumentTypes, calleeType, null,
          invokeType: node.staticInvokeType);
    } else {
      // Invocation of type `dynamic` or `Function`.
      _dispatch(argumentList);
      result = _makeNullableDynamicType(node);
    }
    return result;
  }

  @override
  DecoratedType? visitIfElement(IfElement node) {
    _flowAnalysis!.ifStatement_conditionBegin();
    _checkExpressionNotNull(node.expression);
    _flowAnalysis!.ifStatement_thenBegin(node.expression, node);
    NullabilityNode? trueGuard;
    NullabilityNode? falseGuard;
    if (identical(_conditionInfo?.condition, node.expression)) {
      trueGuard = _conditionInfo!.trueGuard;
      falseGuard = _conditionInfo!.falseGuard;
      _variables.recordConditionalDiscard(source, node,
          ConditionalDiscard(trueGuard, falseGuard, _conditionInfo!.isPure));
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
      _flowAnalysis!.ifStatement_elseBegin();
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
    _flowAnalysis!.ifStatement_end(node.elseElement != null);
    return null;
  }

  @override
  DecoratedType? visitIfStatement(IfStatement node) {
    _flowAnalysis!.ifStatement_conditionBegin();
    _checkExpressionNotNull(node.expression);
    NullabilityNode? trueGuard;
    NullabilityNode? falseGuard;
    if (identical(_conditionInfo?.condition, node.expression)) {
      trueGuard = _conditionInfo!.trueGuard;
      falseGuard = _conditionInfo!.falseGuard;
      _variables.recordConditionalDiscard(source, node,
          ConditionalDiscard(trueGuard, falseGuard, _conditionInfo!.isPure));
    }
    if (trueGuard != null) {
      _guards.add(trueGuard);
    }
    try {
      _flowAnalysis!.ifStatement_thenBegin(node.expression, node);
      // We branched, so create a new scope for post-dominators.
      _postDominatedLocals.doScoped(
          action: () => _dispatch(node.thenStatement));
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
        _flowAnalysis!.ifStatement_elseBegin();
        // We branched, so create a new scope for post-dominators.
        _postDominatedLocals.doScoped(
            action: () => _dispatch(node.elseStatement));
      }
    } finally {
      _flowAnalysis!.ifStatement_end(elseStatement != null);
      if (falseGuard != null) {
        _guards.removeLast();
      }
    }
    return null;
  }

  @override
  DecoratedType? visitImplicitCallReference(ImplicitCallReference node) {
    return _handlePropertyAccessGeneralized(
        node: node,
        target: node.expression,
        propertyName: 'call',
        isNullAware: false,
        isCascaded: false,
        inSetterContext: false,
        callee: node.staticElement);
  }

  @override
  DecoratedType? visitIndexExpression(IndexExpression node) {
    DecoratedType? targetType;
    var target = node.target;
    if (node.isCascaded) {
      targetType = _currentCascadeTargetType;
    } else if (target != null) {
      targetType = _checkExpressionNotNull(target);
    }
    var callee = getWriteOrReadElement(node);
    DecoratedType? result;
    if (callee == null) {
      // Dynamic dispatch.  The return type is `dynamic`.
      // TODO(paulberry): would it be better to assume a return type of `Never`
      // so that we don't unnecessarily propagate nullabilities everywhere?
      result = _makeNullableDynamicType(node);
    } else {
      var calleeType = getOrComputeElementType(node, callee,
          targetType: targetType, targetExpression: target);
      // TODO(paulberry): substitute if necessary
      _handleAssignment(node.index,
          destinationType: calleeType.positionalParameters![0]);
      if (node.inSetterContext()) {
        result = calleeType.positionalParameters![1];
      } else {
        result = calleeType.returnType;
      }
    }
    return result;
  }

  @override
  DecoratedType visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    var callee = node.constructorName.staticElement!;
    var typeParameters = callee.enclosingElement.typeParameters;
    Iterable<DartType?> typeArgumentTypes;
    List<DecoratedType> decoratedTypeArguments;
    var typeArguments = node.constructorName.type.typeArguments;
    late List<EdgeOrigin> parameterEdgeOrigins;
    var target =
        NullabilityNodeTarget.text('constructed type').withCodeRef(node);
    if (typeArguments != null) {
      _dispatch(typeArguments);
      typeArgumentTypes = typeArguments.arguments.map((t) => t.type);
      decoratedTypeArguments = typeArguments.arguments
          .map((t) => _variables.decoratedTypeAnnotation(source, t))
          .toList();
      parameterEdgeOrigins = typeArguments.arguments
          .map((typeAnn) => TypeParameterInstantiationOrigin(source, typeAnn))
          .toList();
    } else {
      var staticType = node.staticType;
      if (staticType is InterfaceType) {
        typeArgumentTypes = staticType.typeArguments;
        int index = 0;
        decoratedTypeArguments = typeArgumentTypes.map((t) {
          return DecoratedType.forImplicitType(
              typeProvider, t, _graph, target.typeArgument(index++));
        }).toList();
        instrumentation?.implicitTypeArguments(
            source, node, decoratedTypeArguments);
        parameterEdgeOrigins = List.filled(typeArgumentTypes.length,
            InferredTypeParameterInstantiationOrigin(source, node));
      } else {
        // Note: this could happen if the code being migrated has errors.
        typeArgumentTypes = const [];
        decoratedTypeArguments = const [];
      }
    }

    if (node.staticType!.isDartCoreList &&
        callee.name == '' &&
        node.argumentList.arguments.length == 1) {
      _graph.connect(_graph.always, decoratedTypeArguments[0].node,
          ListLengthConstructorOrigin(source, node));
    }

    var nullabilityNode = NullabilityNode.forInferredType(target);
    _graph.makeNonNullable(
        nullabilityNode, InstanceCreationOrigin(source, node));
    var createdType = DecoratedType(node.staticType, nullabilityNode,
        typeArguments: decoratedTypeArguments);
    var calleeType =
        getOrComputeElementType(node, callee, targetType: createdType);
    for (var i = 0; i < decoratedTypeArguments.length; ++i) {
      _checkAssignment(parameterEdgeOrigins.elementAt(i),
          FixReasonTarget.root.typeArgument(i),
          source: decoratedTypeArguments[i],
          destination:
              _variables.decoratedTypeParameterBound(typeParameters[i])!,
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
    var expression = node.expression;
    var expressionNode = _dispatch(expression)!.node;
    var type = node.type;
    _dispatch(type);
    var decoratedType = _variables.decoratedTypeAnnotation(source, type);
    // The main type of the is check historically could not be nullable.
    // Making it nullable could change runtime behavior.
    _graph.makeNonNullable(
        decoratedType.node, IsCheckMainTypeOrigin(source, type));
    _conditionInfo = _ConditionInfo(node,
        isPure: expression is SimpleIdentifier,
        postDominatingIntent: _isReferenceInScope(expression),
        trueDemonstratesNonNullIntent: expressionNode);
    if (node.notOperator != null) {
      _conditionInfo = _conditionInfo!.not(node);
    }
    if (!_assumeNonNullabilityInCasts) {
      // TODO(mfairhurst): wire this to handleDowncast if we do not assume
      // nullability.
      assert(false);
    }
    _flowAnalysis!.isExpression_end(
        node, expression, node.notOperator != null, decoratedType);
    return _makeNonNullableBoolType(node);
  }

  @override
  DecoratedType? visitLabel(Label node) {
    // Labels are identifiers but they don't have types so we don't need to
    // visit them directly.
    return null;
  }

  @override
  DecoratedType? visitLibraryDirective(LibraryDirective node) {
    // skip directives, but not their metadata
    _dispatchList(node.metadata);
    return null;
  }

  @override
  DecoratedType visitListLiteral(ListLiteral node) {
    final previousLiteralType = _currentLiteralElementType;
    try {
      var listType = node.staticType as InterfaceType?;
      if (node.typeArguments == null) {
        var target =
            NullabilityNodeTarget.text('list element type').withCodeRef(node);
        var elementType = DecoratedType.forImplicitType(
            typeProvider, listType!.typeArguments[0], _graph, target);
        instrumentation?.implicitTypeArguments(source, node, [elementType]);
        _currentLiteralElementType = elementType;
      } else {
        _dispatch(node.typeArguments);
        _currentLiteralElementType = _variables.decoratedTypeAnnotation(
            source, node.typeArguments!.arguments[0]);
      }
      node.elements.forEach(_handleCollectionElement);
      return _makeNonNullLiteralType(node,
          typeArguments: [_currentLiteralElementType]);
    } finally {
      _currentLiteralElementType = previousLiteralType;
    }
  }

  @override
  DecoratedType? visitMapLiteralEntry(MapLiteralEntry node) {
    assert(_currentMapKeyType != null);
    assert(_currentMapValueType != null);
    _handleAssignment(node.key, destinationType: _currentMapKeyType);
    _handleAssignment(node.value, destinationType: _currentMapValueType);
    return null;
  }

  @override
  DecoratedType? visitMethodDeclaration(MethodDeclaration node) {
    if (BuiltValueTransformer.findNullableAnnotation(node) != null) {
      _graph.makeNullable(
          _variables
              .decoratedElementType(node.declaredElement!.declaration)
              .returnType!
              .node,
          BuiltValueNullableOrigin(source, node));
    }
    _handleExecutableDeclaration(node, node.declaredElement!, node.metadata,
        node.returnType, node.parameters, null, node.body, null);
    _dispatch(node.typeParameters);
    return null;
  }

  @override
  DecoratedType? visitMethodInvocation(MethodInvocation node) {
    DecoratedType? targetType;
    var target = node.target;
    bool isNullAware = node.isNullAware;
    var callee = node.methodName.staticElement;
    bool calleeIsStatic = callee is ExecutableElement && callee.isStatic;
    _dispatch(node.typeArguments);

    if (node.isCascaded) {
      targetType = _currentCascadeTargetType;
    } else if (target != null) {
      if (_isPrefix(target)) {
        // Nothing to do.
      } else if (calleeIsStatic) {
        _dispatch(target);
      } else if (isNullAware) {
        targetType = _handleNullAwareTarget(target, node);
      } else {
        targetType = _handleTarget(target, node.methodName.name, callee);
      }
    } else if (target == null && callee!.enclosingElement is ClassElement) {
      targetType = _thisOrSuper(node);
      _checkThisNotNull(targetType, node);
    }
    DecoratedType? expressionType;
    DecoratedType? calleeType;
    if (targetType != null &&
        targetType.type is FunctionType &&
        node.methodName.name == 'call') {
      // If `X` has a function type, then in the expression `X.call()`, the
      // function being called is `X` itself, so the callee type is simply the
      // type of `X`.
      calleeType = targetType;
    } else if (callee != null) {
      calleeType = getOrComputeElementType(node, callee,
          targetType: targetType,
          targetExpression: target,
          isNullAware: isNullAware);
      if (callee is PropertyAccessorElement) {
        calleeType = calleeType.returnType;
      }
    }
    if (calleeType == null) {
      // Dynamic dispatch.  The return type is `dynamic`.
      // TODO(paulberry): would it be better to assume a return type of `Never`
      // so that we don't unnecessarily propagate nullabilities everywhere?
      _dispatch(node.argumentList);
      expressionType = _makeNullableDynamicType(node);
    } else {
      expressionType = _handleInvocationArguments(
          node,
          node.argumentList.arguments,
          node.typeArguments,
          node.typeArgumentTypes,
          calleeType,
          null,
          invokeType: node.staticInvokeType);
      // Do any deferred processing for this method invocation.
      var deferredProcessing = _deferredMethodInvocationProcessing.remove(node);
      if (deferredProcessing != null) {
        expressionType = deferredProcessing(expressionType);
      }
      if (isNullAware) {
        expressionType = expressionType!.withNode(
            NullabilityNode.forLUB(targetType!.node, expressionType.node));
      }
      _variables.recordDecoratedExpressionType(node, expressionType);
    }
    _handleCustomCheckNotNull(node);
    _handleQuiverCheckNotNull(node);
    return expressionType;
  }

  @override
  DecoratedType? visitMixinDeclaration(MixinDeclaration node) {
    visitClassOrMixinOrExtensionDeclaration(node);
    _dispatch(node.implementsClause);
    _dispatch(node.onClause);
    _dispatch(node.typeParameters);
    return null;
  }

  @override
  DecoratedType? visitNamedType(NamedType node) {
    try {
      _typeNameNesting++;
      var typeArguments = node.typeArguments?.arguments;
      var element = node.element;
      if (element is TypeAliasElement &&
          element.aliasedElement is GenericFunctionTypeElement) {
        var aliasedElement = element.aliasedElement!;
        final typedefType = _variables.decoratedElementType(aliasedElement);
        final typeNameType = _variables.decoratedTypeAnnotation(source, node);

        Map<TypeParameterElement, DecoratedType> substitutions;
        if (node.typeArguments == null) {
          // TODO(mfairhurst): substitute instantiations to bounds
          substitutions = {};
        } else {
          substitutions =
              Map<TypeParameterElement, DecoratedType>.fromIterables(
                  element.typeParameters,
                  node.typeArguments!.arguments.map(
                      (t) => _variables.decoratedTypeAnnotation(source, t)));
        }

        final decoratedType = typedefType.substitute(substitutions);
        final origin = TypedefReferenceOrigin(source, node);
        _linkDecoratedTypeParameters(decoratedType, typeNameType, origin,
            isUnion: true);
        _linkDecoratedTypes(
            decoratedType.returnType!, typeNameType.returnType, origin,
            isUnion: true);
      } else if (element is TypeParameterizedElement) {
        if (typeArguments == null) {
          var instantiatedType =
              _variables.decoratedTypeAnnotation(source, node);
          var origin = InstantiateToBoundsOrigin(source, node);
          for (int i = 0; i < instantiatedType.typeArguments.length; i++) {
            _linkDecoratedTypes(
                instantiatedType.typeArguments[i]!,
                _variables
                    .decoratedTypeParameterBound(element.typeParameters[i]),
                origin,
                isUnion: false);
          }
        } else {
          for (int i = 0; i < typeArguments.length; i++) {
            DecoratedType? bound;
            bound = _variables
                .decoratedTypeParameterBound(element.typeParameters[i]);
            assert(bound != null);
            var argumentType =
                _variables.decoratedTypeAnnotation(source, typeArguments[i]);
            _checkAssignment(
                TypeParameterInstantiationOrigin(source, typeArguments[i]),
                FixReasonTarget.root,
                source: argumentType,
                destination: bound!,
                hard: true);
          }
        }
      }
      node.visitChildren(this);
      // If the type name is followed by a `/*!*/` comment, it is considered to
      // apply to the type and not to the "as" expression.  In order to prevent
      // a future call to _handleNullCheck from interpreting it as applying to
      // the "as" expression, we need to store the `/*!*/` comment in
      // _nullCheckHints.
      var token = node.endToken;
      _nullCheckHints[token] = getPostfixHint(token);
      namedTypeVisited(node); // Note this has been visited to TypeNameTracker.
      return null;
    } finally {
      _typeNameNesting--;
    }
  }

  @override
  DecoratedType? visitNamespaceDirective(NamespaceDirective node) {
    // skip directives, but not their metadata
    _dispatchList(node.metadata);
    return null;
  }

  @override
  DecoratedType? visitNode(AstNode node) {
    for (var child in node.childEntities) {
      if (child is AstNode) {
        _dispatch(child);
      }
    }
    return null;
  }

  @override
  DecoratedType visitNullLiteral(NullLiteral node) {
    var target = NullabilityNodeTarget.text('null literal').withCodeRef(node);
    var decoratedType = DecoratedType.forImplicitType(
        typeProvider, node.staticType, _graph, target);
    _flowAnalysis!.nullLiteral(node, decoratedType);
    _graph.makeNullable(decoratedType.node, LiteralOrigin(source, node));
    return decoratedType;
  }

  @override
  DecoratedType? visitParenthesizedExpression(ParenthesizedExpression node) {
    var result = _dispatch(node.expression);
    _flowAnalysis!.parenthesizedExpression(node, node.expression);
    return result;
  }

  @override
  DecoratedType? visitPartOfDirective(PartOfDirective node) {
    // skip directives, but not their metadata
    _dispatchList(node.metadata);
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
        var calleeType = getOrComputeElementType(node, callee,
            targetType: targetType, targetExpression: operand);
        writeType = _fixNumericTypes(calleeType.returnType!, node.staticType);
      }
      if (operand is SimpleIdentifier) {
        var element = getWriteOrReadElement(operand);
        if (element is PromotableElement) {
          _flowAnalysis!.write(node, element, writeType, null);
        }
      }
      return targetType;
    }
    _unimplemented(
        node, 'Postfix expression with operator ${node.operator.lexeme}');
  }

  @override
  DecoratedType? visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.staticElement is LibraryImportElement) {
      // TODO(paulberry)
      _unimplemented(node, 'PrefixedIdentifier with a prefix');
    } else {
      return _handlePropertyAccess(
          node, node.prefix, node.identifier, false, false);
    }
  }

  @override
  DecoratedType? visitPrefixExpression(PrefixExpression node) {
    var operand = node.operand;
    var targetType = _checkExpressionNotNull(operand);
    var operatorType = node.operator.type;
    if (operatorType == TokenType.BANG) {
      _flowAnalysis!.logicalNot_end(node, operand);
      return _makeNonNullableBoolType(node);
    } else {
      var callee = node.staticElement;
      var isIncrementOrDecrement = operatorType.isIncrementOperator;
      DecoratedType? staticType;
      if (callee == null) {
        // Dynamic dispatch.  The return type is `dynamic`.
        // TODO(paulberry): would it be better to assume a return type of `Never`
        // so that we don't unnecessarily propagate nullabilities everywhere?
        staticType = _makeNullableDynamicType(node);
      } else {
        var calleeType = getOrComputeElementType(node, callee,
            targetType: targetType, targetExpression: operand);
        if (isIncrementOrDecrement) {
          staticType =
              _fixNumericTypes(calleeType.returnType!, node.staticType);
        } else {
          staticType = _handleInvocationArguments(
              node, [], null, null, calleeType, null);
        }
      }
      if (isIncrementOrDecrement) {
        if (operand is SimpleIdentifier) {
          var element = getWriteOrReadElement(operand);
          if (element is PromotableElement) {
            _flowAnalysis!.write(node, element, staticType!, null);
          }
        }
      }
      return staticType;
    }
  }

  @override
  DecoratedType? visitPropertyAccess(PropertyAccess node) {
    return _handlePropertyAccess(node, node.target, node.propertyName,
        node.isNullAware, node.isCascaded);
  }

  @override
  DecoratedType? visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var callee = node.staticElement!;
    var calleeType = _variables.decoratedElementType(callee);
    _handleInvocationArguments(
        node, node.argumentList.arguments, null, null, calleeType, null);
    return null;
  }

  @override
  DecoratedType visitRethrowExpression(RethrowExpression node) {
    _flowAnalysis!.handleExit();
    var target =
        NullabilityNodeTarget.text('rethrow expression').withCodeRef(node);
    var nullabilityNode = NullabilityNode.forInferredType(target);
    _graph.makeNonNullable(nullabilityNode, ThrowOrigin(source, node));
    return DecoratedType(node.staticType, nullabilityNode);
  }

  @override
  DecoratedType? visitReturnStatement(ReturnStatement node) {
    DecoratedType? returnType = _currentFunctionType!.returnType;
    Expression? returnValue = node.expression;
    var functionBody = node.thisOrAncestorOfType<FunctionBody>()!;
    if (functionBody.isGenerator) {
      // Do not connect the return value to the return type.
      return _dispatch(returnValue);
    }
    final isAsync = functionBody.isAsynchronous;
    if (returnValue == null) {
      var target =
          NullabilityNodeTarget.text('implicit null return').withCodeRef(node);
      var implicitNullType = DecoratedType.forImplicitType(
          typeProvider, typeProvider.nullType, _graph, target);
      var origin = ImplicitNullReturnOrigin(source, node);
      _graph.makeNullable(implicitNullType.node, origin);
      _checkAssignment(origin, FixReasonTarget.root,
          source:
              isAsync ? _futureOf(implicitNullType, node) : implicitNullType,
          destination: returnType!,
          hard: false);
    } else {
      _handleAssignment(returnValue,
          destinationType: returnType, wrapFuture: isAsync);
    }

    _flowAnalysis!.handleExit();
    // Later statements no longer post-dominate the declarations because we
    // exited (or, in parent scopes, conditionally exited).
    // TODO(mfairhurst): don't clear post-dominators beyond the current function.
    _postDominatedLocals.clearEachScope();

    return null;
  }

  @override
  DecoratedType visitSetOrMapLiteral(SetOrMapLiteral node) {
    var setOrMapType = node.staticType as InterfaceType?;
    var typeArguments = node.typeArguments?.arguments;

    if (node.isSet) {
      final previousLiteralType = _currentLiteralElementType;
      try {
        if (typeArguments == null) {
          assert(setOrMapType!.typeArguments.length == 1);
          var target =
              NullabilityNodeTarget.text('set element type').withCodeRef(node);
          var elementType = DecoratedType.forImplicitType(
              typeProvider, setOrMapType!.typeArguments[0], _graph, target);
          instrumentation?.implicitTypeArguments(source, node, [elementType]);
          _currentLiteralElementType = elementType;
        } else {
          assert(typeArguments.length == 1);
          _dispatch(node.typeArguments);
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
          assert(setOrMapType!.typeArguments.length == 2);
          var targetKey =
              NullabilityNodeTarget.text('map key type').withCodeRef(node);
          var keyType = DecoratedType.forImplicitType(
              typeProvider, setOrMapType!.typeArguments[0], _graph, targetKey);
          _currentMapKeyType = keyType;
          var targetValue =
              NullabilityNodeTarget.text('map value type').withCodeRef(node);
          var valueType = DecoratedType.forImplicitType(
              typeProvider, setOrMapType.typeArguments[1], _graph, targetValue);
          _currentMapValueType = valueType;
          instrumentation
              ?.implicitTypeArguments(source, node, [keyType, valueType]);
        } else {
          assert(typeArguments.length == 2);
          _dispatch(node.typeArguments);
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
  DecoratedType? visitSimpleIdentifier(SimpleIdentifier node) {
    DecoratedType? targetType;
    DecoratedType? result;
    var staticElement = _favorFieldFormalElements(getWriteOrReadElement(node));
    if (staticElement is PromotableElement) {
      if (!node.inDeclarationContext()) {
        var promotedType = _flowAnalysis!.variableRead(node, staticElement);
        if (promotedType != null) return promotedType;
      }
      var type = getOrComputeElementType(node, staticElement);
      if (!node.inDeclarationContext() &&
          node.inGetterContext() &&
          !_lateHintedLocals.contains(staticElement) &&
          !_flowAnalysis!.isAssigned(staticElement)) {
        _graph.makeNullable(type.node, UninitializedReadOrigin(source, node));
      }
      result = type;
    } else if (staticElement is FunctionElement ||
        staticElement is MethodElement ||
        staticElement is ConstructorElement) {
      if (staticElement!.enclosingElement is ClassElement) {
        targetType = _thisOrSuper(node);
      }
      result =
          getOrComputeElementType(node, staticElement, targetType: targetType);
    } else if (staticElement is PropertyAccessorElement) {
      if (staticElement.enclosingElement is ClassElement) {
        targetType = _thisOrSuper(node);
      }
      var elementType =
          getOrComputeElementType(node, staticElement, targetType: targetType);
      result = staticElement.isGetter
          ? elementType.returnType
          : elementType.positionalParameters![0];
    } else if (staticElement is TypeDefiningElement) {
      result = _makeNonNullLiteralType(node);
    } else if (staticElement is ExtensionElement) {
      result = _makeNonNullLiteralType(node);
    } else if (staticElement == null) {
      assert(node.toString() == 'void', "${node.toString()} != 'void'");
      result = _makeNullableVoidType(node);
    } else if (staticElement.enclosingElement is ClassElement &&
        staticElement.enclosingElement is EnumElement) {
      result = getOrComputeElementType(node, staticElement);
    } else {
      // TODO(paulberry)
      _unimplemented(node,
          'Simple identifier with a static element of type ${staticElement.runtimeType}');
    }
    if (targetType != null) {
      _checkThisNotNull(targetType, node);
    }
    return result;
  }

  @override
  DecoratedType? visitSpreadElement(SpreadElement node) {
    final spreadType = node.expression.staticType!;
    DecoratedType? spreadTypeDecorated;
    var target =
        NullabilityNodeTarget.text('spread element type').withCodeRef(node);
    if (_typeSystem.isSubtypeOf(spreadType, typeProvider.mapObjectObjectType)) {
      assert(_currentMapKeyType != null && _currentMapValueType != null);
      final expectedType = typeProvider.mapType(
          _currentMapKeyType!.type!, _currentMapValueType!.type!);
      final expectedDecoratedType = DecoratedType.forImplicitType(
          typeProvider, expectedType, _graph, target,
          typeArguments: [_currentMapKeyType, _currentMapValueType]);

      spreadTypeDecorated = _handleAssignment(node.expression,
          destinationType: expectedDecoratedType);
    } else if (_typeSystem.isSubtypeOf(
        spreadType, typeProvider.iterableDynamicType)) {
      assert(_currentLiteralElementType != null);
      final expectedType =
          typeProvider.iterableType(_currentLiteralElementType!.type!);
      final expectedDecoratedType = DecoratedType.forImplicitType(
          typeProvider, expectedType, _graph, target,
          typeArguments: [_currentLiteralElementType]);

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
  DecoratedType? visitSuperConstructorInvocation(
      SuperConstructorInvocation node) {
    var callee = node.staticElement!;
    var target = NullabilityNodeTarget.text('super constructor invocation')
        .withCodeRef(node);
    var nullabilityNode = NullabilityNode.forInferredType(target);
    var class_ = node.thisOrAncestorOfType<ClassDeclaration>()!;
    var decoratedSupertype = _decoratedClassHierarchy!.getDecoratedSupertype(
        class_.declaredElement!, callee.enclosingElement);
    var typeArguments = decoratedSupertype.typeArguments;
    Iterable<DartType?> typeArgumentTypes;
    typeArgumentTypes = typeArguments.map((t) => t!.type);
    var createdType = DecoratedType(callee.returnType, nullabilityNode,
        typeArguments: typeArguments);
    var calleeType =
        getOrComputeElementType(node, callee, targetType: createdType);
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
  DecoratedType? visitSuperExpression(SuperExpression node) {
    return _thisOrSuper(node);
  }

  @override
  DecoratedType? visitSwitchStatement(SwitchStatement node) {
    var scrutineeType = _dispatch(node.expression)!;
    _flowAnalysis!
        .switchStatement_expressionEnd(node, node.expression, scrutineeType);
    var hasDefault = false;
    for (var member in node.members) {
      _postDominatedLocals.doScoped(action: () {
        var hasLabel = member.labels.isNotEmpty;
        _flowAnalysis!.switchStatement_beginAlternatives();
        _flowAnalysis!.switchStatement_beginAlternative();
        _flowAnalysis!.constantPattern_end(node.expression, scrutineeType,
            patternsEnabled: false);
        _flowAnalysis!.switchStatement_endAlternative(null, {});
        _flowAnalysis!
            .switchStatement_endAlternatives(node, hasLabels: hasLabel);
        if (member is SwitchCase) {
          _dispatch(member.expression);
        } else {
          hasDefault = true;
        }
        _dispatchList(member.statements);
        _flowAnalysis!.switchStatement_afterCase();
      });
    }
    _flowAnalysis!.switchStatement_end(hasDefault);
    return null;
  }

  @override
  DecoratedType visitSymbolLiteral(SymbolLiteral node) {
    return _makeNonNullLiteralType(node);
  }

  @override
  DecoratedType? visitThisExpression(ThisExpression node) {
    return _thisOrSuper(node);
  }

  @override
  DecoratedType visitThrowExpression(ThrowExpression node) {
    _dispatch(node.expression);
    // TODO(paulberry): do we need to check the expression type?  I think not.
    _flowAnalysis!.handleExit();
    var target =
        NullabilityNodeTarget.text('throw expression').withCodeRef(node);
    var nullabilityNode = NullabilityNode.forInferredType(target);
    _graph.makeNonNullable(nullabilityNode, ThrowOrigin(source, node));
    return DecoratedType(node.staticType, nullabilityNode);
  }

  @override
  DecoratedType? visitTryStatement(TryStatement node) {
    var finallyBlock = node.finallyBlock;
    if (finallyBlock != null) {
      _flowAnalysis!.tryFinallyStatement_bodyBegin();
    }
    var catchClauses = node.catchClauses;
    if (catchClauses.isNotEmpty) {
      _flowAnalysis!.tryCatchStatement_bodyBegin();
    }
    var body = node.body;
    _dispatch(body);
    if (catchClauses.isNotEmpty) {
      _flowAnalysis!.tryCatchStatement_bodyEnd(body);
      _dispatchList(catchClauses);
      _flowAnalysis!.tryCatchStatement_end();
    }
    if (finallyBlock != null) {
      _flowAnalysis!.tryFinallyStatement_finallyBegin(
          catchClauses.isNotEmpty ? node : body);
      _dispatch(finallyBlock);
      _flowAnalysis!.tryFinallyStatement_end();
    }
    return null;
  }

  @override
  DecoratedType? visitVariableDeclarationList(VariableDeclarationList node) {
    var parent = node.parent;
    bool isTopLevel =
        parent is FieldDeclaration || parent is TopLevelVariableDeclaration;
    _dispatchList(node.metadata);
    _dispatch(node.type);
    for (var variable in node.variables) {
      _dispatchList(variable.metadata);
      var initializer = variable.initializer;
      var declaredElement = variable.declaredElement!;
      if (isTopLevel) {
        assert(_flowAnalysis == null);
        _createFlowAnalysis(variable, null);
      } else {
        assert(_flowAnalysis != null);
        if (declaredElement is PromotableElement &&
            _variables.getLateHint(source, node) != null) {
          _lateHintedLocals.add(declaredElement);
        }
      }
      var type = _variables.decoratedElementType(declaredElement);
      var enclosingElement = declaredElement.enclosingElement;
      if (!declaredElement.isStatic && enclosingElement is ClassElement) {
        var overriddenElements = _inheritanceManager.getOverridden2(
            enclosingElement,
            Name(enclosingElement.library.source.uri, declaredElement.name));
        for (var overriddenElement
            in overriddenElements ?? <ExecutableElement>[]) {
          _handleFieldOverriddenDeclaration(
              variable, type, enclosingElement, overriddenElement);
        }
        if (!declaredElement.isFinal) {
          var overriddenElements = _inheritanceManager.getOverridden2(
              enclosingElement,
              Name(enclosingElement.library.source.uri,
                  '${declaredElement.name}='));
          for (var overriddenElement
              in overriddenElements ?? <ExecutableElement>[]) {
            _handleFieldOverriddenDeclaration(
                variable, type, enclosingElement, overriddenElement);
          }
        }
      }
      try {
        if (declaredElement is PromotableElement) {
          _flowAnalysis!.declare(
              declaredElement, _variables.decoratedElementType(declaredElement),
              initialized: initializer != null);
        }
        if (initializer == null) {
          // For top level variables and static fields, we have to generate an
          // implicit assignment of `null`.  For instance fields, this is done
          // when processing constructors.  For local variables, this is done
          // when processing variable reads (only if flow analysis indicates
          // the variable isn't definitely assigned).
          if (isTopLevel &&
              _variables.getLateHint(source, node) == null &&
              !(declaredElement is FieldElement && !declaredElement.isStatic)) {
            _graph.makeNullable(
                type.node, ImplicitNullInitializerOrigin(source, node));
          }
        } else {
          _handleAssignment(initializer, destinationType: type);
        }
        if (isTopLevel) {
          _flowAnalysis!.finish();
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
      _postDominatedLocals.add(node.variables.single.declaredElement!);
    }

    return null;
  }

  @override
  DecoratedType? visitWhileStatement(WhileStatement node) {
    // Note: we do not create guards. A null check here is *very* unlikely to be
    // unnecessary after analysis.
    _flowAnalysis!.whileStatement_conditionBegin(node);
    _checkExpressionNotNull(node.condition);
    _flowAnalysis!.whileStatement_bodyBegin(node, node.condition);
    _postDominatedLocals.doScoped(action: () => _dispatch(node.body));
    _flowAnalysis!.whileStatement_end();
    return null;
  }

  void _addParametersToFlowAnalysis(FormalParameterList? parameters) {
    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        var declaredElement = parameter.declaredElement!;
        // TODO(paulberry): `skipDuplicateCheck` is currently needed to work
        // around a failure in api_test.dart; fix this.
        _flowAnalysis!.declare(
            declaredElement, _variables.decoratedElementType(declaredElement),
            initialized: true, skipDuplicateCheck: true);
      }
    }
  }

  /// Visits [expression] and generates the appropriate edge to assert that its
  /// value is non-null.
  ///
  /// Returns the decorated type of [expression].
  DecoratedType _checkExpressionNotNull(Expression expression,
      {DecoratedType? sourceType}) {
    if (_isPrefix(expression)) {
      throw ArgumentError('cannot check non-nullability of a prefix');
    }
    sourceType ??= _dispatch(expression);
    if (sourceType == null) {
      throw StateError('No type computed for ${expression.runtimeType} '
          '(${expression.toSource()}) offset=${expression.offset}');
    }
    var origin = _makeEdgeOrigin(sourceType, expression);
    var hard = _shouldUseHardEdge(expression);
    var edge = _graph.makeNonNullable(sourceType.node, origin,
        hard: hard, guards: _guards);
    if (origin is ExpressionChecksOrigin) {
      origin.checks.edges[FixReasonTarget.root] = edge;
    }
    return sourceType;
  }

  /// Generates the appropriate edge to assert that the value of `this` is
  /// non-null.
  void _checkThisNotNull(DecoratedType? thisType, AstNode node) {
    // `this` can only be `null` in extensions, so if we're not in an extension,
    // there's nothing to do.
    if (_currentExtendedType == null) return;
    var origin = ImplicitThisOrigin(source, node);
    var hard = _postDominatedLocals.isInScope(_extensionThis);
    _graph.makeNonNullable(thisType!.node, origin, hard: hard, guards: _guards);
  }

  /// Computes the map to be stored in [_currentFieldFormals] while visiting the
  /// constructor having the given [constructorElement].
  Map<PropertyAccessorElement, FieldFormalParameterElement>
      _computeFieldFormalMap(ConstructorElement constructorElement) {
    var result = <PropertyAccessorElement, FieldFormalParameterElement>{};
    for (var parameter in constructorElement.parameters) {
      if (parameter is FieldFormalParameterElement) {
        var getter = parameter.field?.getter;
        if (getter != null) {
          result[getter] = parameter;
        }
      }
    }
    return result;
  }

  @override
  void _connect(NullabilityNode? source, NullabilityNode? destination,
      EdgeOrigin origin, FixReasonTarget? edgeTarget,
      {bool hard = false, bool checkable = true}) {
    var edge = _graph.connect(source, destination!, origin,
        hard: hard, checkable: checkable, guards: _guards);
    if (origin is ExpressionChecksOrigin) {
      origin.checks.edges[edgeTarget] = edge;
    }
  }

  void _createFlowAnalysis(Declaration node, FormalParameterList? parameters) {
    assert(_flowAnalysis == null);
    assert(_assignedVariables == null);
    _assignedVariables =
        FlowAnalysisHelper.computeAssignedVariables(node, parameters);
    // Note: we are using flow analysis to help us track true nullabilities;
    // it's not necessary to replicate old bugs.  So we pass `true` for
    // `respectImplicitlyTypedVarInitializers`.
    _flowAnalysis = FlowAnalysis<AstNode, Statement, Expression,
            PromotableElement, DecoratedType>(
        DecoratedTypeOperations(_typeSystem, typeProvider, _variables, _graph),
        _assignedVariables!,
        respectImplicitlyTypedVarInitializers: true);
    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        var declaredElement = parameter.declaredElement!;
        _flowAnalysis!.declare(
            declaredElement, _variables.decoratedElementType(declaredElement),
            initialized: true);
      }
    }
  }

  /// Creates a type that can be used to check that an expression's value is
  /// non-nullable.
  DecoratedType _createNonNullableType(Expression expression) {
    var target =
        NullabilityNodeTarget.text('expression type').withCodeRef(expression);
    // Note: it's not necessary for the type to precisely match the type of the
    // expression, since all we are going to do is cause a single graph edge to
    // be built; it is sufficient to pass in any decorated type whose node is
    // non-nullable.  So we use `Object`.
    var nullabilityNode = NullabilityNode.forInferredType(target);
    _graph.makeNonNullableUnion(
        nullabilityNode, NonNullableUsageOrigin(source, expression));
    return DecoratedType(typeProvider.objectType, nullabilityNode);
  }

  DecoratedType _decorateUpperOrLowerBound(AstNode astNode, DartType? type,
      DecoratedType left, DecoratedType right, bool isLUB,
      {NullabilityNode? node}) {
    var leftType = left.type;
    var rightType = right.type;
    if (leftType is TypeParameterType && leftType != type) {
      // We are "unwrapping" a type parameter type to its bound.
      final typeParam = leftType.element;
      return _decorateUpperOrLowerBound(
          astNode,
          type,
          left.substitute(
              {typeParam: _variables.decoratedTypeParameterBound(typeParam)!}),
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
              {typeParam: _variables.decoratedTypeParameterBound(typeParam)!}),
          isLUB,
          node: node);
    }

    node ??= isLUB
        ? NullabilityNode.forLUB(left.node, right.node)
        : _nullabilityNodeForGLB(astNode, left.node, right.node);

    if (type is DynamicType || type is VoidType) {
      return DecoratedType(type, node);
    } else if (leftType!.isBottom) {
      return right.withNode(node);
    } else if (rightType!.isBottom) {
      return left.withNode(node);
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
          List<DecoratedType?> leftTypeArguments;
          List<DecoratedType?> rightTypeArguments;
          if (isLUB) {
            leftTypeArguments = _decoratedClassHierarchy!
                .asInstanceOf(left, type.element)
                .typeArguments;
            rightTypeArguments = _decoratedClassHierarchy!
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
                leftTypeArguments[i]!,
                rightTypeArguments[i]!,
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
      var leftType = left.type!;
      var rightType = right.type;
      if (leftType.isDartCoreNull) {
        assert(
            isLUB, "shouldn't be possible to get a function from GLB(null, S)");
        return DecoratedType(type, node,
            returnType: right.returnType,
            positionalParameters: right.positionalParameters,
            namedParameters: right.namedParameters);
      } else if (rightType!.isDartCoreNull) {
        assert(
            isLUB, "shouldn't be possible to get a function from GLB(S, null)");
        return DecoratedType(type, node,
            returnType: left.returnType,
            positionalParameters: left.positionalParameters,
            namedParameters: left.namedParameters);
      }
      if (leftType is FunctionType && rightType is FunctionType) {
        var returnType = _decorateUpperOrLowerBound(astNode, type.returnType,
            left.returnType!, right.returnType!, isLUB);
        List<DecoratedType> positionalParameters = [];
        Map<String, DecoratedType> namedParameters = {};
        int positionalParameterCount = 0;
        for (var parameter in type.parameters) {
          DecoratedType? leftParameterType;
          DecoratedType? rightParameterType;
          if (parameter.isNamed) {
            leftParameterType = left.namedParameters![parameter.name];
            rightParameterType = right.namedParameters![parameter.name];
          } else {
            leftParameterType =
                left.positionalParameters![positionalParameterCount];
            rightParameterType =
                right.positionalParameters![positionalParameterCount];
            positionalParameterCount++;
          }
          var decoratedParameterType = _decorateUpperOrLowerBound(astNode,
              parameter.type, leftParameterType!, rightParameterType!, !isLUB);
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
      var leftType = left.type!;
      var rightType = right.type;
      if (leftType.isDartCoreNull || rightType!.isDartCoreNull) {
        assert(isLUB, "shouldn't be possible to get T from GLB(null, S)");
        return DecoratedType(type, node);
      }

      assert(leftType.element == type.element &&
          rightType.element == type.element);
      return DecoratedType(type, node);
    }
    _unimplemented(astNode, '_decorateUpperOrLowerBound');
  }

  DecoratedType? _dispatch(AstNode? node, {bool skipNullCheckHint = false}) {
    try {
      var type = node?.accept(this);
      if (!skipNullCheckHint && node is Expression) {
        type = _handleNullCheckHint(node, type);
      }
      return type;
    } catch (exception, stackTrace) {
      if (listener != null) {
        listener!.reportException(source, node, exception, stackTrace);
        return null;
      } else {
        rethrow;
      }
    }
  }

  void _dispatchList(List<AstNode>? nodeList) {
    if (nodeList == null) return;
    for (var node in nodeList) {
      _dispatch(node);
    }
  }

  /// If the innermost enclosing executable is a constructor with field formal
  /// parameters, and [staticElement] refers to the getter associated with one
  /// of those fields, returns the corresponding field formal parameter element.
  /// Otherwise returns [staticElement] unchanged.
  ///
  /// This allows us to treat null checks on the field as though they were null
  /// checks on the field formal parameter, which is not strictly correct, but
  /// tends to produce migrations that are more in line with user intent.
  Element? _favorFieldFormalElements(Element? staticElement) {
    if (staticElement is PropertyAccessorElement) {
      var fieldFormal = _currentFieldFormals[staticElement];
      if (fieldFormal != null) {
        return fieldFormal;
      }
    }
    return staticElement;
  }

  DecoratedType _fixNumericTypes(
      DecoratedType decoratedType, DartType? undecoratedType) {
    if (decoratedType.type!.isDartCoreNum && undecoratedType!.isDartCoreInt) {
      // In a few cases the type computed by normal method lookup is `num`,
      // but special rules kick in to cause the type to be `int` instead.  If
      // that is the case, we need to fix up the decorated type.
      return DecoratedType(undecoratedType, decoratedType.node);
    } else {
      return decoratedType;
    }
  }

  DecoratedType _futureOf(DecoratedType type, AstNode node) =>
      DecoratedType.forImplicitType(
          typeProvider,
          typeProvider.futureType(type.type!),
          _graph,
          NullabilityNodeTarget.text('implicit future').withCodeRef(node),
          typeArguments: [type]);

  @override
  DecoratedType? _getCallMethodType(DecoratedType type) {
    var typeType = type.type;
    if (typeType is InterfaceType) {
      var callMethod = typeType.lookUpMethod2('call', _library);
      if (callMethod != null) {
        return _variables
            .decoratedElementType(callMethod.declaration)
            .substitute(type.asSubstitution);
      }
    }
    return null;
  }

  @override
  DecoratedType? _getTypeParameterTypeBound(DecoratedType type) {
    // TODO(paulberry): once we've wired up flow analysis, return promoted
    // bounds if applicable.
    return _variables
        .decoratedTypeParameterBound((type.type as TypeParameterType).element);
  }

  /// Creates the necessary constraint(s) for an assignment of the given
  /// [expression] to a destination whose type is [destinationType].
  ///
  /// Optionally, the caller may supply an [assignmentExpression] instead of
  /// [destinationType].  In this case, then the type comes from visiting the
  /// LHS of the assignment expression.  If the LHS of the assignment expression
  /// refers to a local variable, we mark it as assigned in flow analysis at the
  /// proper time.
  ///
  /// Set [wrapFuture] to true to handle assigning Future<flatten(T)> to R.
  DecoratedType? _handleAssignment(Expression expression,
      {DecoratedType? destinationType,
      AssignmentExpression? assignmentExpression,
      AssignmentExpression? compoundOperatorInfo,
      AssignmentExpression? questionAssignNode,
      bool fromDefaultValue = false,
      bool wrapFuture = false,
      bool sourceIsSetupCall = false,
      bool isInjectorGetAssignment = false}) {
    assert(
        (assignmentExpression == null) != (destinationType == null),
        'Either assignmentExpression or destinationType should be supplied, '
        'but not both');
    PromotableElement? destinationLocalVariable;
    if (destinationType == null) {
      var destinationExpression = assignmentExpression!.leftHandSide;
      if (destinationExpression is SimpleIdentifier) {
        var element = getWriteOrReadElement(destinationExpression);
        if (element is PromotableElement) {
          destinationLocalVariable = element;
        }
      }
      if (destinationLocalVariable != null) {
        _dispatch(destinationExpression);
        destinationType = getOrComputeElementType(
            destinationExpression, destinationLocalVariable);
      } else {
        destinationType = _dispatch(destinationExpression);
      }
    }
    if (sourceIsSetupCall &&
        isInjectorGetAssignment &&
        destinationType != null) {
      _graph.makeNonNullable(
          destinationType.node,
          AssignmentFromAngularInjectorGetOrigin(
              source, assignmentExpression!.leftHandSide as SimpleIdentifier,
              isSetupAssignment: sourceIsSetupCall));
    }

    if (questionAssignNode != null) {
      _guards.add(destinationType!.node);
      _flowAnalysis!.ifNullExpression_rightBegin(
          questionAssignNode.leftHandSide, destinationType);
    }
    DecoratedType? sourceType;
    try {
      sourceType = _dispatch(expression);
      if (wrapFuture) {
        sourceType = _wrapFuture(sourceType!, expression);
      }
      if (sourceType == null) {
        throw StateError('No type computed for ${expression.runtimeType} '
            '(${expression.toSource()}) offset=${expression.offset}');
      }
      EdgeOrigin edgeOrigin = _makeEdgeOrigin(sourceType, expression,
          isSetupAssignment: sourceIsSetupCall);
      if (compoundOperatorInfo != null) {
        var compoundOperatorMethod = compoundOperatorInfo.staticElement;
        if (compoundOperatorMethod != null) {
          _checkAssignment(
              CompoundAssignmentOrigin(source, compoundOperatorInfo),
              FixReasonTarget.root,
              source: destinationType!,
              destination: _createNonNullableType(compoundOperatorInfo),
              hard: _shouldUseHardEdge(assignmentExpression!.leftHandSide));
          DecoratedType compoundOperatorType = getOrComputeElementType(
              compoundOperatorInfo, compoundOperatorMethod,
              targetType: destinationType,
              targetExpression: compoundOperatorInfo.leftHandSide);
          assert(compoundOperatorType.positionalParameters!.isNotEmpty);
          _checkAssignment(edgeOrigin, FixReasonTarget.root,
              source: sourceType,
              destination: compoundOperatorType.positionalParameters![0],
              hard: _shouldUseHardEdge(expression),
              sourceIsFunctionLiteral: expression is FunctionExpression);
          sourceType = _fixNumericTypes(compoundOperatorType.returnType!,
              compoundOperatorInfo.staticType);
          _checkAssignment(
              CompoundAssignmentOrigin(source, compoundOperatorInfo),
              FixReasonTarget.root,
              source: sourceType,
              destination: destinationType,
              hard: false);
        } else {
          sourceType = _makeNullableDynamicType(compoundOperatorInfo);
        }
      } else {
        if (_tryTransformOrElse(expression, sourceType) ||
            _tryTransformWhere(
                expression, edgeOrigin, sourceType, destinationType!)) {
          // Nothing further to do.
        } else {
          var hard = _shouldUseHardEdge(expression,
              isConditionallyExecuted: questionAssignNode != null);
          _checkAssignment(edgeOrigin, FixReasonTarget.root,
              source: sourceType,
              destination: destinationType,
              hard: hard,
              sourceIsFunctionLiteral: expression is FunctionExpression);
        }
      }
      if (destinationLocalVariable != null) {
        _flowAnalysis!.write(assignmentExpression!, destinationLocalVariable,
            sourceType, compoundOperatorInfo == null ? expression : null);
      }
      if (questionAssignNode != null) {
        _flowAnalysis!.ifNullExpression_end();
        // a ??= b is only nullable if both a and b are nullable.
        sourceType = destinationType!.withNode(_nullabilityNodeForGLB(
            questionAssignNode, sourceType.node, destinationType.node));
        _variables.recordDecoratedExpressionType(
            questionAssignNode, sourceType);
      }
    } finally {
      if (questionAssignNode != null) {
        _guards.removeLast();
      }
    }
    if (assignmentExpression != null) {
      var element = _referencedElement(assignmentExpression.leftHandSide);
      if (element != null) {
        _postDominatedLocals.removeFromAllScopes(element);
        _elementsWrittenToInLocalFunction?.add(element);
      }
    }
    return sourceType;
  }

  DecoratedType? _handleCollectionElement(CollectionElement? element) {
    if (element is Expression) {
      assert(_currentLiteralElementType != null);
      return _handleAssignment(element,
          destinationType: _currentLiteralElementType);
    } else {
      return _dispatch(element);
    }
  }

  void _handleConstructorRedirection(
      FormalParameterList parameters, ConstructorName redirectedConstructor) {
    var callee = redirectedConstructor.staticElement!.declaration;
    var redirectedClass = callee.enclosingElement;
    var calleeType = _variables.decoratedElementType(callee);
    var typeArguments = redirectedConstructor.type.typeArguments;
    var typeArgumentTypes =
        typeArguments?.arguments.map((t) => t.type).toList();
    _handleInvocationArguments(
        redirectedConstructor,
        parameters.parameters,
        typeArguments,
        typeArgumentTypes,
        calleeType,
        redirectedClass.typeParameters);
  }

  void _handleCustomCheckNotNull(MethodInvocation node) {
    var callee = node.methodName.staticElement;
    if (node.argumentList.arguments.isNotEmpty &&
        callee is ExecutableElement &&
        callee.isStatic) {
      var enclosingElement = callee.enclosingElement;
      if (enclosingElement is ClassElement) {
        if (callee.name == 'checkNotNull' &&
                enclosingElement.name == 'ArgumentError' &&
                callee.library.isDartCore ||
            callee.name == 'checkNotNull' &&
                enclosingElement.name == 'BuiltValueNullFieldError' &&
                callee.library.source.uri.toString() ==
                    'package:built_value/built_value.dart') {
          var argument = node.argumentList.arguments.first;
          if (argument is SimpleIdentifier && _isReferenceInScope(argument)) {
            var argumentType = _variables.decoratedElementType(
                _favorFieldFormalElements(getWriteOrReadElement(argument))!);
            _graph.makeNonNullable(argumentType.node,
                ArgumentErrorCheckNotNullOrigin(source, argument));
          }
        }
      }
    }
  }

  void _handleExecutableDeclaration(
      Declaration node,
      ExecutableElement declaredElement,
      NodeList<Annotation> metadata,
      TypeAnnotation? returnType,
      FormalParameterList? parameters,
      NodeList<ConstructorInitializer>? initializers,
      FunctionBody body,
      ConstructorName? redirectedConstructor) {
    assert(_currentFunctionType == null);
    assert(_currentFieldFormals.isEmpty);
    assert(_currentExecutable == null);
    _dispatchList(metadata);
    _dispatch(returnType);
    _createFlowAnalysis(node, parameters);
    _dispatch(parameters);

    // Be over conservative with public methods' arguments:
    // Unless we have reasons for non-nullability, assume they are nullable.
    // Soft edge to `always` node does exactly this.
    bool isOverride = false;
    final thisClass = declaredElement.enclosingElement;
    if (thisClass is InterfaceElement) {
      final name = Name(thisClass.library.source.uri, declaredElement.name);
      isOverride = _inheritanceManager.getOverridden2(thisClass, name) != null;
    }
    if (!isOverride &&
        declaredElement.isPublic &&
        declaredElement is! PropertyAccessorElement &&
        // operator == treats `null` specially.
        !(declaredElement.isOperator && declaredElement.name == '==')) {
      _makeArgumentsNullable(declaredElement, node);
    }
    _currentFunctionType = _variables.decoratedElementType(declaredElement);
    _currentFieldFormals = declaredElement is ConstructorElement
        ? _computeFieldFormalMap(declaredElement)
        : const {};
    _currentExecutable = declaredElement;
    _addParametersToFlowAnalysis(parameters);
    // Push a scope of post-dominated declarations on the stack.
    _postDominatedLocals.pushScope(elements: declaredElement.parameters);
    if (declaredElement.enclosingElement is ExtensionElement) {
      _postDominatedLocals.add(_extensionThis);
    }
    try {
      _dispatchList(initializers);
      if (declaredElement is ConstructorElement &&
          !declaredElement.isFactory &&
          declaredElement.redirectedConstructor == null) {
        _handleUninitializedFields(node, _fieldsNotInitializedByConstructor!);
      }
      _dispatch(body);
      if (redirectedConstructor != null) {
        _handleConstructorRedirection(parameters!, redirectedConstructor);
      }
      if (declaredElement is! ConstructorElement) {
        var enclosingElement = declaredElement.enclosingElement;
        if (enclosingElement is ClassElement) {
          var overriddenElements = _inheritanceManager.getOverridden2(
              enclosingElement,
              Name(enclosingElement.library.source.uri, declaredElement.name));
          for (var overriddenElement
              in overriddenElements ?? <ExecutableElement>[]) {
            _handleExecutableOverriddenDeclaration(node, returnType, parameters,
                enclosingElement, overriddenElement);
          }
          if (declaredElement is PropertyAccessorElement) {
            if (declaredElement.isGetter) {
              var setters = [declaredElement.correspondingSetter];
              if (setters[0] == null && !declaredElement.isStatic) {
                // No corresponding setter in this class; look for inherited
                // setters.
                var getterName = declaredElement.name;
                var setterName = '$getterName=';
                var inheritedMembers = _inheritanceManager.getOverridden2(
                    enclosingElement,
                    Name(enclosingElement.library.source.uri, setterName));
                if (inheritedMembers != null) {
                  setters = [
                    for (var setter in inheritedMembers)
                      if (setter is PropertyAccessorElement) setter
                  ];
                }
              }
              for (var setter in setters) {
                if (setter != null) {
                  _handleGetterSetterCorrespondence(
                      node,
                      declaredElement.isStatic ? null : enclosingElement,
                      declaredElement,
                      setter.declaration);
                }
              }
            } else {
              assert(declaredElement.isSetter);
              assert(declaredElement.name.endsWith('='));
              var getters = [declaredElement.correspondingGetter];
              if (getters[0] == null && !declaredElement.isStatic) {
                // No corresponding getter in this class; look for inherited
                // getters.
                var setterName = declaredElement.name;
                var getterName = setterName.substring(0, setterName.length - 1);
                var inheritedMembers = _inheritanceManager.getOverridden2(
                    enclosingElement,
                    Name(enclosingElement.library.source.uri, getterName));
                if (inheritedMembers != null) {
                  getters = [
                    for (var getter in inheritedMembers)
                      if (getter is PropertyAccessorElement) getter
                  ];
                }
              }
              for (var getter in getters) {
                if (getter != null) {
                  _handleGetterSetterCorrespondence(
                      node,
                      declaredElement.isStatic ? null : enclosingElement,
                      getter.declaration,
                      declaredElement);
                }
              }
            }
          }
        }
      }
      _flowAnalysis!.finish();
    } finally {
      _flowAnalysis = null;
      _assignedVariables = null;
      _currentFunctionType = null;
      _currentFieldFormals = const {};
      _postDominatedLocals.popScope();
      _currentExecutable = null;
    }
  }

  void _handleExecutableOverriddenDeclaration(
      Declaration node,
      TypeAnnotation? returnType,
      FormalParameterList? parameters,
      ClassElement classElement,
      Element overriddenElement) {
    overriddenElement = overriddenElement.declaration!;
    var overriddenClass =
        overriddenElement.enclosingElement as InterfaceElement;
    var decoratedSupertype = _decoratedClassHierarchy!
        .getDecoratedSupertype(classElement, overriddenClass);
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
        _checkAssignment(
            ReturnTypeInheritanceOrigin(source, node), FixReasonTarget.root,
            source: _currentFunctionType!.returnType!,
            destination: overriddenFieldType,
            hard: true);
      } else {
        assert(method.isSetter);
        DecoratedType currentParameterType =
            _currentFunctionType!.positionalParameters!.single;
        DecoratedType overriddenParameterType = overriddenFieldType;
        _checkAssignment(
            ParameterInheritanceOrigin(source, node), FixReasonTarget.root,
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
            _currentFunctionType!.returnType!,
            overriddenFunctionType.returnType,
            ReturnTypeInheritanceOrigin(source, node),
            isUnion: false);
      } else {
        _checkAssignment(
            ReturnTypeInheritanceOrigin(source, node), FixReasonTarget.root,
            source: _currentFunctionType!.returnType!,
            destination: overriddenFunctionType.returnType!,
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
          DecoratedType? currentParameterType;
          DecoratedType? overriddenParameterType;
          if (parameter.isNamed) {
            var name = normalParameter.name!.lexeme;
            currentParameterType = _currentFunctionType!.namedParameters![name];
            overriddenParameterType =
                overriddenFunctionType.namedParameters![name];
          } else {
            if (positionalParameterCount <
                _currentFunctionType!.positionalParameters!.length) {
              currentParameterType = _currentFunctionType!
                  .positionalParameters![positionalParameterCount];
            }
            if (positionalParameterCount <
                overriddenFunctionType.positionalParameters!.length) {
              overriddenParameterType = overriddenFunctionType
                  .positionalParameters![positionalParameterCount];
            }
            positionalParameterCount++;
          }
          if (overriddenParameterType != null) {
            var origin = ParameterInheritanceOrigin(source, node);
            if (_isUntypedParameter(normalParameter)) {
              _linkDecoratedTypes(
                  overriddenParameterType, currentParameterType, origin,
                  isUnion: false);
            } else {
              _checkAssignment(origin, FixReasonTarget.root,
                  source: overriddenParameterType,
                  destination: currentParameterType!,
                  hard: false,
                  checkable: false);
            }
          }
        }
      }
    }
  }

  void _handleFieldOverriddenDeclaration(
      VariableDeclaration node,
      DecoratedType type,
      ClassElement classElement,
      Element overriddenElement) {
    overriddenElement = overriddenElement.declaration!;
    var overriddenClass =
        overriddenElement.enclosingElement as InterfaceElement;
    var decoratedSupertype = _decoratedClassHierarchy!
        .getDecoratedSupertype(classElement, overriddenClass);
    var substitution = decoratedSupertype.asSubstitution;
    if (overriddenElement is PropertyAccessorElement) {
      DecoratedType? unsubstitutedOverriddenType;
      if (overriddenElement.isSynthetic) {
        unsubstitutedOverriddenType =
            _variables.decoratedElementType(overriddenElement.variable);
      } else {
        if (overriddenElement.isGetter) {
          unsubstitutedOverriddenType =
              _variables.decoratedElementType(overriddenElement).returnType;
        } else {
          unsubstitutedOverriddenType = _variables
              .decoratedElementType(overriddenElement)
              .positionalParameters![0];
        }
      }
      var overriddenType =
          unsubstitutedOverriddenType!.substitute(substitution);
      if (overriddenElement.isGetter) {
        _checkAssignment(
            ReturnTypeInheritanceOrigin(source, node), FixReasonTarget.root,
            source: type, destination: overriddenType, hard: true);
      } else {
        assert(overriddenElement.isSetter);
        _checkAssignment(
            ParameterInheritanceOrigin(source, node), FixReasonTarget.root,
            source: overriddenType, destination: type, hard: true);
      }
    } else {
      assert(false, 'Field overrides non-property-accessor');
    }
  }

  void _handleForLoopParts(AstNode node, ForLoopParts parts, AstNode body,
      DecoratedType? Function(AstNode) bodyHandler) {
    if (parts is ForParts) {
      if (parts is ForPartsWithDeclarations) {
        _dispatch(parts.variables);
      } else if (parts is ForPartsWithExpression) {
        var initializationType = _dispatch(parts.initialization);
        if (initializationType != null) {
          _graph.connectDummy(
              initializationType.node, DummyOrigin(source, parts));
        }
      }
      _flowAnalysis!.for_conditionBegin(node);
      if (parts.condition != null) {
        _checkExpressionNotNull(parts.condition!);
      }
      _flowAnalysis!
          .for_bodyBegin(node is Statement ? node : null, parts.condition);
    } else if (parts is ForEachParts) {
      Element? lhsElement;
      DecoratedType? lhsType;
      if (parts is ForEachPartsWithDeclaration) {
        var variableElement = parts.loopVariable.declaredElement!;
        _flowAnalysis!.declare(
            variableElement, _variables.decoratedElementType(variableElement),
            initialized: true);
        lhsElement = variableElement;
        _dispatch(parts.loopVariable.type);
        lhsType = _variables.decoratedElementType(lhsElement);
      } else if (parts is ForEachPartsWithIdentifier) {
        lhsElement = parts.identifier.staticElement;
        lhsType = _dispatch(parts.identifier);
      } else {
        throw StateError(
            'Unexpected ForEachParts subtype: ${parts.runtimeType}');
      }
      var iterableType = _checkExpressionNotNull(parts.iterable);
      DecoratedType? elementType;
      if (lhsType != null) {
        var iterableTypeType = iterableType.type!;
        if (_typeSystem.isSubtypeOf(
            iterableTypeType, typeProvider.iterableDynamicType)) {
          elementType = _decoratedClassHierarchy!
              .asInstanceOf(iterableType, typeProvider.iterableElement)
              .typeArguments[0];
          _checkAssignment(
              ForEachVariableOrigin(source, parts), FixReasonTarget.root,
              source: elementType!, destination: lhsType, hard: false);
        }
      }
      _flowAnalysis!.forEach_bodyBegin(node);
      if (lhsElement is PromotableElement) {
        _flowAnalysis!.write(node, lhsElement,
            elementType ?? _makeNullableDynamicType(node), null);
      }
    }

    // The condition may fail/iterable may be empty, so the body gets a new
    // post-dominator scope.
    _postDominatedLocals.doScoped(action: () {
      bodyHandler(body);

      if (parts is ForParts) {
        _flowAnalysis!.for_updaterBegin();
        for (var updater in parts.updaters) {
          var updaterType = _dispatch(updater)!;
          _graph.connectDummy(updaterType.node, DummyOrigin(source, updater));
        }
        _flowAnalysis!.for_end();
      } else {
        _flowAnalysis!.forEach_end();
      }
    });
  }

  void _handleGetterSetterCorrespondence(Declaration node, ClassElement? class_,
      PropertyAccessorElement getter, PropertyAccessorElement setter) {
    DecoratedType? getType;
    if (getter.isSynthetic) {
      var field = getter.variable;
      if (field.isSynthetic) return;
      getType = _variables.decoratedElementType(field);
    } else {
      getType = _variables.decoratedElementType(getter).returnType;
    }
    DecoratedType? setType;
    if (setter.isSynthetic) {
      var field = setter.variable;
      if (field.isSynthetic) return;
      setType = _variables.decoratedElementType(field);
    } else {
      setType =
          _variables.decoratedElementType(setter).positionalParameters!.single;
    }
    Map<TypeParameterElement, DecoratedType> getterSubstitution = const {};
    Map<TypeParameterElement, DecoratedType> setterSubstitution = const {};
    if (class_ != null) {
      var getterClass = getter.enclosingElement as InterfaceElement;
      if (!identical(class_, getterClass)) {
        getterSubstitution = _decoratedClassHierarchy!
            .getDecoratedSupertype(class_, getterClass)
            .asSubstitution;
      }
      var setterClass = setter.enclosingElement as InterfaceElement;
      if (!identical(class_, setterClass)) {
        setterSubstitution = _decoratedClassHierarchy!
            .getDecoratedSupertype(class_, setterClass)
            .asSubstitution;
      }
    }
    _checkAssignment(
        GetterSetterCorrespondenceOrigin(source, node), FixReasonTarget.root,
        source: getType!.substitute(getterSubstitution),
        destination: setType.substitute(setterSubstitution),
        hard: true);
  }

  /// Instantiate [type] with [argumentTypes], assigning [argumentTypes] to
  /// [bounds].
  DecoratedType _handleInstantiation(DecoratedType type,
      List<DecoratedType> argumentTypes, List<EdgeOrigin> edgeOrigins) {
    for (var i = 0; i < argumentTypes.length; ++i) {
      _checkAssignment(
          edgeOrigins.elementAt(i), FixReasonTarget.root.typeArgument(i),
          source: argumentTypes[i],
          destination: DecoratedTypeParameterBounds.current!
              .get((type.type as FunctionType).typeFormals[i])!,
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
  DecoratedType? _handleInvocationArguments(
      AstNode node,
      Iterable<AstNode> arguments,
      TypeArgumentList? typeArguments,
      Iterable<DartType?>? typeArgumentTypes,
      DecoratedType calleeType,
      List<TypeParameterElement>? constructorTypeParameters,
      {DartType? invokeType}) {
    var typeFormals = constructorTypeParameters ?? calleeType.typeFormals!;
    var target = NullabilityNodeTarget.text('invocation').withCodeRef(node);
    if (typeFormals.isNotEmpty) {
      if (typeArguments != null) {
        var argumentTypes = typeArguments.arguments
            .map((t) => _variables.decoratedTypeAnnotation(source, t))
            .toList();
        var origins = typeArguments.arguments
            .map((typeAnnotation) =>
                TypeParameterInstantiationOrigin(source, typeAnnotation))
            .toList();
        if (constructorTypeParameters != null) {
          calleeType = calleeType.substitute(
              Map<TypeParameterElement, DecoratedType>.fromIterables(
                  constructorTypeParameters, argumentTypes));
        } else {
          calleeType = _handleInstantiation(calleeType, argumentTypes, origins);
        }
      } else {
        if (invokeType is FunctionType) {
          var argumentTypes = typeArgumentTypes!
              .map((argType) => DecoratedType.forImplicitType(
                  typeProvider, argType, _graph, target))
              .toList();
          instrumentation?.implicitTypeArguments(source, node, argumentTypes);
          calleeType = _handleInstantiation(
              calleeType,
              argumentTypes,
              List.filled(argumentTypes.length,
                  InferredTypeParameterInstantiationOrigin(source, node)));
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
    var suppliedNamedParameters = <String>{};
    for (var argument in arguments) {
      String? name;
      Expression expression;
      if (argument is NamedExpression) {
        name = argument.name.label.name;
        expression = argument.expression;
      } else if (argument is FormalParameter) {
        if (argument.isNamed) {
          name = argument.name!.lexeme;
        }
        // TODO(scheglov) This is a hack.
        expression = (argument as FormalParameterImpl).identifierForMigration!;
      } else {
        expression = argument as Expression;
      }
      DecoratedType? parameterType;
      if (name != null) {
        parameterType = calleeType.namedParameters![name];
        if (parameterType == null) {
          // TODO(paulberry)
          _unimplemented(expression, 'Missing type for named parameter');
        }
        suppliedNamedParameters.add(name);
      } else {
        if (calleeType.positionalParameters!.length <= i) {
          // TODO(paulberry)
          _unimplemented(node, 'Missing positional parameter at $i');
        }
        parameterType = calleeType.positionalParameters![i++];
      }
      _handleAssignment(expression, destinationType: parameterType);
    }
    // Any parameters not supplied must be optional.
    for (var entry in calleeType.namedParameters!.entries) {
      if (suppliedNamedParameters.contains(entry.key)) continue;
      entry.value.node.recordNamedParameterNotSupplied(
          _guards, _graph, NamedParameterNotSuppliedOrigin(source, node));
    }
    return calleeType.returnType;
  }

  DecoratedType? _handleNullAwareTarget(Expression? target, Expression node) {
    var targetType = _dispatch(target);
    if (target is SimpleIdentifier) {
      var targetElement = target.staticElement;
      if (targetElement is ParameterElement &&
          targetElement.enclosingElement == _currentExecutable &&
          !_currentExecutable!.name.startsWith('_')) {
        _graph.makeNullable(_variables.decoratedElementType(targetElement).node,
            NullAwareAccessOrigin(source, node));
      }
    }
    return targetType;
  }

  DecoratedType? _handleNullCheckHint(
      Expression expression, DecoratedType? type) {
    // Sometimes we think we're looking at an expression but we're really not
    // because we're inside a type name.  If this happens, ignore trailing
    // `/*!*/`s because they're not expression null check hints, they're type
    // non-nullability hints (which are handled by NodeBuilder).
    if (_typeNameNesting > 0) return type;
    var token = expression.endToken;
    if (_nullCheckHints.containsKey(token)) {
      // Already visited this location.
      return type;
    }
    var hint = _nullCheckHints[token] = getPostfixHint(token);
    if (hint != null && hint.kind == HintCommentKind.bang) {
      _variables.recordNullCheckHint(source, expression, hint);
      return type!.withNode(_graph.never);
    } else {
      return type;
    }
  }

  DecoratedType? _handlePropertyAccess(Expression node, Expression? target,
      SimpleIdentifier propertyName, bool isNullAware, bool isCascaded) {
    if (!isCascaded && _isPrefix(target)) {
      return _dispatch(propertyName, skipNullCheckHint: true);
    }
    var callee = getWriteOrReadElement(propertyName);
    return _handlePropertyAccessGeneralized(
        node: node,
        target: target,
        propertyName: propertyName.name,
        isNullAware: isNullAware,
        isCascaded: isCascaded,
        inSetterContext: propertyName.inSetterContext(),
        callee: callee);
  }

  DecoratedType? _handlePropertyAccessGeneralized(
      {required Expression node,
      required Expression? target,
      required String propertyName,
      required bool isNullAware,
      required bool isCascaded,
      required bool inSetterContext,
      required Element? callee}) {
    DecoratedType? targetType;
    bool calleeIsStatic = callee is ExecutableElement && callee.isStatic;
    if (isCascaded) {
      targetType = _currentCascadeTargetType;
    } else if (calleeIsStatic) {
      _dispatch(target);
    } else if (isNullAware) {
      targetType = _handleNullAwareTarget(target, node);
    } else {
      targetType = _handleTarget(target, propertyName, callee);
    }
    DecoratedType? calleeType;
    if (targetType != null &&
        targetType.type is FunctionType &&
        propertyName == 'call') {
      // If `X` has a function type, then in the expression `X.call`, the
      // function being torn off is `X` itself, so the callee type is simply the
      // non-nullable counterpart to the type of `X`.
      var nullabilityNodeTarget =
          NullabilityNodeTarget.text('expression').withCodeRef(node);
      var nullabilityNode =
          NullabilityNode.forInferredType(nullabilityNodeTarget);
      _graph.makeNonNullableUnion(
          nullabilityNode, CallTearOffOrigin(source, node));
      calleeType = targetType.withNode(nullabilityNode);
    } else if (callee != null) {
      calleeType = getOrComputeElementType(node, callee,
          targetType: targetType, targetExpression: target);
    }
    if (calleeType == null) {
      // Dynamic dispatch.
      return _makeNullableDynamicType(node);
    }
    if (inSetterContext) {
      if (isNullAware) {
        _conditionalNodes[node] = targetType!.node;
      }
      return calleeType.positionalParameters![0];
    } else {
      var expressionType = callee is PropertyAccessorElement
          ? calleeType.returnType
          : calleeType;
      if (isNullAware) {
        expressionType = expressionType!.withNode(
            NullabilityNode.forLUB(targetType!.node, expressionType.node));
        _variables.recordDecoratedExpressionType(node, expressionType);
      }
      return expressionType;
    }
  }

  /// Check whether [node] is a call to the quiver package's [`checkNotNull`],
  /// and if so, potentially mark the first argument as non-nullable.
  ///
  /// [`checkNotNull`]: https://pub.dev/documentation/quiver/latest/quiver.check/checkNotNull.html
  void _handleQuiverCheckNotNull(MethodInvocation node) {
    var callee = node.methodName.staticElement;
    var calleeUri = callee?.library?.source.uri;
    var isQuiverCheckNull = callee?.name == 'checkNotNull' &&
        calleeUri != null &&
        calleeUri.isScheme('package') &&
        calleeUri.path.startsWith('quiver/');

    if (isQuiverCheckNull && node.argumentList.arguments.isNotEmpty) {
      var argument = node.argumentList.arguments.first;
      if (argument is SimpleIdentifier && _isReferenceInScope(argument)) {
        var argumentType =
            getOrComputeElementType(argument, argument.staticElement!);
        _graph.makeNonNullable(
            argumentType.node, QuiverCheckNotNullOrigin(source, argument));
      }
    }
  }

  DecoratedType? _handleTarget(
      Expression? target, String name, Element? callee) {
    if (isDeclaredOnObject(name)) {
      return _dispatch(target);
    } else if ((callee is MethodElement || callee is PropertyAccessorElement) &&
        callee!.enclosingElement is ExtensionElement) {
      // Extension methods can be called on a `null` target, when the `on` type
      // of the extension is nullable.  Note: we don't need to check whether the
      // target type is assignable to the extended type; that is done in
      // [getOrComputeElementType].
      return _dispatch(target);
    } else {
      return _checkExpressionNotNull(target!);
    }
  }

  void _handleUninitializedFields(AstNode node, Set<FieldElement?> fields) {
    for (var field in fields) {
      _graph.makeNullable(_variables.decoratedElementType(field!).node,
          FieldNotInitializedOrigin(source, node));
    }
  }

  /// Returns whether [_currentFunctionExpression] is an argument to the test
  /// package's `setUp` function.
  bool _isCurrentFunctionExpressionFoundInTestSetUpCall() {
    var parent = _currentFunctionExpression?.parent;
    if (parent is ArgumentList) {
      var grandParent = parent.parent;
      if (grandParent is MethodInvocation) {
        var enclosingInvocation = grandParent.methodName;
        if (enclosingInvocation.name == 'setUp') {
          var uri = enclosingInvocation.staticElement!.library?.source.uri;
          if (uri != null &&
              uri.isScheme('package') &&
              uri.path.startsWith('test_core/')) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _isPrefix(Expression? e) =>
      e is SimpleIdentifier && e.staticElement is PrefixElement;

  bool _isReferenceInScope(Expression expression) {
    var element = _referencedElement(expression);
    return element != null && _postDominatedLocals.isInScope(element);
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

  void _linkDecoratedTypeParameters(
      DecoratedType x, DecoratedType? y, EdgeOrigin origin,
      {bool isUnion = true}) {
    for (int i = 0;
        i < x.positionalParameters!.length &&
            i < y!.positionalParameters!.length;
        i++) {
      _linkDecoratedTypes(
          x.positionalParameters![i], y.positionalParameters![i], origin,
          isUnion: isUnion);
    }
    for (var entry in x.namedParameters!.entries) {
      var superParameterType = y!.namedParameters![entry.key];
      if (superParameterType != null) {
        _linkDecoratedTypes(entry.value, y.namedParameters![entry.key], origin,
            isUnion: isUnion);
      }
    }
  }

  void _linkDecoratedTypes(DecoratedType x, DecoratedType? y, EdgeOrigin origin,
      {bool isUnion = true}) {
    if (isUnion) {
      _graph.union(x.node, y!.node, origin);
    } else {
      _graph.connect(x.node, y!.node, origin, hard: true);
    }
    _linkDecoratedTypeParameters(x, y, origin, isUnion: isUnion);
    for (int i = 0;
        i < x.typeArguments.length && i < y.typeArguments.length;
        i++) {
      _linkDecoratedTypes(x.typeArguments[i]!, y.typeArguments[i], origin,
          isUnion: isUnion);
    }
    if (x.returnType != null && y.returnType != null) {
      _linkDecoratedTypes(x.returnType!, y.returnType, origin,
          isUnion: isUnion);
    }
  }

  void _makeArgumentsNullable(
      ExecutableElement declaredElement, Declaration node) {
    for (final p in declaredElement.parameters) {
      if (p is! FieldFormalParameterElement &&
          p is! SuperFormalParameterElement &&
          p is! ConstVariableElement) {
        final decoratedType = _variables.decoratedElementType(p);
        if (decoratedType.type is TypeParameterType) continue;
        _graph.makeNullable(
            decoratedType.node, PublicMethodArgumentOrigin(source, node));
      }
    }
  }

  EdgeOrigin _makeEdgeOrigin(DecoratedType sourceType, Expression expression,
      {bool isSetupAssignment = false}) {
    if (sourceType.type is DynamicType) {
      return DynamicAssignmentOrigin(source, expression,
          isSetupAssignment: isSetupAssignment);
    } else {
      ExpressionChecksOrigin expressionChecksOrigin = ExpressionChecksOrigin(
          source, expression, ExpressionChecks(),
          isSetupAssignment: isSetupAssignment);
      _variables.recordExpressionChecks(
          source, expression, expressionChecksOrigin);
      return expressionChecksOrigin;
    }
  }

  DecoratedType _makeNonNullableBoolType(Expression expression) {
    assert(expression.staticType!.isDartCoreBool);
    var target =
        NullabilityNodeTarget.text('expression').withCodeRef(expression);
    var nullabilityNode = NullabilityNode.forInferredType(target);
    _graph.makeNonNullableUnion(
        nullabilityNode, NonNullableBoolTypeOrigin(source, expression));
    return DecoratedType(typeProvider.boolType, nullabilityNode);
  }

  DecoratedType _makeNonNullLiteralType(Expression expression,
      {List<DecoratedType?> typeArguments = const []}) {
    var target =
        NullabilityNodeTarget.text('expression').withCodeRef(expression);
    var nullabilityNode = NullabilityNode.forInferredType(target);
    _graph.makeNonNullableUnion(
        nullabilityNode, LiteralOrigin(source, expression));
    return DecoratedType(expression.staticType, nullabilityNode,
        typeArguments: typeArguments);
  }

  DecoratedType _makeNullableDynamicType(AstNode astNode) {
    var target =
        NullabilityNodeTarget.text('dynamic type').withCodeRef(astNode);
    var decoratedType = DecoratedType.forImplicitType(
        typeProvider, typeProvider.dynamicType, _graph, target);
    _graph.makeNullable(
        decoratedType.node, AlwaysNullableTypeOrigin(source, astNode, false));
    return decoratedType;
  }

  DecoratedType _makeNullableVoidType(SimpleIdentifier astNode) {
    var target = NullabilityNodeTarget.text('void type').withCodeRef(astNode);
    var decoratedType = DecoratedType.forImplicitType(
        typeProvider, typeProvider.voidType, _graph, target);
    _graph.makeNullable(
        decoratedType.node, AlwaysNullableTypeOrigin(source, astNode, true));
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

  /// Returns the element referenced directly by [expression], if any; otherwise
  /// returns `null`.
  Element? _referencedElement(Expression expression) {
    expression = expression.unParenthesized;
    if (expression is SimpleIdentifier) {
      return _favorFieldFormalElements(expression.staticElement);
    } else if (expression is ThisExpression || expression is SuperExpression) {
      return _extensionThis;
    } else {
      return null;
    }
  }

  /// Determines whether uses of [expression] should cause hard edges to be
  /// created in the nullability graph.
  ///
  /// If [isConditionallyExecuted] is `true`, that indicates that [expression]
  /// appears in a context where it might not get executed (e.g. on the RHS of
  /// a `??=`).
  bool _shouldUseHardEdge(Expression expression,
      {bool isConditionallyExecuted = false}) {
    expression = expression.unParenthesized;
    if (expression is ListLiteral || expression is SetOrMapLiteral) {
      // List, set, and map literals have either explicit or implicit type
      // arguments.  If supplying a nullable type for one of these type
      // arguments would lead to an error (e.g. `f(<int?>[])` where `f` requires
      // a `List<int>`), then we should use a hard edge, to ensure that the
      // migrated type argument will be non-nullable.
      return true;
    } else if (expression is AsExpression) {
      // "as" expressions have an explicit type.  If making this type nullable
      // would lead to an error (e.g. `f(x as int?)` where `f` requires an
      // `int`),then we should use a hard edge, to ensure that the migrated type
      // will be non-nullable.
      return true;
    }
    // For other expressions, we should use a hard edge only if (a) the
    // expression is unconditionally executed, and (b) the expression is a
    // reference to a local variable or parameter and it post-dominates the
    // declaration of that local variable or parameter.
    return !isConditionallyExecuted && _isReferenceInScope(expression);
  }

  DecoratedType? _thisOrSuper(Expression node) {
    if (_currentInterfaceOrExtension == null) {
      return null;
    }

    NullabilityNode makeNonNullableNode(NullabilityNodeTarget target) {
      var nullabilityNode = NullabilityNode.forInferredType(target);
      _graph.makeNonNullableUnion(nullabilityNode,
          ThisOrSuperOrigin(source, node, node is ThisExpression));
      return nullabilityNode;
    }

    var token = node.beginToken.lexeme;
    var target =
        NullabilityNodeTarget.text('$token expression').withCodeRef(node);
    if (_currentInterfaceOrExtension is InterfaceElement) {
      final type = (_currentInterfaceOrExtension as InterfaceElement).thisType;

      // Instantiate the type, and any type arguments, with non-nullable types,
      // because the type of `this` is always `ClassName<Param, Param, ...>`
      // with no `?`s.  (Even if some of the type parameters are allowed to be
      // instantiated with nullable types at runtime, a reference to `this`
      // can't be migrated in such a way that forces them to be nullable.)
      var index = 0;
      return DecoratedType(type, makeNonNullableNode(target),
          typeArguments: type.typeArguments
              .map((t) => DecoratedType(
                  t, makeNonNullableNode(target.typeArgument(index++))))
              .toList());
    } else {
      assert(_currentInterfaceOrExtension is ExtensionElement);
      assert(_currentExtendedType != null);
      return _currentExtendedType;
    }
  }

  /// If [node] is an `orElse` argument to an iterable method that should be
  /// transformed, performs the necessary assignment checks on the expression
  /// type and returns `true` (this indicates to the caller that no further
  /// assignment checks need to be performed); otherwise returns `false`.
  bool _tryTransformOrElse(Expression? expression, DecoratedType sourceType) {
    var transformationInfo =
        _whereOrNullTransformer.tryTransformOrElseArgument(expression);
    if (transformationInfo != null) {
      // Don't build any edges for this argument; if necessary we'll transform
      // it rather than make things nullable.  But do save the nullability of
      // the return value of the `orElse` method, so that we can later connect
      // it to the nullability of the value returned from the method
      // invocation.
      var extraNullability = sourceType.returnType!.node;
      _deferredMethodInvocationProcessing[transformationInfo.methodInvocation] =
          (methodInvocationType) {
        var newNode = NullabilityNode.forInferredType(
            NullabilityNodeTarget.text(
                'return value from ${transformationInfo.originalName}'));
        var origin = IteratorMethodReturnOrigin(
            source, transformationInfo.methodInvocation);
        _graph.connect(methodInvocationType!.node, newNode, origin);
        _graph.connect(extraNullability, newNode, origin);
        return methodInvocationType.withNode(newNode);
      };
      return true;
    } else {
      return false;
    }
  }

  /// If [node] is a call to `Iterable.where` that should be transformed,
  /// performs the necessary assignment checks on the expression type and
  /// returns `true` (this indicates to the caller that no further assignment
  /// checks need to be performed); otherwise returns `false`.
  bool _tryTransformWhere(Expression? expression, EdgeOrigin edgeOrigin,
      DecoratedType sourceType, DecoratedType destinationType) {
    var transformationInfo =
        _whereNotNullTransformer.tryTransformMethodInvocation(expression);
    if (transformationInfo != null) {
      _checkAssignment(edgeOrigin, FixReasonTarget.root,
          source: _whereNotNullTransformer.transformDecoratedInvocationType(
              sourceType, _graph),
          destination: destinationType,
          hard: false);
      return true;
    } else {
      return false;
    }
  }

  Never _unimplemented(AstNode? node, String message) {
    StringBuffer buffer = StringBuffer();
    buffer.write(message);
    if (node != null) {
      CompilationUnit unit = node.root as CompilationUnit;
      buffer.write(' in "');
      buffer.write(node.toSource());
      buffer.write('" on line ');
      buffer.write(unit.lineInfo.getLocation(node.offset).lineNumber);
      buffer.write(' of "');
      buffer.write(unit.declaredElement!.source.fullName);
      buffer.write('"');
    }
    throw UnimplementedError(buffer.toString());
  }

  /// Produce Future<flatten(T)> for some T, however, we would like to merely
  /// upcast T to that type if possible, skipping the flatten when not
  /// necessary.
  DecoratedType _wrapFuture(DecoratedType type, AstNode? node) {
    var dartType = type.type!;
    if (dartType.isDartCoreNull || dartType.isBottom) {
      return _futureOf(type, node!);
    }

    if (dartType is InterfaceType &&
        dartType.element == typeProvider.futureOrElement) {
      var typeArguments = type.typeArguments;
      if (typeArguments.length == 1) {
        // Wrapping FutureOr<T?1>?2 should produce Future<T?3>, where either 1
        // or 2 being nullable causes 3 to become nullable.
        var typeArgument = typeArguments[0]!;
        return _futureOf(
            typeArgument
                .withNode(NullabilityNode.forLUB(typeArgument.node, type.node)),
            node!);
      }
    }

    if (_typeSystem.isSubtypeOf(dartType, typeProvider.futureDynamicType)) {
      return _decoratedClassHierarchy!
          .asInstanceOf(type, typeProvider.futureElement);
    }

    return _futureOf(type, node!);
  }

  /// If the [node] is the finishing identifier of an assignment, return its
  /// "writeElement", otherwise return its "staticElement", which might be
  /// thought as the "readElement".
  static Element? getWriteOrReadElement(AstNode node) {
    var writeElement = _getWriteElement(node);
    if (writeElement != null) {
      return writeElement;
    }

    if (node is IndexExpression) {
      return node.staticElement;
    } else if (node is SimpleIdentifier) {
      return node.staticElement;
    } else {
      return null;
    }
  }

  /// If the [node] is the target of a [CompoundAssignmentExpression],
  /// return the corresponding "writeElement", which is the local variable,
  /// the setter referenced with a [SimpleIdentifier] or a [PropertyAccess],
  /// or the `[]=` operator.
  static Element? _getWriteElement(AstNode node) {
    var parent = node.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == node) {
      return parent.writeElement;
    } else if (parent is PostfixExpression) {
      return parent.writeElement;
    } else if (parent is PrefixExpression) {
      return parent.writeElement;
    }

    if (parent is PrefixedIdentifier && parent.identifier == node) {
      return _getWriteElement(parent);
    } else if (parent is PropertyAccess && parent.propertyName == node) {
      return _getWriteElement(parent);
    } else {
      return null;
    }
  }

  /// Whether `expression` is a call to Angular's [Injector.get], with exactly
  /// one argument.
  static bool _isInjectorGetCall(Expression expression) {
    if (expression is! MethodInvocation) {
      return false;
    }

    if (expression.methodName.name != 'get') {
      return false;
    }
    if (expression.argumentList.arguments.length != 1) {
      // If a second argument is passed, which may indicate that a non-null
      // value isn't necessarily expected, don't count this call.
      return false;
    }

    var target = expression.target;
    if (target is! Identifier) {
      return false;
    }

    var receiver = target.staticType?.element;
    if (receiver?.name != 'Injector') {
      return false;
    }

    var uri = receiver?.library?.source.uri;
    return uri != null &&
        uri.isScheme('package') &&
        uri.path.startsWith('angular/');
  }
}

/// Implementation of [_checkAssignment] for [EdgeBuilder].
///
/// This has been moved to its own mixin to allow it to be more easily unit
/// tested.
mixin _AssignmentChecker {
  TypeProvider get typeProvider;

  DecoratedClassHierarchy? get _decoratedClassHierarchy;

  TypeSystem get _typeSystem;

  /// Creates the necessary constraint(s) for an assignment from [source] to
  /// [destination].  [origin] should be used as the origin for any edges
  /// created.  [hard] indicates whether a hard edge should be created.
  /// [sourceIsFunctionLiteral] indicates whether the source of the assignment
  /// is a function literal expression.
  void _checkAssignment(EdgeOrigin origin, FixReasonTarget edgeTarget,
      {required DecoratedType source,
      required DecoratedType destination,
      required bool hard,
      bool checkable = true,
      bool sourceIsFunctionLiteral = false}) {
    var sourceType = source.type!;
    var destinationType = destination.type!;
    if (!_typeSystem.isSubtypeOf(sourceType, destinationType)) {
      // Not a proper upcast assignment.
      if (_typeSystem.isSubtypeOf(destinationType, sourceType)) {
        // But rather a downcast.
        _checkDowncast(origin,
            source: source, destination: destination, hard: hard);
        return;
      }
      if (destinationType is FunctionType) {
        var callMethodType = _getCallMethodType(source);
        if (callMethodType != null) {
          // Handle implicit `.call` coercion
          _checkAssignment(origin, edgeTarget,
              source: callMethodType,
              destination: destination,
              hard: false,
              checkable: false,
              sourceIsFunctionLiteral: sourceIsFunctionLiteral);
          return;
        }
      }
      // A side cast. This may be an explicit side cast, or illegal code. There
      // is no nullability we can infer here.
      assert(
          _assumeNonNullabilityInCasts,
          'side cast not supported without assuming non-nullability:'
          ' $sourceType to $destinationType');
      _connect(source.node, destination.node, origin, edgeTarget, hard: hard);
      return;
    }
    _connect(source.node, destination.node, origin, edgeTarget,
        hard: hard, checkable: checkable);
    _checkAssignment_recursion(origin, edgeTarget,
        source: source,
        destination: destination,
        sourceIsFunctionLiteral: sourceIsFunctionLiteral,
        hard: hard);
  }

  /// Does the recursive part of [_checkAssignment], visiting all of the types
  /// constituting [source] and [destination], and creating the appropriate
  /// edges between them.  [sourceIsFunctionLiteral] indicates whether the
  /// source of the assignment is a function literal expression.
  void _checkAssignment_recursion(EdgeOrigin origin, FixReasonTarget edgeTarget,
      {required DecoratedType source,
      required DecoratedType destination,
      bool sourceIsFunctionLiteral = false,
      bool hard = false}) {
    var sourceType = source.type!;
    var destinationType = destination.type!;
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
        var s0 = source.typeArguments[0]!;
        _checkAssignment(origin, edgeTarget.yieldedType,
            source: s0, destination: s1!, hard: false);
        return;
      }
      // (From the subtyping spec):
      // if T1 is FutureOr<S1> then T0 <: T1 iff any of the following hold:
      // - either T0 <: Future<S1>
      if (_typeSystem.isSubtypeOf(
          sourceType, typeProvider.futureType(s1!.type!))) {
        // E.g. FutureOr<int> = (... as Future<int>)
        // This is handled by the InterfaceType logic below, since we treat
        // FutureOr as a supertype of Future.
      }
      // - or T0 <: S1
      else if (_typeSystem.isSubtypeOf(sourceType, s1.type!)) {
        // E.g. FutureOr<int> = (... as int)
        _checkAssignment_recursion(origin, edgeTarget.yieldedType,
            source: source, destination: s1);
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
        _checkAssignment(origin, edgeTarget,
            source: _getTypeParameterTypeBound(source)!,
            destination: destination,
            hard: false);
        return;
      }
    } else if (destinationType is DynamicType ||
        destinationType is VoidType ||
        destinationType.isDartCoreObject) {
      // No further edges need to be created, since all types are trivially
      // subtypes of dynamic, Object, and void, since all are treated as
      // equivalent to dynamic for subtyping purposes.
    } else if (sourceType is InterfaceType &&
        destinationType is InterfaceType) {
      var rewrittenSource = _decoratedClassHierarchy!
          .asInstanceOf(source, destinationType.element);
      assert(rewrittenSource.typeArguments.length ==
          destination.typeArguments.length);
      for (int i = 0; i < rewrittenSource.typeArguments.length; i++) {
        _checkAssignment(origin, edgeTarget.typeArgument(i),
            source: rewrittenSource.typeArguments[i]!,
            destination: destination.typeArguments[i]!,
            hard: hard,
            checkable: false);
      }
    } else if (sourceType is FunctionType && destinationType is FunctionType) {
      // If the source is a function literal, we want a hard edge, so that if a
      // function returning non-null is required, we will insure that the
      // function literal has a non-nullable return type (e.g. by inserting null
      // checks into the function literal).
      _checkAssignment(origin, edgeTarget.returnType,
          source: source.returnType!,
          destination: destination.returnType!,
          hard: sourceIsFunctionLiteral,
          checkable: false);
      if (source.typeArguments.isNotEmpty ||
          destination.typeArguments.isNotEmpty) {
        throw UnimplementedError('TODO(paulberry)');
      }
      for (int i = 0;
          i < source.positionalParameters!.length &&
              i < destination.positionalParameters!.length;
          i++) {
        // Note: source and destination are swapped due to contravariance.
        _checkAssignment(origin, edgeTarget.positionalParameter(i),
            source: destination.positionalParameters![i],
            destination: source.positionalParameters![i],
            hard: false,
            checkable: false);
      }
      for (var entry in destination.namedParameters!.entries) {
        // Note: source and destination are swapped due to contravariance.
        _checkAssignment(origin, edgeTarget.namedParameter(entry.key),
            source: entry.value,
            destination: source.namedParameters![entry.key]!,
            hard: false,
            checkable: false);
      }
    } else if (destinationType is DynamicType || sourceType is DynamicType) {
      // ok; nothing further to do.
    } else if (destinationType is InterfaceType && sourceType is FunctionType) {
      // Either this is an upcast to Function or Object, or it is erroneous
      // code.  In either case we don't need to create any additional edges.
    } else {
      throw '$destination <= $source'; // TODO(paulberry)
    }
  }

  void _checkDowncast(EdgeOrigin origin,
      {required DecoratedType source,
      required DecoratedType destination,
      required bool hard}) {
    var destinationType = destination.type!;
    final sourceType = source.type!;
    assert(_typeSystem.isSubtypeOf(destinationType, sourceType));
    // Nullability should narrow to maintain subtype relationship.
    _connect(source.node, destination.node, origin, FixReasonTarget.root,
        hard: hard);

    if (sourceType is DynamicType ||
        sourceType.isDartCoreObject ||
        sourceType is VoidType) {
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
    } else if (destinationType.isDartCoreNull) {
      // There's not really much we can infer from trying to assign a type to
      // Null.  We could say that the source of the assignment must be nullable,
      // but that's not really useful because the nullability won't propagate
      // anywhere.  Besides, the code is probably erroneous (e.g. the user is
      // trying to store a value into a `List<Null>`).  So do nothing.
      return;
    } else if (destinationType is TypeParameterType) {
      if (sourceType is! TypeParameterType) {
        // Assume an assignment to the type parameter's bound.
        _checkAssignment(origin, FixReasonTarget.root,
            source: source,
            destination: _getTypeParameterTypeBound(destination)!,
            hard: false);
      } else if (destinationType == sourceType) {
        // Nothing to do.
        return;
      }
    } else if (sourceType.isDartAsyncFutureOr) {
      if (destination.type!.isDartAsyncFuture) {
        // FutureOr<T?> is nullable, so the Future<T> should be nullable too.
        _connect(source.typeArguments[0]!.node, destination.node, origin,
            FixReasonTarget.root.yieldedType,
            hard: hard);
        _checkDowncast(origin,
            source: source.typeArguments[0]!,
            destination: destination.typeArguments[0]!,
            hard: false);
      } else if (destination.type!.isDartAsyncFutureOr) {
        _checkDowncast(origin,
            source: source.typeArguments[0]!,
            destination: destination.typeArguments[0]!,
            hard: false);
      } else {
        _checkDowncast(origin,
            source: source.typeArguments[0]!,
            destination: destination,
            hard: false);
      }
    } else if (destinationType is InterfaceType) {
      if (sourceType is InterfaceType) {
        final target = _decoratedClassHierarchy!
            .asInstanceOf(destination, sourceType.element);
        for (var i = 0; i < source.typeArguments.length; ++i) {
          _checkDowncast(origin,
              source: source.typeArguments[i]!,
              destination: target.typeArguments[i]!,
              hard: false);
        }
      } else {
        assert(false,
            'downcasting from ${sourceType.runtimeType} to interface type');
      }
    } else if (destinationType is FunctionType) {
      if (sourceType.isDartCoreFunction) {
        // Nothing else to do.
        return;
      }
    } else {
      assert(
          false,
          'downcasting from ${sourceType.runtimeType} to '
          '${destinationType.runtimeType} not supported. ($sourceType $destinationType)');
    }
  }

  void _connect(NullabilityNode? source, NullabilityNode? destination,
      EdgeOrigin origin, FixReasonTarget edgeTarget,
      {bool hard = false, bool checkable = true});

  /// If [type] represents a class containing a `call` method, returns the
  /// decorated type of the `call` method, with appropriate substitutions.
  /// Otherwise returns `null`.
  DecoratedType? _getCallMethodType(DecoratedType type);

  /// Given a [type] representing a type parameter, retrieves the type's bound.
  DecoratedType? _getTypeParameterTypeBound(DecoratedType type);
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
  final bool? postDominatingIntent;

  /// If not `null`, the [NullabilityNode] that would need to be nullable in
  /// order for [condition] to evaluate to `true`.
  final NullabilityNode? trueGuard;

  /// If not `null`, the [NullabilityNode] that would need to be nullable in
  /// order for [condition] to evaluate to `false`.
  final NullabilityNode? falseGuard;

  /// If not `null`, the [NullabilityNode] that should be asserted to have
  /// non-null intent if [condition] is asserted to be `true`.
  final NullabilityNode? trueDemonstratesNonNullIntent;

  /// If not `null`, the [NullabilityNode] that should be asserted to have
  /// non-null intent if [condition] is asserted to be `false`.
  final NullabilityNode? falseDemonstratesNonNullIntent;

  _ConditionInfo(this.condition,
      {required this.isPure,
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

extension on DartType? {
  DartType? get explicitBound {
    final self = this;
    if (self is TypeParameterType &&
        self.nullabilitySuffix == NullabilitySuffix.star) {
      return self.element.bound.explicitBound;
    }
    return self;
  }
}
