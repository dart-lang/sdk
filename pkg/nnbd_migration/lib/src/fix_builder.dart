// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/null_safety_understanding_flag.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/best_practices_verifier.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:analyzer/src/generated/migration.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/fix_reason_target.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/fix_aggregator.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/utilities/hint_utils.dart';
import 'package:nnbd_migration/src/utilities/permissive_mode.dart';
import 'package:nnbd_migration/src/utilities/resolution_utils.dart';
import 'package:nnbd_migration/src/utilities/where_or_null_transformer.dart';
import 'package:nnbd_migration/src/variables.dart';
import 'package:pub_semver/pub_semver.dart';

bool _isIncrementOrDecrementOperator(TokenType tokenType) {
  switch (tokenType) {
    case TokenType.PLUS_PLUS:
    case TokenType.MINUS_MINUS:
      return true;
    default:
      return false;
  }
}

/// Problem reported by [FixBuilder] when encountering a compound assignment
/// for which the combination result is nullable.  This occurs if the compound
/// assignment resolves to a user-defined operator that returns a nullable type,
/// but the target of the assignment expects a non-nullable type.  We need to
/// add a null check but it's nontrivial to do so because we would have to
/// rewrite the assignment as an ordinary assignment (e.g. change `x += y` to
/// `x = (x + y)!`), but that might change semantics by causing subexpressions
/// of the target to be evaluated twice.
///
/// TODO(paulberry): consider alternatives.
/// See https://github.com/dart-lang/sdk/issues/38675.
class CompoundAssignmentCombinedNullable implements Problem {
  const CompoundAssignmentCombinedNullable();
}

/// Problem reported by [FixBuilder] when encountering a compound assignment
/// for which the value read from the target of the assignment has a nullable
/// type.  We need to add a null check but it's nontrivial to do so because we
/// would have to rewrite the assignment as an ordinary assignment (e.g. change
/// `x += y` to `x = x! + y`), but that might change semantics by causing
/// subexpressions of the target to be evaluated twice.
///
/// TODO(paulberry): consider alternatives.
/// See https://github.com/dart-lang/sdk/issues/38676.
class CompoundAssignmentReadNullable implements Problem {
  const CompoundAssignmentReadNullable();
}

/// This class runs the analyzer's resolver over the code being migrated, after
/// graph propagation, to figure out what changes need to be made.  It doesn't
/// actually make the changes; it simply reports what changes are necessary
/// through abstract methods.
class FixBuilder {
  final DecoratedClassHierarchy _decoratedClassHierarchy;

  /// The type provider providing non-nullable types.
  final TypeProvider typeProvider;

  final Map<AstNode, NodeChange> changes = {};

  final Map<AstNode, Set<Problem>> problems = {};

  /// The NNBD type system.
  final TypeSystemImpl _typeSystem;

  /// Variables for this migration run.
  final Variables _variables;

  /// The file being analyzed.
  final Source source;

  ResolverVisitor _resolver;

  /// The listener to which exceptions should be reported.
  final NullabilityMigrationListener listener;

  /// The compilation unit for which fixes are being built.
  final CompilationUnit unit;

  final MigrationResolutionHooksImpl migrationResolutionHooks;

  /// Parameter elements for which an explicit type should be added, and what
  /// that type should be.
  final Map<ParameterElement, DartType> _addedParameterTypes = {};

  final bool warnOnWeakCode;

  final NullabilityGraph _graph;

  /// Helper that assists us in transforming Iterable methods to their "OrNull"
  /// equivalents.
  final WhereOrNullTransformer _whereOrNullTransformer;

  /// Indicates whether an import of package:collection's `IterableExtension`
  /// will need to be added.
  @visibleForTesting
  bool needsIterableExtension = false;

  /// Map of additional package dependencies that will be required by the
  /// migrated code.  Keys are package names; values indicate the minimum
  /// required version of each package.
  final Map<String, Version> _neededPackages;

  factory FixBuilder(
      Source source,
      DecoratedClassHierarchy decoratedClassHierarchy,
      TypeProvider typeProvider,
      TypeSystemImpl typeSystem,
      Variables variables,
      LibraryElement definingLibrary,
      NullabilityMigrationListener listener,
      CompilationUnit unit,
      bool warnOnWeakCode,
      NullabilityGraph graph,
      Map<String, Version> neededPackages) {
    var migrationResolutionHooks = MigrationResolutionHooksImpl();
    return FixBuilder._(
        decoratedClassHierarchy,
        _makeNnbdTypeSystem(
            (typeProvider as TypeProviderImpl).asNonNullableByDefault,
            typeSystem,
            migrationResolutionHooks),
        variables,
        source,
        definingLibrary,
        listener,
        unit,
        migrationResolutionHooks,
        warnOnWeakCode,
        graph,
        neededPackages);
  }

