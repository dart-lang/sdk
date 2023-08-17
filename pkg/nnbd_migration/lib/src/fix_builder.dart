// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
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
import 'package:collection/collection.dart' show IterableExtension;
import 'package:meta/meta.dart';
import 'package:nnbd_migration/fix_reason_target.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/fix_aggregator.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/utilities/built_value_transformer.dart';
import 'package:nnbd_migration/src/utilities/permissive_mode.dart';
import 'package:nnbd_migration/src/utilities/resolution_utils.dart';
import 'package:nnbd_migration/src/utilities/where_not_null_transformer.dart';
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
  final DecoratedClassHierarchy? _decoratedClassHierarchy;

  /// The type provider providing non-nullable types.
  final TypeProvider typeProvider;

  final Map<AstNode, NodeChange> changes = {};

  final Map<AstNode, Set<Problem>> problems = {};

  /// The NNBD type system.
  final TypeSystemImpl _typeSystem;

  /// Variables for this migration run.
  final Variables? _variables;

  /// The file being analyzed.
  final Source? source;

  late ResolverVisitor _resolver;

  /// The listener to which exceptions should be reported.
  final NullabilityMigrationListener? listener;

  /// The compilation unit for which fixes are being built.
  final CompilationUnit? unit;

  final MigrationResolutionHooksImpl migrationResolutionHooks;

  /// Parameter elements for which an explicit type should be added, and what
  /// that type should be.
  final Map<ParameterElement, DartType> _addedParameterTypes = {};

  final bool? warnOnWeakCode;

  final NullabilityGraph _graph;

  /// Helper that assists us in transforming Iterable methods to their "OrNull"
  /// equivalents.
  final WhereOrNullTransformer _whereOrNullTransformer;

  /// Helper that assists us in transforming calls to `Iterable.where` to
  /// `Iterable.whereNotNull`.
  final WhereNotNullTransformer _whereNotNullTransformer;

  /// The set of extensions that need to be imported from package:collection.
  @visibleForTesting
  final Set<String> neededCollectionPackageExtensions = {};

  /// Map of additional package dependencies that will be required by the
  /// migrated code.  Keys are package names; values indicate the minimum
  /// required version of each package.
  final Map<String, Version> _neededPackages;

  factory FixBuilder(
      Source? source,
      DecoratedClassHierarchy? decoratedClassHierarchy,
      TypeProvider typeProvider,
      TypeSystemImpl typeSystem,
      Variables? variables,
      LibraryElementImpl definingLibrary,
      NullabilityMigrationListener? listener,
      CompilationUnit? unit,
      bool? warnOnWeakCode,
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
      LibraryElementImpl definingLibrary,
      this.listener,
      this.unit,
      this.migrationResolutionHooks,
      this.warnOnWeakCode,
      this._graph,
      this._neededPackages)
      : typeProvider = _typeSystem.typeProvider,
        _whereOrNullTransformer =
            WhereOrNullTransformer(_typeSystem.typeProvider, _typeSystem),
        _whereNotNullTransformer =
            WhereNotNullTransformer(_typeSystem.typeProvider, _typeSystem) {
    migrationResolutionHooks._fixBuilder = this;
    assert(_typeSystem.isNonNullableByDefault);
    assert((typeProvider as TypeProviderImpl).isNonNullableByDefault);
    var inheritanceManager = InheritanceManager3();
    // TODO(paulberry): is it a bad idea to throw away errors?
    var errorListener = AnalysisErrorListener.NULL_LISTENER;
    _resolver = ResolverVisitorForMigration(
        inheritanceManager,
        definingLibrary,
        source!,
        typeProvider,
        errorListener,
        _typeSystem,
        FeatureSet.fromEnableFlags2(
          sdkLanguageVersion: Feature.non_nullable.releaseVersion!,
          flags: [],
        ),
        migrationResolutionHooks);
  }

  /// Visits the entire compilation [unit] using the analyzer's resolver and
  /// makes note of changes that need to be made.
  void visitAll() {
    try {
      ElementTypeProvider.current = migrationResolutionHooks;
      unit!.accept(_FixBuilderPreVisitor(this));
      unit!.accept(_resolver);
      unit!.accept(_FixBuilderPostVisitor(this));
    } catch (exception, stackTrace) {
      if (listener != null) {
        listener!.reportException(source, unit, exception, stackTrace);
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
    element = element.declaration!;
    if (element is ClassElement || element is TypeParameterElement) {
      return typeProvider.typeType;
    } else if (element is PropertyAccessorElement &&
        element.isSynthetic &&
        !element.variable.isSynthetic) {
      var variableType = _variables!
          .toFinalType(_variables!.decoratedElementType(element.variable));
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
      return _variables!.toFinalType(_variables!.decoratedElementType(element));
    }
  }

  /// If [node] is a property access or method invocation, returns the element
  /// it invokes.  Otherwise returns `null`.
  Element? _findPropertyOrMethodElement(Expression node) {
    if (node is PrefixedIdentifier) {
      return node.identifier.staticElement;
    } else if (node is PropertyAccess) {
      return node.propertyName.staticElement;
    } else if (node is MethodInvocation) {
      return node.methodName.staticElement;
    } else {
      return null;
    }
  }

  /// Returns the [NodeChange] object accumulating changes for the given [node],
  /// creating it if necessary.
  NodeChange _getChange(AstNode node) =>
      changes[node] ??= NodeChange.create(node)!;

  /// Determines whether the given [node], which is a null-aware method
  /// invocation, property access, or index expression, should remain null-aware
  /// after migration.
  bool _shouldStayNullAware(Expression node) {
    Expression? target;
    if (node is PropertyAccess) {
      target = node.target;
    } else if (node is MethodInvocation) {
      target = node.target;
    } else {
      throw StateError('Unexpected expression type: ${node.runtimeType}');
    }
    if (!_typeSystem.isPotentiallyNullable(target!.staticType!)) {
      var element = _findPropertyOrMethodElement(target);
      if (element != null) {
        var library = element.library;
        if (library!.isNonNullableByDefault &&
            !_graph.isBeingMigrated(library.source)) {
          (_getChange(node) as NodeChangeForNullAware).nullAwarenessRemoval =
              NullAwarenessRemovalType.strong;
          return false;
        }
      }
      (_getChange(node) as NodeChangeForNullAware).nullAwarenessRemoval =
          NullAwarenessRemovalType.weak;
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
        isNonNullableByDefault: true,
        strictCasts: typeSystem.strictCasts,
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
  late final FixBuilder _fixBuilder;

  final Expando<List<CollectionElement>> _collectionElements = Expando();

  final Expando<bool> _shouldStayNullAware = Expando();

  final Map<Expression, _AssignmentLikeExpressionHandler>
      _assignmentLikeExpressionHandlers = {};

  FlowAnalysis<AstNode, Statement, Expression, PromotableElement, DartType>?
      _flowAnalysis;

  /// Deferred processing that should be performed once we have finished
  /// evaluating the type of an expression.
  final Map<Expression, DartType Function(DartType)>
      _deferredExpressionProcessing = {};

  final Map<Expression, DartType?> _contextTypes = {};

  TypeProvider get typeProvider => _fixBuilder.typeProvider;

  @override
  void freshTypeParameterCreated(TypeParameterElement newTypeParameter,
      TypeParameterElement oldTypeParameter) {
    DecoratedTypeParameterBounds.current!.put(newTypeParameter,
        DecoratedTypeParameterBounds.current!.get(oldTypeParameter));
  }

  @override
  List<InterfaceType> getClassInterfaces(InterfaceElementImpl element) {
    return _wrapExceptions(
        _fixBuilder.unit,
        () => element.interfacesInternal,
        () => [
              for (var interface in element.interfacesInternal)
                _getClassInterface(element, interface.element)
            ]);
  }

  @override
  bool? getConditionalKnownValue(AstNode node) =>
      _wrapExceptions(node, () => null, () {
        // TODO(paulberry): handle conditional expressions.
        var conditionalDiscard = _fixBuilder._variables!
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
          return _fixBuilder.warnOnWeakCode! ? null : conditionValue;
        }
      });

  @override
  List<ParameterElement> getExecutableParameters(
      ExecutableElementImpl element) {
    // Note: even if the element is part of a library that's being migrated,
    // there's no guarantee that the parameter elements have been appropriately
    // updated by the migration process, because they might be synthetic
    // parameters.  (This happens when the code being migrated contains a mixin
    // application and there's a synthetic constructor).  So we can't safely get
    // the parameters out of the element.  But it is always safe to defer to
    // `getExecutableType` and get the parameter list from the function type.
    return getExecutableType(element).parameters;
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
        () => _fixBuilder._variables!.toFinalType(
            _fixBuilder._variables!.decoratedElementType(element)));
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
          _transformCollectionElements(node.elements));

  @override
  List<CollectionElement> getSetOrMapElements(SetOrMapLiteral node) =>
      _wrapExceptions(
          node,
          () => node.elements,
          () => _collectionElements[node] ??=
              _transformCollectionElements(node.elements));

  @override
  DartType? getTypeParameterBound(TypeParameterElementImpl element) {
    var decoratedBound = _fixBuilder._variables!
        .decoratedTypeParameterBound(element, allowNullUnparentedBounds: true);
    if (decoratedBound == null) return element.boundInternal;
    var bound = _fixBuilder._variables!.toFinalType(decoratedBound);
    if (bound is DynamicType) {
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

  /// Indicates whether the given [element] is a member of an extension on a
  /// potentially nullable type (and hence the extension member can be invoked
  /// on a nullable type without introducing a null check).
  bool isNullableExtensionMember(Element? element) {
    if (element != null) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement is ExtensionElement) {
        return _fixBuilder._typeSystem
            .isPotentiallyNullable(enclosingElement.extendedType);
      }
    }
    return false;
  }

  @override
  bool isPropertyAccessNullAware(PropertyAccess node) {
    return node.isNullAware &&
        (_shouldStayNullAware[node] ??= _fixBuilder._shouldStayNullAware(node));
  }

  @override
  DartType modifyExpressionType(
          Expression node, DartType type, DartType? contextType) =>
      _wrapExceptions(node, () => type, () {
        _contextTypes[node] = contextType;
        if (node is NamedExpression) {
          // Do not attempt to modify named expressions.  We should already have
          // been called for [node.expression], and we should have made the
          // necessary modifications then.
          return type;
        }
        var parent = node.parent;
        if (parent is AssignmentExpression) {
          if (parent.leftHandSide == node) {
            return type;
          }
          return _assignmentLikeExpressionHandlers[parent]!
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
  void reportBinaryExpressionContext(
      BinaryExpression node, DartType? contextType) {
    _contextTypes[node] = contextType;
  }

  @override
  void setCompoundAssignmentExpressionTypes(CompoundAssignmentExpression node) {
    assert(_assignmentLikeExpressionHandlers[node] == null);
    if (node is AssignmentExpression) {
      var handler = _AssignmentExpressionHandler(node);
      _assignmentLikeExpressionHandlers[node] = handler;
      handler.handleLValueType(this, node.readType, node.writeType!);
    } else if (node is PrefixExpression) {
      assert(_isIncrementOrDecrementOperator(node.operator.type));
      var handler = _PrefixExpressionHandler(node);
      _assignmentLikeExpressionHandlers[node] = handler;
      handler.handleLValueType(this, node.readType, node.writeType!);
      handler.handleAssignmentRhs(this, _fixBuilder.typeProvider.intType);
    } else if (node is PostfixExpression) {
      assert(_isIncrementOrDecrementOperator(node.operator.type));
      var handler = _PostfixExpressionHandler(node);
      _assignmentLikeExpressionHandlers[node] = handler;
      handler.handleLValueType(this, node.readType, node.writeType!);
      handler.handleAssignmentRhs(this, _fixBuilder.typeProvider.intType);
    } else {
      throw StateError('(${node.runtimeType}) $node');
    }
  }

  @override
  void setFlowAnalysis(
      FlowAnalysis<AstNode, Statement, Expression, PromotableElement, DartType>?
          flowAnalysis) {
    _flowAnalysis = flowAnalysis;
  }

  DartType _addCastOrNullCheck(
      Expression node, DartType expressionType, DartType contextType) {
    var expressionFutureTypeArgument = _getFutureTypeArgument(expressionType);
    var contextFutureOrTypeArgument = _getFutureOrTypeArgument(contextType);
    var parent = node.parent;
    if (parent is AwaitExpression &&
        expressionFutureTypeArgument != null &&
        contextFutureOrTypeArgument != null) {
      // `node` is an expression inside an await expression, and is a Future of
      // a nullable type. The context type is a FutureOr...
      var nonNullType = _fixBuilder._typeSystem
          .promoteToNonNull(expressionFutureTypeArgument);
      if (_fixBuilder._typeSystem.isSubtypeOf(nonNullType, contextType)) {
        // ... and a null-check will get us where we need to be; add a
        // null-check to the outer await, instead of adding a cast to FutureOr
        // inside the await.
        var change = _createExpressionChange(
            parent, expressionFutureTypeArgument, contextType);
        var checks = _fixBuilder._variables!
            .expressionChecks(_fixBuilder.source, parent);
        var info = AtomicEditInfo(change.description, checks?.edges ?? {});
        (_fixBuilder._getChange(parent) as NodeChangeForExpression)
            .addExpressionChange(change, info);
        _deferredExpressionProcessing[parent] = (_) => change.resultType;
        return expressionType;
      }
    }

    var checks =
        _fixBuilder._variables!.expressionChecks(_fixBuilder.source, node);
    var change = _createExpressionChange(node, expressionType, contextType);
    var info = AtomicEditInfo(change.description, checks?.edges ?? {});
    (_fixBuilder._getChange(node) as NodeChangeForExpression)
        .addExpressionChange(change, info);
    return change.resultType;
  }

  /// Ensures that the migrated file will contain an import of the extension
  /// called [extensionName] from `package:collection/collection.dart`, and that
  /// the pubspec will be appropriately updated (if necessary).
  void _addCollectionPackageExtension(String extensionName) {
    _fixBuilder.neededCollectionPackageExtensions.add(extensionName);
    _fixBuilder._neededPackages['collection'] =
        Version.parse('1.15.0-nullsafety.4');
  }

  DartType _addNullCheck(Expression node, DartType type,
      {AtomicEditInfo? info, HintComment? hint}) {
    var change = _createNullCheckChange(node, type, hint: hint);
    var checks =
        _fixBuilder._variables!.expressionChecks(_fixBuilder.source, node);
    info ??= AtomicEditInfo(change.description, checks?.edges ?? {});
    var nodeChangeForExpression =
        _fixBuilder._getChange(node) as NodeChangeForExpression;
    nodeChangeForExpression.addExpressionChange(change, info);
    return change.resultType;
  }

  bool _canBeInvokedOnNullable(Identifier identifier) =>
      isDeclaredOnObject(identifier.name) ||
      isNullableExtensionMember(identifier.staticElement);

  ExpressionChange _createExpressionChange(
      Expression node, DartType expressionType, DartType contextType) {
    var expressionFutureTypeArgument = _getFutureTypeArgument(expressionType);
    var contextFutureTypeArgument = _getFutureTypeArgument(contextType);
    if (expressionFutureTypeArgument != null &&
        contextFutureTypeArgument != null) {
      return IntroduceThenChange(
          contextType,
          _createExpressionChange(
              node, expressionFutureTypeArgument, contextFutureTypeArgument));
    }
    // Either a cast or a null check is needed.  We prefer to do a null
    // check if we can.
    var nonNullType = _fixBuilder._typeSystem.promoteToNonNull(expressionType);
    if (_fixBuilder._typeSystem.isSubtypeOf(nonNullType, contextType)) {
      return _createNullCheckChange(node, expressionType);
    } else {
      _flowAnalysis!.asExpression_end(node, contextType);
      var glb = _fixBuilder._typeSystem
          .greatestLowerBound(contextType, expressionType);

      if (glb != _fixBuilder._typeSystem.typeProvider.neverType &&
          !identical(glb, expressionType)) {
        return IntroduceAsChange(glb, isDowncast: true);
      }
      // there is no sense to do casts of unrelated types, let it fail at
      // compile time, so users see it earlier.
      return NoValidMigrationChange(contextType);
    }
  }

  ExpressionChange _createNullCheckChange(Expression node, DartType type,
      {HintComment? hint}) {
    var resultType = _fixBuilder._typeSystem.promoteToNonNull(type as TypeImpl);
    _flowAnalysis!.nonNullAssert_end(node);
    return type.isDartCoreNull && hint == null
        ? NoValidMigrationChange(resultType)
        : NullCheckChange(resultType, hint: hint);
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
      InterfaceElement class_, InterfaceElement superclass) {
    var decoratedSupertype = _fixBuilder._decoratedClassHierarchy!
        .getDecoratedSupertype(class_, superclass);
    var finalType = _fixBuilder._variables!.toFinalType(decoratedSupertype);
    return finalType as InterfaceType;
  }

  DartType? _getFutureOrTypeArgument(DartType type) {
    if (type is InterfaceType && type.isDartAsyncFutureOr) {
      var typeArguments = type.typeArguments;
      if (typeArguments.isNotEmpty) {
        return typeArguments.first;
      }
    }
    return null;
  }

  DartType? _getFutureTypeArgument(DartType type) {
    if (type is InterfaceType && type.isDartAsyncFuture) {
      var typeArguments = type.typeArguments;
      if (typeArguments.isNotEmpty) {
        return typeArguments.first;
      }
    }
    return null;
  }

  bool _isSubtypeOrCoercible(DartType type, DartType context) {
    var typeSystem = _fixBuilder._typeSystem;
    if (typeSystem.isSubtypeOf(type, context)) {
      return true;
    }
    if (context is FunctionType && type is InterfaceType) {
      var callMethod = type.lookUpMethod2(
          'call', _fixBuilder.unit!.declaredElement!.library);
      if (callMethod != null) {
        var variables = _fixBuilder._variables!;
        var callMethodType = variables.toFinalType(
            variables.decoratedElementType(callMethod.declaration));
        if (callMethod is MethodMember) {
          callMethodType =
              callMethod.substitution.substituteType(callMethodType);
        }
        if (typeSystem.isSubtypeOf(callMethodType, context)) {
          return true;
        }
      }
    }
    return false;
  }

  DartType _modifyRValueType(Expression node, DartType type,
      {DartType? context}) {
    var deferredProcessing = _deferredExpressionProcessing.remove(node);
    if (deferredProcessing != null) {
      type = deferredProcessing(type);
    }
    var hint =
        _fixBuilder._variables!.getNullCheckHint(_fixBuilder.source, node);
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
    if (type is DynamicType) return type;
    var ancestor = _findNullabilityContextAncestor(node);
    context ??= _contextTypes[ancestor] ?? DynamicTypeImpl.instance;
    if (!_isSubtypeOrCoercible(type, context)) {
      return _tryTransformOrElse(node, type) ??
          _tryTransformWhere(node, type) ??
          _addCastOrNullCheck(node, type, context);
    } else {
      // Even if the type is a subtype of its context, we still want to
      // transform `.where`.
      type = _tryTransformWhere(node, type) ?? type;
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
          return !isNullableExtensionMember(parent.staticElement);
        }
      }
    } else if (parent is PrefixedIdentifier) {
      if (_canBeInvokedOnNullable(parent.identifier)) {
        return false;
      }
      return identical(node, parent.prefix);
    } else if (parent is PropertyAccess) {
      if (_canBeInvokedOnNullable(parent.propertyName)) {
        return false;
      }
      return !parent.isNullAware && identical(node, parent.target);
    } else if (parent is MethodInvocation) {
      if (_canBeInvokedOnNullable(parent.methodName)) {
        return false;
      }
      return !parent.isNullAware && identical(node, parent.target);
    } else if (parent is CascadeExpression) {
      if (parent.cascadeSections.every((e) =>
          e is MethodInvocation && _canBeInvokedOnNullable(e.methodName) ||
          e is PropertyAccess && _canBeInvokedOnNullable(e.propertyName))) {
        return false;
      }
      return !parent.isNullAware && identical(node, parent.target);
    } else if (parent is IndexExpression) {
      if (identical(node, parent.target)) {
        return !isNullableExtensionMember(parent.staticElement);
      } else {
        return false;
      }
    } else if (parent is ConditionalExpression) {
      return identical(node, parent.condition);
    } else if (parent is FunctionExpressionInvocation) {
      if (identical(node, parent.function)) {
        return !isNullableExtensionMember(parent.staticElement);
      } else {
        return false;
      }
    } else if (parent is PrefixExpression) {
      // TODO(paulberry): for prefix increment/decrement, inserting a null check
      // isn't sufficient.
      return !isNullableExtensionMember(parent.staticElement);
    } else if (parent is ThrowExpression) {
      return true;
    }
    return false;
  }

  CollectionElement? _transformCollectionElement(CollectionElement? node) {
    while (node is IfElement) {
      var conditionalDiscard = _fixBuilder._variables!
          .getConditionalDiscard(_fixBuilder.source, node);
      if (conditionalDiscard == null ||
          conditionalDiscard.keepTrue && conditionalDiscard.keepFalse) {
        return node;
      }
      var conditionValue = conditionalDiscard.keepTrue;
      var ifElement = node;
      node = conditionValue ? ifElement.thenElement : ifElement.elseElement;
    }
    return node;
  }

  List<CollectionElement> _transformCollectionElements(
      NodeList<CollectionElement> elements) {
    return elements
        .map(_transformCollectionElement)
        .whereType<CollectionElement>()
        .toList();
  }

  /// If [node] is an `orElse` argument to an iterable method that should be
  /// transformed, transforms it and returns [type] (this indicates to the
  /// caller that no further transformations to this expression need to be
  /// considered); otherwise returns `null`.
  DartType? _tryTransformOrElse(Expression node, DartType type) {
    var transformationInfo =
        _fixBuilder._whereOrNullTransformer.tryTransformOrElseArgument(node);
    if (transformationInfo != null) {
      // We can fix this by dropping the node and changing the method call.
      _addCollectionPackageExtension('IterableExtension');
      var info = AtomicEditInfo(
          NullabilityFixDescription.changeMethodName(
              transformationInfo.originalName,
              transformationInfo.replacementName),
          {});
      (_fixBuilder._getChange(transformationInfo.methodInvocation.methodName)
              as NodeChangeForMethodName)
          .replaceWith(transformationInfo.replacementName, info);
      (_fixBuilder._getChange(transformationInfo.methodInvocation.argumentList)
              as NodeChangeForArgumentList)
          .dropArgument(transformationInfo.orElseArgument, info);
      _deferredExpressionProcessing[transformationInfo.methodInvocation] =
          (methodInvocationType) => _fixBuilder._typeSystem
              .makeNullable(methodInvocationType as TypeImpl);
      return type;
    }
    return null;
  }

  /// If [node] is a call to `Iterable.where` that should be transformed,
  /// transforms it and returns the type of the transformed method call (this
  /// indicates to the caller that no further transformations to this expression
  /// need to be considered); otherwise returns `null`.
  DartType? _tryTransformWhere(Expression node, DartType type) {
    var transformationInfo =
        _fixBuilder._whereNotNullTransformer.tryTransformMethodInvocation(node);
    if (transformationInfo != null) {
      // We can fix this by dropping the method call's argument and changing the
      // call.
      _addCollectionPackageExtension('IterableNullableExtension');
      var info = AtomicEditInfo(
          NullabilityFixDescription.changeMethodName(
              transformationInfo.originalName,
              transformationInfo.replacementName),
          {});
      (_fixBuilder._getChange(transformationInfo.methodInvocation.methodName)
              as NodeChangeForMethodName)
          .replaceWith(transformationInfo.replacementName, info);
      (_fixBuilder._getChange(transformationInfo.methodInvocation.argumentList)
              as NodeChangeForArgumentList)
          .dropArgument(transformationInfo.argument, info);
      return _fixBuilder._whereNotNullTransformer
          .transformPostMigrationInvocationType(type);
    }
    return null;
  }

  /// Runs the computation in [compute].  If an exception occurs and
  /// [_fixBuilder.listener] is non-null, the exception is reported to the
  /// listener and [fallback] is called to produce a result.  Otherwise the
  /// exception is propagated normally.
  T _wrapExceptions<T>(
      AstNode? node, T Function() fallback, T Function() compute) {
    if (_fixBuilder.listener == null) return compute();
    try {
      return compute();
    } catch (exception, stackTrace) {
      _fixBuilder.listener!
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
  MethodElement? get combiner => node.staticElement;

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
  late final DartType? readType;

  /// The type that may be written to the LHS.
  late final DartType writeType;

  /// The type that should be used as a context type when inferring the RHS.
  DartType? rhsContextType;

  /// Gets the static element representing the combiner.
  MethodElement? get combiner;

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
    MethodElement? combiner = this.combiner;
    if (combiner != null) {
      var fixBuilder = hooks._fixBuilder;
      var combinerReturnType =
          fixBuilder._typeSystem.refineBinaryExpressionType(
        readType!,
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
      DartType? readTypeToSet, DartType writeTypeToSet) {
    assert(writeTypeToSet.nullabilitySuffix != NullabilitySuffix.star);
    writeType = writeTypeToSet;
    // TODO(scheglov) Remove this after the analyzer breaking change that
    // will top setting types for LHS.
    (target as ExpressionImpl).staticType = writeTypeToSet;
    var fixBuilder = hooks._fixBuilder;
    if (combinerType == TokenType.EQ) {
      rhsContextType = writeTypeToSet;
    } else {
      readType = readTypeToSet;
      assert(readType!.nullabilitySuffix != NullabilitySuffix.star);
      if (combinerType == TokenType.QUESTION_QUESTION_EQ) {
        rhsContextType = writeTypeToSet;
        if (fixBuilder._typeSystem.isNonNullable(readType!)) {
          (fixBuilder._getChange(node) as NodeChangeForAssignment)
              .isWeakNullAware = true;
        }
      } else {
        if (readType is! DynamicType &&
            fixBuilder._typeSystem.isPotentiallyNullable(readType!)) {
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
  NullabilityMigrationListener? get listener => _fixBuilder.listener;

  @override
  Source? get source => _fixBuilder.source;

  @override
  void visitAsExpression(AsExpression node) {
    if (!_fixBuilder._variables!.wasUnnecessaryCast(_fixBuilder.source, node) &&
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
    if (_fixBuilder.neededCollectionPackageExtensions.isNotEmpty) {
      var packageCollectionImport =
          _findImportDirective(node, 'package:collection/collection.dart');
      if (packageCollectionImport != null) {
        for (var combinator in packageCollectionImport.combinators) {
          if (combinator is ShowCombinator) {
            for (var extensionName
                in _fixBuilder.neededCollectionPackageExtensions) {
              _ensureShows(combinator, extensionName);
            }
          }
        }
      } else {
        var change =
            _fixBuilder._getChange(node) as NodeChangeForCompilationUnit;
        for (var extensionName
            in _fixBuilder.neededCollectionPackageExtensions) {
          change.addImport('package:collection/collection.dart', extensionName);
        }
      }
    }
    super.visitCompilationUnit(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.type == null) {
      var typeToAdd = _fixBuilder._addedParameterTypes[node.declaredElement!];
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
            ._computeMigratedType(variableDeclaration.declaredElement!);
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
          // Different variables need different types.  We handle this by
          // introducing casts, which is not great but gets the job done.
          for (int i = 0; i < node.variables.length; i++) {
            if (neededTypes[i] != inferredTypes[i]) {
              // We only have to worry about variables with initializers because
              // variables without initializers will get the type `dynamic`.
              var initializer = node.variables[i].initializer;
              if (initializer != null) {
                (_fixBuilder._getChange(initializer) as NodeChangeForExpression)
                    .addExpressionChange(
                        IntroduceAsChange(neededTypes[i], isDowncast: false),
                        AtomicEditInfo(
                            NullabilityFixDescription.otherCastExpression, {}));
              }
            }
          }
        } else {
          (_fixBuilder._getChange(node) as NodeChangeForVariableDeclarationList)
              .addExplicitType = firstNeededType;
        }
      }
    }

    // Check if the nullability node for a single variable declaration has been
    // declared to be late.
    if (node.variables.length == 1) {
      var variableElement = node.variables.single.declaredElement!;
      var lateCondition = _fixBuilder._variables!
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

    var lateHint = _fixBuilder._variables!.getLateHint(source, node);
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
  ImportDirective? _findImportDirective(CompilationUnit unit, String uri) {
    for (var directive in unit.directives) {
      if (directive is ImportDirective &&
          directive.prefix == null &&
          directive.uri.stringValue == uri) {
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
  NullabilityMigrationListener? get listener => _fixBuilder.listener;

  @override
  Source? get source => _fixBuilder.source;

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    var element = node.declaredElement;
    if (node.defaultValue == null) {
      var requiredHint =
          _fixBuilder._variables!.getRequiredHint(_fixBuilder.source, node);
      var nullabilityNode =
          _fixBuilder._variables!.decoratedElementType(element!).node;
      if (!nullabilityNode.isNullable) {
        var enclosingElement = element.enclosingElement;
        if (enclosingElement is ConstructorElement &&
            enclosingElement.isFactory &&
            enclosingElement.redirectedConstructor != null &&
            !node.declaredElement!.hasRequired) {
          // Redirecting factory constructors inherit their parameters' default
          // values from the constructors they redirect to, so the lack of a
          // default value doesn't mean the parameter has to be nullable.
        } else if (element.isNamed) {
          _addRequiredKeyword(node, nullabilityNode, requiredHint);
        } else {
          _fixBuilder._addProblem(
              node, const NonNullableUnnamedOptionalParameter());
        }
      } else if (requiredHint != null ||
          element.metadata.any((m) => m.isRequired)) {
        _addRequiredKeyword(node, nullabilityNode, requiredHint);
      }
    }
    super.visitDefaultFormalParameter(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.type == null) {
      // Potentially add an explicit type to a field formal parameter.
      var decl = node.declaredElement as FieldFormalParameterElement;
      var decoratedType = _fixBuilder._variables!.decoratedElementType(decl);
      var field = decl.field;
      if (field != null) {
        var decoratedFieldType =
            _fixBuilder._variables!.decoratedElementType(field);
        var typeToAdd = _fixBuilder._variables!.toFinalType(decoratedType);
        var fieldFinalType =
            _fixBuilder._variables!.toFinalType(decoratedFieldType);
        if (typeToAdd is InterfaceType &&
            !_fixBuilder._typeSystem.isSubtypeOf(fieldFinalType, typeToAdd)) {
          (_fixBuilder._getChange(node) as NodeChangeForFieldFormalParameter)
              .addExplicitType = typeToAdd;
        }
      }
    } else if (node.parameters != null) {
      // Handle function-typed field formal parameters.
      var decoratedType =
          _fixBuilder._variables!.decoratedElementType(node.declaredElement!);
      if (decoratedType.node.isNullable) {
        (_fixBuilder._getChange(node) as NodeChangeForFieldFormalParameter)
            .recordNullability(decoratedType, decoratedType.node.isNullable,
                nullabilityHint:
                    _fixBuilder._variables!.getNullabilityHint(source, node));
      }
    }
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var decoratedType =
        _fixBuilder._variables!.decoratedElementType(node.declaredElement!);
    if (decoratedType.node.isNullable) {
      (_fixBuilder._getChange(node)
              as NodeChangeForFunctionTypedFormalParameter)
          .recordNullability(decoratedType, decoratedType.node.isNullable,
              nullabilityHint:
                  _fixBuilder._variables!.getNullabilityHint(source, node));
    }
    super.visitFunctionTypedFormalParameter(node);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    var decoratedType = _fixBuilder._variables!
        .decoratedTypeAnnotation(_fixBuilder.source, node);
    if (!typeIsNonNullableByContext(node)) {
      _makeTypeNameNullable(node, decoratedType);
    }
    (node as GenericFunctionTypeImpl).type =
        _fixBuilder._variables!.toFinalType(decoratedType);
    super.visitGenericFunctionType(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var nullableAnnotation = BuiltValueTransformer.findNullableAnnotation(node);
    if (nullableAnnotation != null) {
      var info = AtomicEditInfo(
          NullabilityFixDescription.removeNullableAnnotation, {});
      (_fixBuilder._getChange(node) as NodeChangeForMethodDeclaration)
        ..annotationToRemove = nullableAnnotation
        ..removeAnnotationInfo = info;
    }
    super.visitMethodDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    var decoratedType = _fixBuilder._variables!
        .decoratedTypeAnnotation(_fixBuilder.source, node);
    if (!typeIsNonNullableByContext(node)) {
      if (!_typeIsNaturallyNullable(decoratedType.type!)) {
        _makeTypeNameNullable(node, decoratedType);
      }
    }
    (node as NamedTypeImpl).type =
        _fixBuilder._variables!.toFinalType(decoratedType);
    super.visitNamedType(node);
  }

  void _addRequiredKeyword(DefaultFormalParameter parameter,
      NullabilityNode node, HintComment? requiredHint) {
    // Change an existing `@required` annotation into a `required` keyword if
    // possible.
    final element = parameter.declaredElement!;
    final method = element.enclosingElement!;
    final cls = method.enclosingElement!;
    var info = AtomicEditInfo(
        NullabilityFixDescription.addRequired(
            cls.name, method.name, element.name),
        {FixReasonTarget.root: node});
    var metadata = parameter.metadata;
    if (metadata.isNotEmpty) {
      // Only the last annotation can be changed into a `required` keyword;
      // changing an earlier annotation into a keyword would be illegal.
      var lastAnnotation = metadata.last;
      if (lastAnnotation.elementAnnotation!.isRequired) {
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
      ..addRequiredKeywordInfo = info
      ..requiredHint = requiredHint;
    var requiredAnnotation = metadata.firstWhereOrNull(
        (annotation) => annotation.elementAnnotation!.isRequired);
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
    if (decoratedType.type!.isDartAsyncFutureOr) {
      var typeArguments = decoratedType.typeArguments;
      if (typeArguments.length == 1) {
        var typeArgument = typeArguments[0]!;
        if (_typeIsNaturallyNullable(typeArgument.type!) ||
            typeArgument.node.isNullable) {
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
                _fixBuilder._variables!.getNullabilityHint(source, node));
  }

  bool _typeIsNaturallyNullable(DartType type) =>
      type is DynamicType || type is VoidType || type.isDartCoreNull;
}

/// Specialization of [_AssignmentLikeExpressionHandler] for
/// [PostfixExpression].
class _PostfixExpressionHandler extends _AssignmentLikeExpressionHandler {
  @override
  final PostfixExpression node;

  _PostfixExpressionHandler(this.node)
      : assert(_isIncrementOrDecrementOperator(node.operator.type));

  @override
  MethodElement? get combiner => node.staticElement;

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
  MethodElement? get combiner => node.staticElement;

  @override
  TokenType get combinerType => node.operator.type;

  @override
  Expression get target => node.operand;
}