  FixBuilder._(
      this._decoratedClassHierarchy,
      this._typeSystem,
      this._variables,
      this.source,
      LibraryElement definingLibrary,
      this.listener,
      this.unit,
      this.migrationResolutionHooks,
      this.warnOnWeakCode,
      this._graph,
      this._neededPackages)
      : typeProvider = _typeSystem.typeProvider,
        _whereOrNullTransformer =
            WhereOrNullTransformer(_typeSystem.typeProvider, _typeSystem) {
    migrationResolutionHooks._fixBuilder = this;
    assert(_typeSystem.isNonNullableByDefault);
    assert((typeProvider as TypeProviderImpl).isNonNullableByDefault);
    var inheritanceManager = InheritanceManager3();
    // TODO(paulberry): is it a bad idea to throw away errors?
    var errorListener = AnalysisErrorListener.NULL_LISTENER;
    // TODO(paulberry): once the feature is no longer experimental, change the
    // way we enable it in the resolver.
    // ignore: invalid_use_of_visible_for_testing_member
    var featureSet = FeatureSet.forTesting(
        sdkVersion: '2.6.0', additionalFeatures: [Feature.non_nullable]);
    _resolver = ResolverVisitorForMigration(
        inheritanceManager,
        definingLibrary,
        source,
        typeProvider,
        errorListener,
        _typeSystem,
        featureSet,
        migrationResolutionHooks);
  }

  /// Visits the entire compilation [unit] using the analyzer's resolver and
  /// makes note of changes that need to be made.
  void visitAll() {
    try {
      NullSafetyUnderstandingFlag.enableNullSafetyTypes(() {
        ElementTypeProvider.current = migrationResolutionHooks;
        unit.accept(_FixBuilderPreVisitor(this));
        unit.accept(_resolver);
        unit.accept(_FixBuilderPostVisitor(this));
      });
    } catch (exception, stackTrace) {
      if (listener != null) {
        listener.reportException(source, unit, exception, stackTrace);
      } else {
        rethrow;
      }
    } finally {
      ElementTypeProvider.current = const ElementTypeProvider();
    }
  }

  /// Called whenever an AST node is found that can't be automatically fixed.
  void _addProblem(AstNode node, Problem problem) {
    var newlyAdded = (problems[node] ??= {}).add(problem);
    assert(newlyAdded);
  }

  /// Computes the type that [element] will have after migration.
  ///
  /// If [targetType] is present, and [element] is a class member, it is the
  /// type of the class within which [element] is being accessed; this is used
  /// to perform the correct substitutions.
  DartType _computeMigratedType(Element element) {
    element = element.declaration;
    if (element is ClassElement || element is TypeParameterElement) {
      return typeProvider.typeType;
    } else if (element is PropertyAccessorElement &&
        element.isSynthetic &&
        !element.variable.isSynthetic) {
      var variableType = _variables
          .toFinalType(_variables.decoratedElementType(element.variable));
      if (element.isSetter) {
        return FunctionTypeImpl(
            returnType: typeProvider.voidType,
            typeFormals: [],
            parameters: [
              ParameterElementImpl.synthetic(
                  'value', variableType, ParameterKind.REQUIRED)
            ],
            nullabilitySuffix: NullabilitySuffix.none);
      } else {
        return FunctionTypeImpl(
            returnType: variableType,
            typeFormals: [],
            parameters: [],
            nullabilitySuffix: NullabilitySuffix.none);
      }
    } else {
      return _variables.toFinalType(_variables.decoratedElementType(element));
    }
  }

  /// Returns the [NodeChange] object accumulating changes for the given [node],
  /// creating it if necessary.
  NodeChange _getChange(AstNode node) =>
      changes[node] ??= NodeChange.create(node);

  /// Determines whether the given [node], which is a null-aware method
  /// invocation, property access, or index expression, should remain null-aware
  /// after migration.
  bool _shouldStayNullAware(Expression node) {
    Expression target;
    if (node is PropertyAccess) {
      target = node.target;
    } else if (node is MethodInvocation) {
      target = node.target;
    } else {
      throw StateError('Unexpected expression type: ${node.runtimeType}');
    }
    if (!_typeSystem.isPotentiallyNullable(target.staticType)) {
      (_getChange(node) as NodeChangeForNullAware).removeNullAwareness = true;
      return false;
    }
    return true;
  }

  static TypeSystemImpl _makeNnbdTypeSystem(
      TypeProvider nnbdTypeProvider,
      TypeSystemImpl typeSystem,
      MigrationResolutionHooksImpl migrationResolutionHooks) {
    // TODO(paulberry): do we need to test both possible values of
    // strictInference?
    return TypeSystemImpl(
        implicitCasts: typeSystem.implicitCasts,
        isNonNullableByDefault: true,
        strictInference: typeSystem.strictInference,
        typeProvider: nnbdTypeProvider);
  }
}

/// Fix reason object when adding a null check because of an explicit hint.
class FixReason_NullCheckHint implements SimpleFixReasonInfo {
  @override
  final CodeReference codeReference;

  FixReason_NullCheckHint(this.codeReference);

  @override
  String get description => 'Null check hint';
}

/// Implementation of [MigrationResolutionHooks] that interfaces with
/// [FixBuilder].
class MigrationResolutionHooksImpl
    with ResolutionUtils
    implements MigrationResolutionHooks {
  FixBuilder _fixBuilder;

  final Expando<List<CollectionElement>> _collectionElements = Expando();

  final Expando<bool> _shouldStayNullAware = Expando();

  final Map<Expression, _AssignmentLikeExpressionHandler>
      _assignmentLikeExpressionHandlers = {};

  FlowAnalysis<AstNode, Statement, Expression, PromotableElement, DartType>
      _flowAnalysis;

  /// Deferred processing that should be performed once we have finished
  /// evaluating the type of a method invocation.
  final Map<MethodInvocation, DartType Function(DartType)>
      _deferredMethodInvocationProcessing = {};

  TypeProvider get typeProvider => _fixBuilder.typeProvider;

  @override
  void freshTypeParameterCreated(TypeParameterElement newTypeParameter,
      TypeParameterElement oldTypeParameter) {
    DecoratedTypeParameterBounds.current.put(newTypeParameter,
        DecoratedTypeParameterBounds.current.get(oldTypeParameter));
  }

  @override
  List<InterfaceType> getClassInterfaces(ClassElementImpl element) {
    return _wrapExceptions(
        _fixBuilder.unit,
        () => element.interfacesInternal,
        () => [
              for (var interface in element.interfacesInternal)
                _getClassInterface(element, interface.element)
            ]);
  }

  @override
  bool getConditionalKnownValue(AstNode node) =>
      _wrapExceptions(node, () => null, () {
        // TODO(paulberry): handle conditional expressions.
        var conditionalDiscard = _fixBuilder._variables
            .getConditionalDiscard(_fixBuilder.source, node);
        if (conditionalDiscard == null) {
          return null;
        } else {
          if (conditionalDiscard.keepTrue && conditionalDiscard.keepFalse) {
            return null;
          }
          var conditionValue = conditionalDiscard.keepTrue;
          (_fixBuilder._getChange(node) as NodeChangeForConditional)
            ..conditionValue = conditionValue
            ..conditionReason = conditionalDiscard.reason;
          // If we're just issuing warnings, instruct the resolver to go ahead
          // and visit both branches of the conditional.
          return _fixBuilder.warnOnWeakCode ? null : conditionValue;
        }
      });

  @override
  List<ParameterElement> getExecutableParameters(
      ExecutableElementImpl element) {
    if (_fixBuilder._graph.isBeingMigrated(element.library.source)) {
      // The element is part of a library that's being migrated, so its
      // parameters all have been visited (and thus have their own final
      // types).  So we don't need to do anything.
      return const ElementTypeProvider().getExecutableParameters(element);
    } else {
      // The element is not part of a library that's being migrated, so its
      // parameters probably haven't been visited; we need to get the parameters
      // from the final function type.
      return getExecutableType(element).parameters;
    }
  }

  @override
  DartType getExecutableReturnType(Element element) =>
      getExecutableType(element as ElementImplWithFunctionType).returnType;

  @override
  FunctionType getExecutableType(ElementImplWithFunctionType element) =>
      _wrapExceptions(_fixBuilder.unit, () => element.typeInternal, () {
        var type = _fixBuilder._computeMigratedType(element);
        Element baseElement = element;
        if (baseElement is Member) {
          type = baseElement.substitution.substituteType(type);
        }
        return type as FunctionType;
      });

  @override
  DartType getExtendedType(ExtensionElementImpl element) {
    return _wrapExceptions(
        _fixBuilder.unit,
        () => element.extendedTypeInternal,
        () => _fixBuilder._variables
            .toFinalType(_fixBuilder._variables.decoratedElementType(element)));
  }

  @override
  DartType getFieldType(PropertyInducingElementImpl element) =>
      _wrapExceptions(_fixBuilder.unit, () => element.typeInternal, () {
        assert(!element.isSynthetic);
        return _fixBuilder._computeMigratedType(element);
      });

  @override
  List<CollectionElement> getListElements(ListLiteral node) => _wrapExceptions(
      node,
      () => node.elements,
      () => _collectionElements[node] ??=
          _transformCollectionElements(node.elements, node.typeArguments));

  @override
  List<CollectionElement> getSetOrMapElements(SetOrMapLiteral node) =>
      _wrapExceptions(
          node,
          () => node.elements,
          () => _collectionElements[node] ??=
              _transformCollectionElements(node.elements, node.typeArguments));

  @override
  DartType getTypeParameterBound(TypeParameterElementImpl element) {
    var decoratedBound = _fixBuilder._variables
        .decoratedTypeParameterBound(element, allowNullUnparentedBounds: true);
    if (decoratedBound == null) return element.boundInternal;
    var bound = _fixBuilder._variables.toFinalType(decoratedBound);
    if (bound.isDynamic) {
      return null;
    } else if (bound.isDartCoreObject &&
        bound.nullabilitySuffix == NullabilitySuffix.question) {
      return null;
    } else {
      return bound;
    }
  }

  @override
  DartType getVariableType(VariableElementImpl variable) =>
      _wrapExceptions(_fixBuilder.unit, () => variable.typeInternal, () {
        if (variable.library == null) {
          // This is a synthetic variable created during resolution (e.g. a
          // parameter of a function type), so the type it currently has is the
          // correct post-migration type.
          return variable.typeInternal;
        }
        if (variable is ParameterElement) {
          var enclosingElement = variable.enclosingElement;
          if (enclosingElement is PropertyAccessorElement &&
              enclosingElement.isSynthetic) {
            // This is the parameter of a synthetic getter, so it has the same
            // type as the corresponding variable.
            return _fixBuilder._computeMigratedType(enclosingElement.variable);
          }
        }
        return _fixBuilder._computeMigratedType(variable);
      });

  @override
  bool isIndexExpressionNullAware(IndexExpression node) {
    // Null-aware index expressions weren't supported prior to NNBD.
    assert(!node.isNullAware);
    return false;
  }

  @override
  bool isLibraryNonNullableByDefault(LibraryElementImpl element) {
    return _fixBuilder._graph.isBeingMigrated(element.source) ||
        element.isNonNullableByDefaultInternal;
  }

  @override
  bool isMethodInvocationNullAware(MethodInvocation node) {
    return node.isNullAware &&
        (_shouldStayNullAware[node] ??= _fixBuilder._shouldStayNullAware(node));
  }

  @override
  bool isPropertyAccessNullAware(PropertyAccess node) {
    return node.isNullAware &&
        (_shouldStayNullAware[node] ??= _fixBuilder._shouldStayNullAware(node));
  }

  @override
  DartType modifyExpressionType(Expression node, DartType type) =>
      _wrapExceptions(node, () => type, () {
        var parent = node.parent;
        if (parent is AssignmentExpression) {
          if (parent.leftHandSide == node) {
            return type;
          }
          return _assignmentLikeExpressionHandlers[parent]
              .modifyAssignmentRhs(this, node, type);
        } else if (parent is PrefixExpression) {
          if (_isIncrementOrDecrementOperator(parent.operator.type)) {
            return type;
          }
        } else if (parent is PostfixExpression) {
          if (_isIncrementOrDecrementOperator(parent.operator.type)) {
            return type;
          }
        }
        return _modifyRValueType(node, type);
      });

  @override
  DartType modifyInferredParameterType(
      ParameterElement parameter, DartType type) {
    var postMigrationType = parameter.type;
    if (postMigrationType != type) {
      // TODO(paulberry): test field formal parameters.
      _fixBuilder._addedParameterTypes[parameter] = postMigrationType;
      return postMigrationType;
    }
    return type;
  }

  @override
  void setCompoundAssignmentExpressionTypes(CompoundAssignmentExpression node) {
    assert(_assignmentLikeExpressionHandlers[node] == null);
    if (node is AssignmentExpression) {
      var handler = _AssignmentExpressionHandler(node);
      _assignmentLikeExpressionHandlers[node] = handler;
      handler.handleLValueType(this, node.readType, node.writeType);
    } else if (node is PrefixExpression) {
      assert(_isIncrementOrDecrementOperator(node.operator.type));
      var handler = _PrefixExpressionHandler(node);
      _assignmentLikeExpressionHandlers[node] = handler;
      handler.handleLValueType(this, node.readType, node.writeType);
      handler.handleAssignmentRhs(this, _fixBuilder.typeProvider.intType);
    } else if (node is PostfixExpression) {
      assert(_isIncrementOrDecrementOperator(node.operator.type));
      var handler = _PostfixExpressionHandler(node);
      _assignmentLikeExpressionHandlers[node] = handler;
      handler.handleLValueType(this, node.readType, node.writeType);
      handler.handleAssignmentRhs(this, _fixBuilder.typeProvider.intType);
    } else {
      throw StateError('(${node.runtimeType}) $node');
    }
  }

  @override
  void setFlowAnalysis(
      FlowAnalysis<AstNode, Statement, Expression, PromotableElement, DartType>
          flowAnalysis) {
    _flowAnalysis = flowAnalysis;
  }

  DartType _addCast(
      Expression node, DartType expressionType, DartType contextType) {
    var isDowncast =
        _fixBuilder._typeSystem.isSubtypeOf(contextType, expressionType);
    var checks =
        _fixBuilder._variables.expressionChecks(_fixBuilder.source, node);
    var info = AtomicEditInfo(
        isDowncast
            ? NullabilityFixDescription.downcastExpression
            : NullabilityFixDescription.otherCastExpression,
        checks != null ? checks.edges : {});
    (_fixBuilder._getChange(node) as NodeChangeForExpression)
        .introduceAs(contextType, info);
    _flowAnalysis.asExpression_end(node, contextType);
    return contextType;
  }

  DartType _addNullCheck(Expression node, DartType type,
      {AtomicEditInfo info, HintComment hint}) {
    var checks =
        _fixBuilder._variables.expressionChecks(_fixBuilder.source, node);
    bool noValidMigration = node is NullLiteral && hint == null;
    info ??= checks != null
        ? AtomicEditInfo(
            noValidMigration
                ? NullabilityFixDescription.noValidMigrationForNull
                : NullabilityFixDescription.checkExpression,
            checks.edges)
        : null;
    var nodeChangeForExpression =
        _fixBuilder._getChange(node) as NodeChangeForExpression;
    if (noValidMigration) {
      nodeChangeForExpression.addNoValidMigration(info);
    } else {
      nodeChangeForExpression.addNullCheck(info, hint: hint);
    }
    _flowAnalysis.nonNullAssert_end(node);
    return _fixBuilder._typeSystem.promoteToNonNull(type as TypeImpl);
  }

  Expression _findNullabilityContextAncestor(Expression node) {
    while (true) {
      var parent = node.parent;
      if (parent is BinaryExpression &&
          parent.operator.type == TokenType.QUESTION_QUESTION &&
          identical(node, parent.rightOperand)) {
        node = parent;
        continue;
      }
      return node;
    }
  }

  InterfaceType _getClassInterface(
      ClassElement class_, ClassElement superclass) {
    var decoratedSupertype = _fixBuilder._decoratedClassHierarchy
        .getDecoratedSupertype(class_, superclass);
    var finalType = _fixBuilder._variables.toFinalType(decoratedSupertype);
    return finalType as InterfaceType;
  }

  DartType _modifyRValueType(Expression node, DartType type,
      {DartType context}) {
    if (node is MethodInvocation) {
      var deferredProcessing = _deferredMethodInvocationProcessing.remove(node);
      if (deferredProcessing != null) {
        type = deferredProcessing(type);
      }
    }
    var hint =
        _fixBuilder._variables.getNullCheckHint(_fixBuilder.source, node);
    if (hint != null) {
      type = _addNullCheck(node, type,
          info: AtomicEditInfo(
              NullabilityFixDescription.checkExpressionDueToHint,
              {
                FixReasonTarget.root:
                    FixReason_NullCheckHint(CodeReference.fromAstNode(node))
              },
              hintComment: hint),
          hint: hint);
    }
    if (type.isDynamic) return type;
    var ancestor = _findNullabilityContextAncestor(node);
    context ??=
        InferenceContext.getContext(ancestor) ?? DynamicTypeImpl.instance;
    if (!_fixBuilder._typeSystem.isSubtypeOf(type, context)) {
      var transformationInfo =
          _fixBuilder._whereOrNullTransformer.tryTransformOrElseArgument(node);
      if (transformationInfo != null) {
        // We can fix this by dropping the node and changing the method call.
        _fixBuilder.needsIterableExtension = true;
        _fixBuilder._neededPackages['collection'] =
            Version.parse('1.15.0-nullsafety.4');
        var info = AtomicEditInfo(
            NullabilityFixDescription.changeMethodName(
                transformationInfo.originalName,
                transformationInfo.replacementName),
            {});
        (_fixBuilder._getChange(transformationInfo.methodInvocation.methodName)
                as NodeChangeForMethodName)
            .replaceWith(transformationInfo.replacementName, info);
        (_fixBuilder._getChange(
                    transformationInfo.methodInvocation.argumentList)
                as NodeChangeForArgumentList)
            .dropArgument(transformationInfo.orElseArgument, info);
        _deferredMethodInvocationProcessing[
                transformationInfo.methodInvocation] =
            (methodInvocationType) => _fixBuilder._typeSystem
                .makeNullable(methodInvocationType as TypeImpl);
        return type;
      }
      // Either a cast or a null check is needed.  We prefer to do a null
      // check if we can.
      var nonNullType = _fixBuilder._typeSystem.promoteToNonNull(type);
      if (_fixBuilder._typeSystem.isSubtypeOf(nonNullType, context)) {
        return _addNullCheck(node, type);
      } else {
        return _addCast(node, type, context);
      }
    }
    if (!_fixBuilder._typeSystem.isNullable(type)) return type;
    if (_needsNullCheckDueToStructure(ancestor)) {
      return _addNullCheck(node, type);
    }
    return type;
  }

  bool _needsNullCheckDueToStructure(Expression node) {
    var parent = node.parent;

    if (parent is BinaryExpression) {
      if (identical(node, parent.leftOperand)) {
        var operatorType = parent.operator.type;
        if (operatorType == TokenType.QUESTION_QUESTION ||
            operatorType == TokenType.EQ_EQ ||
            operatorType == TokenType.BANG_EQ) {
          return false;
        } else {
          return true;
        }
      }
    } else if (parent is PrefixedIdentifier) {
      if (isDeclaredOnObject(parent.identifier.name)) {
        return false;
      }
      return identical(node, parent.prefix);
    } else if (parent is PropertyAccess) {
      if (isDeclaredOnObject(parent.propertyName.name)) {
        return false;
      }
      // TODO(paulberry): what about cascaded?
      return parent.operator.type == TokenType.PERIOD &&
          identical(node, parent.target);
    } else if (parent is MethodInvocation) {
      if (isDeclaredOnObject(parent.methodName.name)) {
        return false;
      }
      // TODO(paulberry): what about cascaded?
      return parent.operator.type == TokenType.PERIOD &&
          identical(node, parent.target);
    } else if (parent is IndexExpression) {
      return identical(node, parent.target);
    } else if (parent is ConditionalExpression) {
      return identical(node, parent.condition);
    } else if (parent is FunctionExpressionInvocation) {
      return identical(node, parent.function);
    } else if (parent is PrefixExpression) {
      // TODO(paulberry): for prefix increment/decrement, inserting a null check
      // isn't sufficient.
      return true;
    } else if (parent is ThrowExpression) {
      return true;
    }
    return false;
  }

  CollectionElement _transformCollectionElement(CollectionElement node) {
    while (node is IfElement) {
      var conditionalDiscard = _fixBuilder._variables
          .getConditionalDiscard(_fixBuilder.source, node);
      if (conditionalDiscard == null ||
          conditionalDiscard.keepTrue && conditionalDiscard.keepFalse) {
        return node;
      }
      var conditionValue = conditionalDiscard.keepTrue;
      var ifElement = node as IfElement;
      node = conditionValue ? ifElement.thenElement : ifElement.elseElement;
    }
    return node;
  }

  List<CollectionElement> _transformCollectionElements(
      NodeList<CollectionElement> elements, TypeArgumentList typeArguments) {
    return elements
        .map(_transformCollectionElement)
        .where((e) => e != null)
        .toList();
  }

  /// Runs the computation in [compute].  If an exception occurs and
  /// [_fixBuilder.listener] is non-null, the exception is reported to the
  /// listener and [fallback] is called to produce a result.  Otherwise the
  /// exception is propagated normally.
  T _wrapExceptions<T>(
      AstNode node, T Function() fallback, T Function() compute) {
    if (_fixBuilder.listener == null) return compute();
    try {
      return compute();
    } catch (exception, stackTrace) {
      _fixBuilder.listener
          .reportException(_fixBuilder.source, node, exception, stackTrace);
      return fallback();
    }
  }
}

/// Problem reported by [FixBuilder] when encountering a non-nullable unnamed
/// optional parameter that lacks a default value.
class NonNullableUnnamedOptionalParameter implements Problem {
  const NonNullableUnnamedOptionalParameter();
}

/// Common supertype for problems reported by [FixBuilder._addProblem].
abstract class Problem {}

/// Specialization of [_AssignmentLikeExpressionHandler] for
/// [AssignmentExpression].
class _AssignmentExpressionHandler extends _AssignmentLikeExpressionHandler {
  @override
  final AssignmentExpression node;

  _AssignmentExpressionHandler(this.node);

  @override
  MethodElement get combiner => node.staticElement;

  @override
  TokenType get combinerType => node.operator.type;

  @override
  Expression get target => node.leftHandSide;
}

/// Data structure keeping track of intermediate results when the fix builder
/// is handling an assignment expression, or an expression that desugars to an
/// assignment.
abstract class _AssignmentLikeExpressionHandler {
  /// For compound and null-aware assignments, the type read from the LHS.
  /*late final*/ DartType readType;

  /// The type that may be written to the LHS.
  /*late final*/ DartType writeType;

  /// The type that should be used as a context type when inferring the RHS.
  DartType rhsContextType;

  /// Gets the static element representing the combiner.
  MethodElement get combiner;

  /// Gets the operator type representing the combiner.
  TokenType get combinerType;

  /// Gets the expression in question.
  Expression get node;

  /// Gets the target of the assignment.
  Expression get target;

  /// Called after visiting the RHS of the assignment, to verify that for
  /// compound assignments, the return value of the assignment is assignable to
  /// [writeType].
  void handleAssignmentRhs(
      MigrationResolutionHooksImpl hooks, DartType rhsType) {
    MethodElement combiner = this.combiner;
    if (combiner != null) {
      var fixBuilder = hooks._fixBuilder;
      var combinerReturnType =
          fixBuilder._typeSystem.refineBinaryExpressionType(
        readType,
        combinerType,
        rhsType,
        combiner.returnType,
        combiner,
      );
      if (!fixBuilder._typeSystem.isSubtypeOf(combinerReturnType, writeType)) {
        (fixBuilder._getChange(node) as NodeChangeForAssignmentLike)
            .hasBadCombinedType = true;
      }
    }
  }

  /// Called after visiting the LHS of the assignment.  Records the [readType],
  /// [writeType], and [rhsContextType].  Also verifies that for compound
  /// assignments, the [readType] is non-nullable, and that for null-aware
  /// assignments, the [readType] is nullable.
  void handleLValueType(MigrationResolutionHooksImpl hooks,
      DartType readTypeToSet, DartType writeTypeToSet) {
    assert(writeTypeToSet.nullabilitySuffix != NullabilitySuffix.star);
    writeType = writeTypeToSet;
    // TODO(scheglov) Remove this after the analyzer breaking change that
    // will top setting types for LHS.
    target.staticType = writeTypeToSet;
    var fixBuilder = hooks._fixBuilder;
    if (combinerType == TokenType.EQ) {
      rhsContextType = writeTypeToSet;
    } else {
      readType = readTypeToSet;
      assert(readType.nullabilitySuffix != NullabilitySuffix.star);
      if (combinerType == TokenType.QUESTION_QUESTION_EQ) {
        rhsContextType = writeTypeToSet;
        if (fixBuilder._typeSystem.isNonNullable(readType)) {
          (fixBuilder._getChange(node) as NodeChangeForAssignment)
              .isWeakNullAware = true;
        }
      } else {
        if (!readType.isDynamic &&
            fixBuilder._typeSystem.isPotentiallyNullable(readType)) {
          (fixBuilder._getChange(node) as NodeChangeForAssignmentLike)
              .hasNullableSource = true;
        }
      }
    }
  }

  /// Called after visiting the RHS of the assignment.
  DartType modifyAssignmentRhs(MigrationResolutionHooksImpl hooks,
      Expression subexpression, DartType type) {
    type =
        hooks._modifyRValueType(subexpression, type, context: rhsContextType);
    handleAssignmentRhs(hooks, type);
    return type;
  }
}

/// Visitor that computes additional migrations on behalf of [FixBuilder] that
/// should be run after resolution
class _FixBuilderPostVisitor extends GeneralizingAstVisitor<void>
    with PermissiveModeVisitor<void> {
  final FixBuilder _fixBuilder;

  _FixBuilderPostVisitor(this._fixBuilder);

  @override
  NullabilityMigrationListener get listener => _fixBuilder.listener;

  @override
  Source get source => _fixBuilder.source;

  @override
  void visitAsExpression(AsExpression node) {
    if (!_fixBuilder._variables.wasUnnecessaryCast(_fixBuilder.source, node) &&
        BestPracticesVerifier.isUnnecessaryCast(
            node, _fixBuilder._typeSystem)) {
      (_fixBuilder._getChange(node) as NodeChangeForAsExpression).removeAs =
          true;
    }
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if ((node as CompilationUnitImpl).languageVersionToken != null) {
      (_fixBuilder._getChange(node) as NodeChangeForCompilationUnit)
          .removeLanguageVersionComment = true;
    }
    if (_fixBuilder.needsIterableExtension) {
      var packageCollectionImport =
          _findImportDirective(node, 'package:collection/collection.dart');
      if (packageCollectionImport != null) {
        for (var combinator in packageCollectionImport.combinators) {
          if (combinator is ShowCombinator) {
            _ensureShows(combinator, 'IterableExtension');
          }
        }
      } else {
        (_fixBuilder._getChange(node) as NodeChangeForCompilationUnit)
            .addImport(
                'package:collection/collection.dart', 'IterableExtension');
      }
    }
    super.visitCompilationUnit(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.type == null) {
      var typeToAdd = _fixBuilder._addedParameterTypes[node.declaredElement];
      if (typeToAdd != null) {
        (_fixBuilder._getChange(node) as NodeChangeForSimpleFormalParameter)
            .addExplicitType = typeToAdd;
      }
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.type == null) {
      // TODO(paulberry): for fields, handle inference via override as well.
      List<DartType> neededTypes = [];
      List<DartType> inferredTypes = [];
      bool explicitTypeNeeded = false;
      for (var variableDeclaration in node.variables) {
        var neededType = _fixBuilder
            ._computeMigratedType(variableDeclaration.declaredElement);
        neededTypes.add(neededType);
        var inferredType = variableDeclaration.initializer?.staticType ??
            _fixBuilder.typeProvider.dynamicType;
        inferredTypes.add(inferredType);
        if (neededType != inferredType) {
          explicitTypeNeeded = true;
        }
      }
      if (explicitTypeNeeded) {
        var firstNeededType = neededTypes[0];
        if (neededTypes.any((t) => t != firstNeededType)) {
          throw UnimplementedError(
              'Different explicit types needed in multi-variable declaration');
        } else {
          (_fixBuilder._getChange(node) as NodeChangeForVariableDeclarationList)
              .addExplicitType = firstNeededType;
        }
      }
    }

    // Check if the nullability node for a single variable declaration has been
    // declared to be late.
    if (node.variables.length == 1) {
      var variableElement = node.variables.single.declaredElement;
      var lateCondition = _fixBuilder._variables
          .decoratedElementType(variableElement)
          .node
          .lateCondition;
      switch (lateCondition) {
        case LateCondition.possiblyLate:
          (_fixBuilder._getChange(node) as NodeChangeForVariableDeclarationList)
              .lateAdditionReason = LateAdditionReason.inference;
          break;
        case LateCondition.possiblyLateDueToTestSetup:
          (_fixBuilder._getChange(node) as NodeChangeForVariableDeclarationList)
              .lateAdditionReason = LateAdditionReason.testVariableInference;
          break;
        case LateCondition.lateDueToHint:
        // Handled below.
        case LateCondition.notLate:
        // Nothing to do.
      }
    }

    var lateHint = _fixBuilder._variables.getLateHint(source, node);
    if (lateHint != null) {
      (_fixBuilder._getChange(node) as NodeChangeForVariableDeclarationList)
          .lateHint = lateHint;
    }
    super.visitVariableDeclarationList(node);
  }

  /// Creates the necessary changes to ensure that [combinator] shows [name].
  void _ensureShows(ShowCombinator combinator, String name) {
    if (combinator.shownNames.any((shownName) => shownName.name == name)) {
      return;
    }
    (_fixBuilder._getChange(combinator) as NodeChangeForShowCombinator)
        .addName(name);
  }

  /// Searches [unit] for an unprefixed import directive whose URI matches
  /// [uri], returning it if found, or `null` if not found.
  ImportDirective _findImportDirective(CompilationUnit unit, String uri) {
    for (var directive in unit.directives) {
      if (directive is ImportDirective &&
          directive.prefix == null &&
          directive.uriContent == uri) {
        return directive;
      }
    }
    return null;
  }
}

/// Visitor that computes additional migrations on behalf of [FixBuilder] that
/// don't need to be integrated into the resolver itself, and should be run
/// prior to resolution
class _FixBuilderPreVisitor extends GeneralizingAstVisitor<void>
    with PermissiveModeVisitor<void> {
  final FixBuilder _fixBuilder;

  _FixBuilderPreVisitor(this._fixBuilder);

  @override
  NullabilityMigrationListener get listener => _fixBuilder.listener;

  @override
  Source get source => _fixBuilder.source;

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    var element = node.declaredElement;
    if (node.defaultValue == null) {
      var nullabilityNode =
          _fixBuilder._variables.decoratedElementType(element).node;
      if (!nullabilityNode.isNullable) {
        if (element.isNamed) {
          _addRequiredKeyword(node, nullabilityNode);
        } else {
          _fixBuilder._addProblem(
              node, const NonNullableUnnamedOptionalParameter());
        }
      } else if (element.metadata.any((m) => m.isRequired)) {
        _addRequiredKeyword(node, nullabilityNode);
      }
    }
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.type == null) {
      // Potentially add an explicit type to a field formal parameter.
      var decl = node.declaredElement as FieldFormalParameterElement;
      var decoratedType = _fixBuilder._variables.decoratedElementType(decl);
      var decoratedFieldType =
          _fixBuilder._variables.decoratedElementType(decl.field);
      var typeToAdd = _fixBuilder._variables.toFinalType(decoratedType);
      var fieldFinalType =
          _fixBuilder._variables.toFinalType(decoratedFieldType);
      if (typeToAdd is InterfaceType &&
          !_fixBuilder._typeSystem.isSubtypeOf(fieldFinalType, typeToAdd)) {
        (_fixBuilder._getChange(node) as NodeChangeForFieldFormalParameter)
            .addExplicitType = typeToAdd;
      }
    } else if (node.parameters != null) {
      // Handle function-typed field formal parameters.
      var decoratedType =
          _fixBuilder._variables.decoratedElementType(node.declaredElement);
      if (decoratedType.node.isNullable) {
        (_fixBuilder._getChange(node) as NodeChangeForFieldFormalParameter)
            .recordNullability(decoratedType, decoratedType.node.isNullable,
                nullabilityHint:
                    _fixBuilder._variables.getNullabilityHint(source, node));
      }
    }
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var decoratedType =
        _fixBuilder._variables.decoratedElementType(node.declaredElement);
    if (decoratedType.node.isNullable) {
      (_fixBuilder._getChange(node)
              as NodeChangeForFunctionTypedFormalParameter)
          .recordNullability(decoratedType, decoratedType.node.isNullable,
              nullabilityHint:
                  _fixBuilder._variables.getNullabilityHint(source, node));
    }
    super.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var decoratedType = _fixBuilder._variables
        .decoratedTypeAnnotation(_fixBuilder.source, node);
    if (!typeIsNonNullableByContext(node)) {
      _makeTypeNameNullable(node, decoratedType);
    }
    (node as GenericFunctionTypeImpl).type =
        _fixBuilder._variables.toFinalType(decoratedType);
    super.visitGenericFunctionType(node);
  }

  @override
  void visitTypeName(TypeName node) {
    var decoratedType = _fixBuilder._variables
        .decoratedTypeAnnotation(_fixBuilder.source, node);
    if (!typeIsNonNullableByContext(node)) {
      if (!_typeIsNaturallyNullable(decoratedType.type)) {
        _makeTypeNameNullable(node, decoratedType);
      }
    }
    node.type = _fixBuilder._variables.toFinalType(decoratedType);
    super.visitTypeName(node);
  }

  void _addRequiredKeyword(
      DefaultFormalParameter parameter, NullabilityNode node) {
    // Change an existing `@required` annotation into a `required` keyword if
    // possible.
    final element = parameter.declaredElement;
    final method = element.enclosingElement;
    final cls = method.enclosingElement;
    var info = AtomicEditInfo(
        NullabilityFixDescription.addRequired(
            cls.name, method.name, element.name),
        {FixReasonTarget.root: node});
    var metadata = parameter.metadata;
    if (metadata != null && metadata.isNotEmpty) {
      // Only the last annotation can be changed into a `required` keyword;
      // changing an earlier annotation into a keyword would be illegal.
      var lastAnnotation = metadata.last;
      if (lastAnnotation.elementAnnotation.isRequired) {
        (_fixBuilder._getChange(lastAnnotation) as NodeChangeForAnnotation)
          ..changeToRequiredKeyword = true
          ..changeToRequiredKeywordInfo = info;
        return;
      }
    }
    // Otherwise create a new `required` keyword.
    var nodeChange = (_fixBuilder._getChange(parameter)
        as NodeChangeForDefaultFormalParameter)
      ..addRequiredKeyword = true
      ..addRequiredKeywordInfo = info;
    var requiredAnnotation = metadata?.firstWhere(
        (annotation) => annotation.elementAnnotation.isRequired,
        orElse: () => null);
    if (requiredAnnotation != null) {
      // If the parameter was annotated with `@required`, but it was not the
      // last annotation, we remove the annotation in addition to adding the
      // `required` keyword.
      nodeChange
        ..annotationToRemove = requiredAnnotation
        ..removeAnnotationInfo = info;
    }
  }

  void _makeTypeNameNullable(TypeAnnotation node, DecoratedType decoratedType) {
    bool makeNullable = decoratedType.node.isNullable;
    if (decoratedType.type.isDartAsyncFutureOr) {
      var typeArguments = decoratedType.typeArguments;
      if (typeArguments.length == 1) {
        var typeArgument = typeArguments[0];
        if ((_typeIsNaturallyNullable(typeArgument.type) ||
            typeArgument.node.isNullable)) {
          // FutureOr<T?>? is equivalent to FutureOr<T?>, so there is no need to
          // make this type nullable.
          makeNullable = false;
        }
      }
    }
    (_fixBuilder._getChange(node) as NodeChangeForTypeAnnotation)
        .recordNullability(
            decoratedType, makeNullable,
            nullabilityHint:
                _fixBuilder._variables.getNullabilityHint(source, node));
  }

  bool _typeIsNaturallyNullable(DartType type) =>
      type.isDynamic || type.isVoid || type.isDartCoreNull;
}

/// Specialization of [_AssignmentLikeExpressionHandler] for
/// [PostfixExpression].
class _PostfixExpressionHandler extends _AssignmentLikeExpressionHandler {
  @override
  final PostfixExpression node;

  _PostfixExpressionHandler(this.node)
      : assert(_isIncrementOrDecrementOperator(node.operator.type));

  @override
  MethodElement get combiner => node.staticElement;

  @override
  TokenType get combinerType => node.operator.type;

  @override
  Expression get target => node.operand;
}

/// Specialization of [_AssignmentLikeExpressionHandler] for
/// [PrefixExpression].
class _PrefixExpressionHandler extends _AssignmentLikeExpressionHandler {
  @override
  final PrefixExpression node;

  _PrefixExpressionHandler(this.node)
      : assert(_isIncrementOrDecrementOperator(node.operator.type));

  @override
  MethodElement get combiner => node.staticElement;

  @override
  TokenType get combinerType => node.operator.type;

  @override
  Expression get target => node.operand;
}
